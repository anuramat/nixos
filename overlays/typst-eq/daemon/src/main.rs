//! Renders the equations of a typst document exactly as the document lays them out: the whole
//! document is compiled, and every equation's frame items are cut out of its page.
//!
//! Serves requests from stdin, one JSON object per line, each answered by one line on stdout.

use std::collections::HashSet;
use std::io::BufRead;
use std::path::PathBuf;
use std::str::FromStr;

use anyhow::{Context, Result, anyhow};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tiny_skia::{IntRect, Pixmap};
use typst::diag::FileResult;
use typst::foundations::{Bytes, Datetime, Duration, Smart};
use typst::introspection::{Location, Tag};
use typst::layout::{Abs, Frame, FrameItem, Point, Ratio, Size, Transform};
use typst::math::EquationElem;
use typst::syntax::{FileId, RootedPath, Source, Span, VirtualPath, VirtualRoot};
use typst::text::{Font, FontBook, Glyph};
use typst::utils::{LazyHash, Scalar, hash128};
use typst::visualize::{Color, Paint};
use typst::{Library, LibraryExt, World, WorldExt};
use typst_kit::datetime::Time;
use typst_kit::downloader::SystemDownloader;
use typst_kit::files::{FileLoader, FileStore, FsRoot};
use typst_kit::fonts::{self, FontStore};
use typst_kit::packages::SystemPackages;
use typst_layout::{Page, PagedDocument};
use typst_render::RenderOptions;

/// Pixels per pt of the pass that finds the ink.
const PROBE_SCALE: f64 = 0.5;
/// What the coarse pass might miss around the ink, in pt.
const PROBE_MARGIN: f64 = 4.0;

#[derive(Deserialize)]
struct Request {
    /// Where the document is; its content is `text`, whatever the file has.
    path: PathBuf,
    text: String,
    /// Replaces the default black.
    fg: Option<String>,
    /// Pixels per pt of the images.
    scale: f64,
}

#[derive(Serialize)]
struct Equation {
    /// Zero-based (line, byte column) of the start and of the end in `text`.
    range: [usize; 4],
    png: PathBuf,
}

/// What outlives a request.
struct Env {
    library: LazyHash<Library>,
    fonts: FontStore,
    packages: SystemPackages,
    time: Time,
    out: PathBuf,
}

struct Loader<'a> {
    root: FsRoot,
    packages: &'a SystemPackages,
    main: FileId,
    text: &'a str,
}

impl FileLoader for Loader<'_> {
    fn load(&self, id: FileId) -> FileResult<Bytes> {
        if id == self.main {
            return Ok(Bytes::from_string(self.text.to_owned()));
        }
        match id.root() {
            VirtualRoot::Project => self.root.load(id.vpath()),
            VirtualRoot::Package(spec) => self.packages.obtain(spec)?.load(id.vpath()),
        }
    }
}

struct Doc<'a> {
    env: &'a Env,
    files: FileStore<Loader<'a>>,
}

impl World for Doc<'_> {
    fn library(&self) -> &LazyHash<Library> {
        &self.env.library
    }

    fn book(&self) -> &LazyHash<FontBook> {
        self.env.fonts.book()
    }

    fn main(&self) -> FileId {
        self.files.loader().main
    }

    fn source(&self, id: FileId) -> FileResult<Source> {
        self.files.source(id)
    }

    fn file(&self, id: FileId) -> FileResult<Bytes> {
        self.files.file(id)
    }

    fn font(&self, index: usize) -> Option<Font> {
        self.env.fonts.font(index)
    }

    fn today(&self, offset: Option<Duration>) -> Option<Datetime> {
        self.env.time.today(offset)
    }
}

impl Env {
    fn new(out: PathBuf) -> Self {
        let mut fonts = FontStore::new();
        fonts.extend(fonts::system());
        fonts.extend(fonts::embedded());
        Self {
            library: LazyHash::new(Library::default()),
            fonts,
            packages: SystemPackages::new(SystemDownloader::new("typst-eq")),
            time: Time::system(),
            out,
        }
    }

    /// The equations written in `request.text` itself that the document lays out, in the order
    /// of the layout; one that is laid out several times is rendered as its first occurrence.
    fn equations(&self, request: &Request) -> Result<Vec<Equation>> {
        let name = request.path.file_name().and_then(|name| name.to_str());
        let main = RootedPath::new(
            VirtualRoot::Project,
            VirtualPath::new(name.context("no file name")?)?,
        )
        .intern();
        let root = FsRoot::new(request.path.parent().context("no directory")?.into());
        let loader = Loader {
            root,
            packages: &self.packages,
            main,
            text: &request.text,
        };
        let doc = Doc {
            env: self,
            files: FileStore::new(loader),
        };

        let compiled = typst::compile::<PagedDocument>(&doc).output;
        comemo::evict(10);
        let compiled = compiled.map_err(|errors| anyhow!("{}", errors[0].message))?;
        let fg = request
            .fg
            .as_deref()
            .map(Color::from_str)
            .transpose()
            .map_err(|e| anyhow!(e))?;
        let source = doc.source(main)?;
        let position = |byte| {
            let line = source.lines().byte_to_line(byte)?;
            Some((line, byte - source.lines().line_to_byte(line)?))
        };

        let mut seen = HashSet::new();
        let mut equations = Vec::new();
        for page in compiled.pages() {
            let mut starts = Vec::new();
            find_starts(&page.frame, &mut starts);
            for (location, span) in starts {
                let Some(range) = doc.range(span).filter(|_| span.id() == Some(main)) else {
                    continue;
                };
                if !seen.insert(range.start) {
                    continue;
                }
                let mut cut = Cut {
                    target: location,
                    fg: fg.as_ref(),
                    open: false,
                    looks: Vec::new(),
                };
                let frame = cut.frame(&page.frame, Transform::identity());
                let (Some(start), Some(end), Some(key)) = (
                    position(range.start),
                    position(range.end),
                    cut.key(request.scale),
                ) else {
                    continue;
                };
                let png = self.out.join(format!("{key:032x}.png"));
                if !png.exists() {
                    let Some(image) = render(page, frame, cut.looks[0].0, request.scale) else {
                        continue;
                    };
                    image.save_png(&png)?;
                }
                equations.push(Equation {
                    range: [start.0, start.1, end.0, end.1],
                    png,
                });
            }
        }
        Ok(equations)
    }
}

/// The start tags of the equations in `frame`.
fn find_starts(frame: &Frame, starts: &mut Vec<(Location, Span)>) {
    for (_, item) in frame.items() {
        match item {
            FrameItem::Group(group) => find_starts(&group.frame, starts),
            FrameItem::Tag(tag @ Tag::Start(elem, _)) if elem.is::<EquationElem>() => {
                starts.push((tag.location(), elem.span()));
            }
            _ => {}
        }
    }
}

/// Cuts the items between the start and the end tag of an element out of a frame.
struct Cut<'a> {
    target: Location,
    fg: Option<&'a Color>,
    open: bool,
    /// Where on the page each of the items is, and what it looks like; the same for the
    /// groups that clip them.
    looks: Vec<(Transform, u128)>,
}

impl Cut<'_> {
    /// A copy of `frame` with its groups, and so its transforms and clips, but only the
    /// target's items in them.
    fn frame(&mut self, frame: &Frame, ts: Transform) -> Frame {
        let mut out = Frame::new(frame.size(), frame.kind());
        for (pos, item) in frame.items() {
            match item {
                FrameItem::Tag(tag) if tag.location() == self.target => {
                    self.open = matches!(tag, Tag::Start(..));
                }
                FrameItem::Tag(_) | FrameItem::Link(..) => {}
                FrameItem::Group(group) => {
                    let ts = ts
                        .pre_concat(Transform::translate(pos.x, pos.y))
                        .pre_concat(group.transform);
                    let inner = self.frame(&group.frame, ts);
                    if !inner.is_empty() {
                        self.looks
                            .extend(group.clip.iter().map(|clip| (ts, hash128(clip))));
                        let mut group = group.clone();
                        group.frame = inner;
                        out.push(*pos, FrameItem::Group(group));
                    }
                }
                item if self.open => {
                    let item = self.recolor(item.clone());
                    self.looks.push((
                        ts.pre_concat(Transform::translate(pos.x, pos.y)),
                        look(&item),
                    ));
                    out.push(*pos, item);
                }
                _ => {}
            }
        }
        out
    }

    fn recolor(&self, mut item: FrameItem) -> FrameItem {
        let Some(fg) = self.fg else { return item };
        let swap = |paint: &mut Paint| {
            if matches!(paint, Paint::Solid(color) if color.to_rgb() == Color::BLACK.to_rgb()) {
                *paint = fg.clone().into();
            }
        };
        match &mut item {
            FrameItem::Text(text) => {
                swap(&mut text.fill);
                text.stroke
                    .iter_mut()
                    .for_each(|stroke| swap(&mut stroke.paint));
            }
            FrameItem::Shape(shape, _) => {
                shape.fill.iter_mut().for_each(swap);
                shape
                    .stroke
                    .iter_mut()
                    .for_each(|stroke| swap(&mut stroke.paint));
            }
            _ => {}
        }
        item
    }

    /// Identifies the image of what was cut out: the looks, relative to the first one, so that
    /// an element keeps its key when it moves, or when the source changes elsewhere.
    fn key(&self, scale: f64) -> Option<u128> {
        let (anchor, _) = self.looks.first()?;
        let relative = |(ts, look): &(Transform, u128)| {
            let offset = [ts.tx - anchor.tx, ts.ty - anchor.ty].map(Abs::to_pt);
            let matrix = [ts.sx, ts.ky, ts.kx, ts.sy].map(Ratio::get);
            (
                offset.map(|v| (v * 1e4).round().to_bits()),
                matrix.map(f64::to_bits),
                *look,
            )
        };
        Some(hash128(&(
            self.looks.iter().map(relative).collect::<Vec<_>>(),
            scale.to_bits(),
        )))
    }
}

/// What an item looks like, whichever source it comes from.
fn look(item: &FrameItem) -> u128 {
    match item {
        FrameItem::Text(text) => {
            let glyph = |g: &Glyph| (g.id, g.x_advance, g.x_offset, g.y_advance, g.y_offset);
            let glyphs: Vec<_> = text.glyphs.iter().map(glyph).collect();
            hash128(&(&text.font, text.size, &text.fill, &text.stroke, glyphs))
        }
        FrameItem::Shape(shape, _) => hash128(shape),
        FrameItem::Image(image, size, _) => hash128(&(image, size)),
        FrameItem::Group(_) | FrameItem::Link(..) | FrameItem::Tag(_) => 0,
    }
}

/// What `frame`, a cut of the frame of `page`, shows, on a transparent background, trimmed to
/// the ink; `None` if there is none.
fn render(page: &Page, frame: Frame, anchor: Transform, scale: f64) -> Option<Pixmap> {
    // a coarse pass over the page finds the ink, a fine one renders its surroundings; these
    // start a whole number of pixels away from the anchor, so that the image doesn't depend on
    // where on the page the ink is
    let probe = ink(&rasterize(page, frame.clone(), PROBE_SCALE))?;
    let edge = |px: i32, anchor: Abs, margin: f64| {
        let offset = f64::from(px) / PROBE_SCALE + margin - anchor.to_pt();
        anchor + Abs::pt((offset * scale).round() / scale)
    };
    let min = Point::new(
        edge(probe.x(), anchor.tx, -PROBE_MARGIN),
        edge(probe.y(), anchor.ty, -PROBE_MARGIN),
    );
    let max = Point::new(
        edge(probe.right(), anchor.tx, PROBE_MARGIN),
        edge(probe.bottom(), anchor.ty, PROBE_MARGIN),
    );
    let mut surroundings = Frame::hard(Size::new(max.x - min.x, max.y - min.y));
    surroundings.push_frame(-min, frame);
    let fine = rasterize(page, surroundings, scale);
    fine.clone_rect(ink(&fine)?)
}

/// `frame` in place of the content of `page`, without the page's background.
fn rasterize(page: &Page, frame: Frame, scale: f64) -> Pixmap {
    let page = Page {
        frame,
        fill: Smart::Custom(None),
        ..page.clone()
    };
    let options = RenderOptions {
        pixel_per_pt: Scalar::new(scale),
        render_bleed: false,
    };
    typst_render::render(&page, &options)
}

/// The bounding box of the pixels that aren't transparent.
fn ink(pixmap: &Pixmap) -> Option<IntRect> {
    let width = pixmap.width() as usize;
    let inked = pixmap
        .pixels()
        .iter()
        .enumerate()
        .filter(|(_, pixel)| pixel.alpha() > 0);
    let (mut x0, mut y0, mut x1, mut y1) = (usize::MAX, usize::MAX, 0, 0);
    for (i, _) in inked {
        x0 = x0.min(i % width);
        y0 = y0.min(i / width);
        x1 = x1.max(i % width);
        y1 = y1.max(i / width);
    }
    let [x, y, w, h] = [x0, y0, x1.checked_sub(x0)? + 1, y1 - y0 + 1].map(u32::try_from);
    IntRect::from_xywh(
        x.ok()?.try_into().ok()?,
        y.ok()?.try_into().ok()?,
        w.ok()?,
        h.ok()?,
    )
}

fn main() -> Result<()> {
    let out = std::env::args().nth(1).context("usage: typst-eq OUT_DIR")?;
    std::fs::create_dir_all(&out)?;
    let env = Env::new(out.into());
    for line in std::io::stdin().lock().lines() {
        let equations = serde_json::from_str(&line?)
            .map_err(Into::into)
            .and_then(|request| env.equations(&request));
        match equations {
            Ok(equations) => println!("{}", json!({ "equations": equations })),
            Err(error) => println!("{}", json!({ "error": format!("{error:#}") })),
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use super::*;

    /// The equations of `text`, taken to be `tests/main.typ`, which doesn't exist.
    fn equations(text: &str, fg: Option<&str>) -> Vec<Equation> {
        let out = std::env::temp_dir().join("typst-eq-tests");
        std::fs::create_dir_all(&out).unwrap();
        let request = Request {
            path: Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/main.typ"),
            text: text.into(),
            fg: fg.map(Into::into),
            scale: 4.0,
        };
        Env::new(out).equations(&request).unwrap()
    }

    /// The text that the ranges cover, and the sizes in pixels.
    fn summary(text: &str, equations: &[Equation]) -> Vec<String> {
        let lines: Vec<_> = text.split('\n').collect();
        equations
            .iter()
            .map(|equation| {
                let [r0, c0, r1, c1] = equation.range;
                let covered = if r0 == r1 {
                    lines[r0][c0..c1].to_owned()
                } else {
                    format!("{} ... {}", &lines[r0][c0..], &lines[r1][..c1])
                };
                let image = Pixmap::load_png(&equation.png).unwrap();
                format!("{covered} | {}x{}", image.width(), image.height())
            })
            .collect()
    }

    /// The colors of the opaque pixels.
    fn colors(equation: &Equation) -> HashSet<[u8; 3]> {
        let image = Pixmap::load_png(&equation.png).unwrap();
        let opaque = image.pixels().iter().filter(|pixel| pixel.alpha() == 255);
        opaque
            .map(|pixel| [pixel.red(), pixel.green(), pixel.blue()])
            .collect()
    }

    #[test]
    fn finds_equations_in_context() {
        let text = include_str!("../tests/context.typ");
        insta::assert_yaml_snapshot!(summary(text, &equations(text, None)), @r#"
        - $integral_0^1 f(x) dif x$ | 273x96
        - "$f: Reals -> Reals$ | 192x40"
        - $norm(x) <= 1$ | 134x44
        - "$#x^2$ | 37x38"
        - $ e^(i pi) + 1 = 0 $ | 758x48
        - $a_1 + a_2 + a_3 + a_4 + a_5 + a_6 + a_7 + a_8 + a_9 + a_10 + a_11 + a_12 + a_13 + a_14 + a_15 + a_16 = S$ | 1205x97
        - "$ x &= (-b plus.minus sqrt(b^2 - 4 a c)) / (2a) \\ ...     &= y + z $ | 850x165"
        - $ nabla times bold(E) = - (partial bold(B)) / (partial t) $ | 783x94
        - $alpha + beta$ | 107x41
        - $Sigma_i x_i$ | 147x76
        - $a/b$ | 26x44
        - $x in Reals$ | 109x33
        - $gamma^2$ | 35x39
        - "$ mat(1, 2; 3, 4) $ | 639x106"
        - $sum_(i=1)^n i$ | 122x57
        "#);
    }

    #[test]
    fn reads_the_text_not_the_file() {
        // `tests/main.typ` doesn't exist, and the import is relative to it
        let text = "#import \"defs.typ\": norm\n$norm(x)$";
        insta::assert_yaml_snapshot!(summary(text, &equations(text, None)), @"- $norm(x)$ | 52x44");
    }

    #[test]
    fn image_is_independent_of_position() {
        let pngs = |text| {
            equations(text, None)
                .into_iter()
                .map(|e| e.png)
                .collect::<Vec<_>>()
        };
        similar_asserts::assert_eq!(
            pngs("$a^2 + b^2$"),
            pngs("Some text first.\n\n- and a list, with $a^2 + b^2$"),
        );
    }

    #[test]
    fn fg_replaces_only_the_default_black() {
        let text = "$a/b$ #text(fill: rgb(\"#0000ff\"))[$a/b$]";
        let [default, blue] = &equations(text, Some("#ff0000"))[..] else {
            panic!()
        };
        similar_asserts::assert_eq!(colors(default), HashSet::from([[255, 0, 0]]));
        similar_asserts::assert_eq!(colors(blue), HashSet::from([[0, 0, 255]]));
        let [default, _] = &equations(text, None)[..] else {
            panic!()
        };
        similar_asserts::assert_eq!(colors(default), HashSet::from([[0, 0, 0]]));
    }

    #[test]
    fn reports_compile_errors() {
        let request = Request {
            path: "/tmp/main.typ".into(),
            text: "#unknown".into(),
            fg: None,
            scale: 4.0,
        };
        let error = Env::new(std::env::temp_dir())
            .equations(&request)
            .err()
            .unwrap();
        insta::assert_snapshot!(error, @"unknown variable: unknown");
    }
}
