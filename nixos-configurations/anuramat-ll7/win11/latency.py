"""Click-to-capture latency of the win11 VM through looking glass.

Clicks with a virtual mouse, and polls a screen pixel with wlr-screencopy until
the guest's page turns white. niri renders each capture on request, so the
latency ends when the looking glass client's window shows the change, before
niri's next frame and the panel's scanout.
Alternates blocks of samples with the page idle and redrawing every frame
(toggled with the A key), since an idle desktop lets the capture slow down. In
the guest, open this in a fullscreen browser, then focus the looking glass
client and park the cursor away from the sampled pixel (the output's center):

data:text/html,<body style="background:black" onmousedown="this.style.background='white'" onmouseup="this.style.background='black'" onkeydown="if(event.key=='a'){a=!a;a&&f()}"><div id=d style="width:9px;height:9px"></div><script>a=0;function f(){d.style.background=d.style.background?'':'gray';a&&requestAnimationFrame(f)}</script>
"""

import argparse
import json
import mmap
import os
import random
import statistics
import subprocess
import time

from evdev import UInput, ecodes as e
from pywayland.client import Display
from pywayland.protocol.wayland import WlOutput, WlShm
from pywayland.protocol.wlr_screencopy_unstable_v1 import ZwlrScreencopyManagerV1


class Pixel:
    """One pixel of an output, captured with wlr-screencopy."""

    def __init__(self, display, output, x, y):
        self.display, self.x, self.y = display, x, y
        outputs, self.buf = {}, None

        def bind(registry, name, interface, version):
            if interface == "wl_output":
                o = registry.bind(name, WlOutput, 4)
                o.dispatcher["name"] = lambda _, n: outputs.update({n: o})
            elif interface == "wl_shm":
                self.shm = registry.bind(name, WlShm, 1)
            elif interface == ZwlrScreencopyManagerV1.name:
                self.manager = registry.bind(name, ZwlrScreencopyManagerV1, 3)

        self.display.get_registry().dispatcher["global"] = bind
        self.display.roundtrip()  # globals
        self.display.roundtrip()  # output names
        self.output = outputs[output]

    def buffer(self, fmt, width, height, stride):
        if self.buf is None:
            size = stride * height
            fd = os.memfd_create("win11-latency")
            os.ftruncate(fd, size)
            self.mem = mmap.mmap(fd, size)
            pool = self.shm.create_pool(fd, size)
            self.buf = pool.create_buffer(0, width, height, stride, fmt)
        return self.buf

    def capture(self):
        """Presentation time of the captured frame, and if it's bright."""
        frame = self.manager.capture_output_region(0, self.output, self.x, self.y, 1, 1)
        done = []
        frame.dispatcher["buffer"] = lambda f, *b: setattr(self, "fmt", b)
        frame.dispatcher["buffer_done"] = lambda f: f.copy(self.buffer(*self.fmt))
        frame.dispatcher["ready"] = lambda f, hi, lo, ns: done.append(
            (hi << 32) + lo + ns / 1e9
        )
        frame.dispatcher["failed"] = lambda f: done.append(None)
        while not done:
            self.display.dispatch(block=True)
        frame.destroy()
        if done[0] is None:
            raise SystemExit("screencopy failed")
        return done[0], sum(self.mem[:3]) > 3 * 128


def wait_for(pixel, want, timeout=1.0):
    """Time of the first frame that shows `want` and the median poll period, or None."""
    end, times = time.monotonic() + timeout, []
    while time.monotonic() < end:
        t, bright = pixel.capture()
        times.append(t)
        if bright == want:
            gaps = [b - a for a, b in zip(times, times[1:])]
            return t, statistics.median(gaps) if gaps else 0
    return None


def tap(ui, code, value):
    ui.write(e.EV_KEY, code, value)
    ui.syn()


def sample(ui, pixel):
    """Click latency and the median poll period, in ms, or None."""
    if wait_for(pixel, False) is None:
        raise SystemExit("the sampled pixel isn't black, run with --help")
    t0 = time.monotonic()  # CLOCK_MONOTONIC, like the presentation times
    tap(ui, e.BTN_LEFT, 1)
    r = wait_for(pixel, True)
    tap(ui, e.BTN_LEFT, 0)
    return r and ((r[0] - t0) * 1000, r[1] * 1000)


def summary(lat):
    q = statistics.quantiles(lat, n=20)
    return (
        f"n={len(lat)} min={min(lat):.1f} median={statistics.median(lat):.1f}"
        f" p95={q[18]:.1f} max={max(lat):.1f} ms"
    )


def main():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("-n", type=int, default=100, help="samples")
    p.add_argument("-b", type=int, default=10, help="samples per idle/redraw block")
    args = p.parse_args()

    out = json.loads(subprocess.check_output(["niri", "msg", "-j", "focused-output"]))
    size = out["logical"]
    # disconnecting by hand destroys the proxies first; at exit, the
    # interpreter can free them after the display and crash
    with Display() as display:
        pixel = Pixel(display, out["name"], size["width"] // 2, size["height"] // 2)
        run(args, pixel)


def run(args, pixel):
    ui = UInput(
        {e.EV_KEY: [e.BTN_LEFT, e.KEY_A], e.EV_REL: [e.REL_X, e.REL_Y]},
        name="win11-latency",
    )
    print("focus the looking glass client, starting in 3s")
    time.sleep(3)  # also lets the compositor pick up the new device
    for _ in range(3):  # the first clicks also wake up the input path
        sample(ui, pixel)

    lat, periods, redraw = {False: [], True: []}, {False: [], True: []}, False
    for i in range(args.n):
        if redraw != (i // args.b % 2 == 1):
            redraw = not redraw
            tap(ui, e.KEY_A, 1)
            tap(ui, e.KEY_A, 0)
        time.sleep(random.uniform(0.1, 0.5))  # don't phase-lock to the refresh
        mode = "redraw" if redraw else "idle"
        if (s := sample(ui, pixel)) is None:
            print(f"{i} {mode}: timed out")
            continue
        lat[redraw].append(s[0])
        periods[redraw].append(s[1])
        print(f"{i} {mode}: {s[0]:.1f} ms")
    if redraw:
        tap(ui, e.KEY_A, 1)
        tap(ui, e.KEY_A, 0)
    ui.close()

    for redraw, mode in [(False, "idle:  "), (True, "redraw:")]:
        print(
            f"{mode} {summary(lat[redraw])};"
            f" poll period ~{statistics.median(periods[redraw]):.1f} ms"
        )


main()
