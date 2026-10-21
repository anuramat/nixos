// battery charge over time with uPlot, from `rows` of [unix time, percent, state];
// touchpad and touchscreen pan/zoom follow the fingers, like scrolling a page
const xs = rows.map((r) => r[0]);
const only = (state) => rows.map((r) => (r[2] === state ? r[1] : null));
const dots = (label, color) => ({ label, stroke: color, paths: () => null, points: { show: true, size: 5, fill: color } });
const size = () => ({ width: innerWidth, height: innerHeight - 40 }); // legend below
const d = 86400;
const u = new uPlot(
  {
    ...size(),
    scales: { y: { range: [0, 100] } },
    axes: [
      {
        // uPlot's default time labels with a 24-hour clock: minimum tick increment, label,
        // then what gets appended when the year/month/day/hour/minute/second rolls over
        values: [
          [365 * d, "{YYYY}", null, null, null, null, null, null, 1],
          [28 * d, "{MMM}", "\n{YYYY}", null, null, null, null, null, 1],
          [d, "{M}/{D}", "\n{YYYY}", null, null, null, null, null, 1],
          [3600, "{HH}:{mm}", "\n{M}/{D}/{YY}", null, "\n{M}/{D}", null, null, null, 1],
          [60, "{HH}:{mm}", "\n{M}/{D}/{YY}", null, "\n{M}/{D}", null, null, null, 1],
          [1, ":{ss}", "\n{M}/{D}/{YY} {HH}:{mm}", null, "\n{M}/{D} {HH}:{mm}", null, "\n{HH}:{mm}", null, 1],
        ],
      },
      {},
    ],
    series: [
      { value: "{YYYY}-{MM}-{DD} {HH}:{mm}" },
      { label: "charge", stroke: "gray", points: { show: false } },
      dots("charging", "green"),
      dots("discharging", "red"),
    ],
  },
  [xs, rows.map((r) => r[1]), only("charging"), only("discharging")],
  document.body,
);
addEventListener("resize", () => u.setSize(size()));

// x range [a, b], clamped to the data
const [lo, hi] = [xs[0], xs.at(-1)];
function setX(a, b) {
  const w = Math.min(b - a, hi - lo);
  a = Math.min(Math.max(a, lo), hi - w);
  u.setScale("x", { min: a, max: a + w });
}
const over = u.over;

// touchpad: vertical scroll and pinch (ctrl+wheel) zoom, horizontal scroll pans, both by the scrolled distance
over.addEventListener(
  "wheel",
  (e) => {
    e.preventDefault();
    const { min, max } = u.scales.x;
    const rect = over.getBoundingClientRect();
    const px = e.deltaMode ? 16 : 1; // line mode -> pixels
    const perPx = (max - min) / rect.width;
    const at = min + (e.clientX - rect.left) * perPx;
    const f = Math.exp((e.deltaY * px) / (e.ctrlKey ? 100 : 300));
    const shift = e.deltaX * px * perPx;
    setX(at - (at - min) * f + shift, at + (max - at) * f + shift);
  },
  { passive: false },
);

// touchscreen: one finger pans, two fingers pinch; the time under the fingers stays under them
over.style.touchAction = "none";
const fingers = new Map();
let start;
const snapshot = () => {
  const xs = [...fingers.values()];
  return {
    mid: xs.reduce((s, x) => s + x, 0) / xs.length,
    dist: xs.length > 1 ? Math.abs(xs[0] - xs[1]) : 0,
    min: u.scales.x.min,
    max: u.scales.x.max,
  };
};
over.addEventListener("pointerdown", (e) => {
  if (e.pointerType !== "touch") return;
  e.preventDefault();
  over.setPointerCapture(e.pointerId);
  fingers.set(e.pointerId, e.clientX);
  start = snapshot();
});
over.addEventListener("pointermove", (e) => {
  if (!fingers.has(e.pointerId)) return;
  fingers.set(e.pointerId, e.clientX);
  const now = snapshot();
  const left = over.getBoundingClientRect().left;
  const perPx = (start.max - start.min) / over.clientWidth;
  const f = start.dist && now.dist ? start.dist / now.dist : 1;
  const at = start.min + (start.mid - left) * perPx;
  const a = at - (now.mid - left) * perPx * f;
  setX(a, a + (start.max - start.min) * f);
});
const lift = (e) => {
  if (fingers.delete(e.pointerId) && fingers.size) start = snapshot();
};
over.addEventListener("pointerup", lift);
over.addEventListener("pointercancel", lift);
