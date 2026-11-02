use crate::{
    AppState,
    pages::{page, sep},
};
use async_zip::{Compression, ZipEntryBuilder, base::write::ZipFileWriter};
use axum::{
    body::Body,
    extract::{Path, State},
    http::{StatusCode, header::CONTENT_LENGTH},
    response::IntoResponse,
};
use axum_extra::response::Attachment;
use maud::{Markup, html};
use std::{fs, io, path::Path as FsPath};
use tokio_util::io::{InspectWriter, ReaderStream};

// sorted names of subdirectories (or files) of dir
fn ls(dir: &FsPath, dirs: bool) -> Vec<String> {
    let mut names: Vec<_> = fs::read_dir(dir)
        .into_iter()
        .flatten()
        .flatten()
        .filter(|e| e.file_type().is_ok_and(|t| t.is_dir() == dirs))
        .filter_map(|e| e.file_name().into_string().ok())
        .collect();
    names.sort();
    names
}

// files of the album, if it exists; also validates the name
fn album_files(s: &AppState, album: &str) -> Result<Vec<String>, StatusCode> {
    let fullsize = s.photos.join("fullsize");
    if !ls(&fullsize, true).iter().any(|a| a == album) {
        return Err(StatusCode::NOT_FOUND);
    }
    Ok(ls(&fullsize.join(album), false))
}

pub async fn albums(State(s): State<AppState>) -> Markup {
    let mut names = ls(&s.photos.join("fullsize"), true);
    // newest first: names start with YYYY-MM-DD_
    names.reverse();
    page(
        &["photo"],
        &html! {
            (sep())
            form .inline method="post" action="/logout" { button .link { "logout" } }
            ul {
                @for a in &names { li { a href={ "/photo/" (a) } { (a) } } }
            }
        },
    )
}

pub async fn album(
    State(s): State<AppState>,
    Path(album): Path<String>,
) -> Result<Markup, StatusCode> {
    let photos = album_files(&s, &album)?;
    Ok(page(
        &["photo", &album],
        &html! {
            (sep())
            a href={ "/photo/" (album) "/zip" } { "zip" }
            #album {
                @for p in &photos {
                    a href={ "/photo/fullsize/" (album) "/" (p) } data-fslightbox="gallery" {
                        img src={ "/photo/preview/" (album) "/" (p) } loading="lazy"
                            onerror="this.onerror=null; this.src='/static/assets/pfp.gif';";
                    }
                }
            }
            script src="/static/js/fslightbox.js" {}
        },
    ))
}

// exact size of the archive of files (name, size): the same zip written to a
// counter, with placeholder data that is never read
pub async fn zip_len(files: &[(String, u64)]) -> u64 {
    let mut len = 0;
    let counter = InspectWriter::new(tokio::io::sink(), |b: &[u8]| len += b.len() as u64);
    let mut zip = ZipFileWriter::with_tokio(counter);
    let zeros = vec![0; usize::try_from(files.iter().map(|f| f.1).max().unwrap_or(0)).unwrap()];
    for (name, size) in files {
        let entry = ZipEntryBuilder::new(name.clone().into(), Compression::Stored)
            .uncompressed_size(*size)
            .crc32(0u32);
        zip.write_entry_whole_precompressed(entry, &zeros[..usize::try_from(*size).unwrap()])
            .await
            .unwrap();
    }
    zip.close().await.unwrap();
    len
}

pub async fn zip(
    State(s): State<AppState>,
    Path(album): Path<String>,
) -> Result<impl IntoResponse, StatusCode> {
    let dir = s.photos.join("fullsize").join(&album);
    let files = album_files(&s, &album)?
        .into_iter()
        .map(|p| fs::metadata(dir.join(&p)).map(|m| (p, m.len())))
        .collect::<io::Result<Vec<_>>>()
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let len = zip_len(&files).await;
    let (w, r) = tokio::io::duplex(1 << 16);
    // photos are already compressed; on error the body ends short of
    // Content-Length, and the download fails
    tokio::spawn(async move {
        let mut zip = ZipFileWriter::with_tokio(w);
        for (p, _) in files {
            let data = tokio::fs::read(dir.join(&p)).await?;
            zip.write_entry_whole(ZipEntryBuilder::new(p.into(), Compression::Stored), &data)
                .await?;
        }
        zip.close().await
    });
    Ok((
        [(CONTENT_LENGTH, len)],
        Attachment::new(Body::from_stream(ReaderStream::new(r)))
            .filename(format!("{album}.zip"))
            .content_type("application/zip"),
    ))
}
