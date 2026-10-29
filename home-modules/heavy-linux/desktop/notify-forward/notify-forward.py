# routes desktop notifications to wherever the user is: an unlocked peer, or
# the phone; shows the ones routed to this host
# usage: notify-forward NTFY_URL HOST [PEER...]
import io
import json
import os
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request

from jeepney import DBusAddress, DBusErrorResponse, new_method_call
from jeepney.io.blocking import open_dbus_connection
from PIL import Image

NTFY, HOST, PEERS = sys.argv[1], sys.argv[2], sys.argv[3:]
PHONE = "notify-forward"  # topic the phone subscribes to
# apps that notify on the phone and the peers natively
SKIP = {"org.telegram.desktop"}
# at most BURST messages per WINDOW seconds, in case a loop slips through
BURST, WINDOW = 10, 60
# niri sets the hint on the user's display session
LOCKED = 'loginctl show-session "$(loginctl show-user "$USER" -p Display --value)" -p LockedHint --value'
IMAGES = os.path.join(os.environ["XDG_RUNTIME_DIR"], "notify-forward")

notifications = DBusAddress(
    "/org/freedesktop/Notifications",
    bus_name="org.freedesktop.Notifications",
    interface="org.freedesktop.Notifications",
)


def topic(host):
    return f"desktop-{host}"


def unlocked(host):
    """unreachable hosts count as locked"""
    cmd = ["sh", "-c", LOCKED] if host == HOST else ["ssh", f"_bg-{host}", LOCKED]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    return out.strip() == "no"


def image(hints):
    """(filename, bytes) of the notification's image, if any"""
    if "image-path" in hints:
        path = urllib.parse.unquote(hints["image-path"][1].removeprefix("file://"))
        try:  # may also be an icon name
            with open(path, "rb") as f:
                return os.path.basename(path), f.read()
        except OSError:
            return None
    if "image-data" in hints:
        w, h, stride, alpha, _, _, data = hints["image-data"][1]
        mode = "RGBA" if alpha else "RGB"
        png = io.BytesIO()
        Image.frombytes(mode, (w, h), bytes(data), "raw", mode, stride).save(png, "PNG")
        return "image.png", png.getvalue()


def publish(to, params, img):
    """the body is the attachment, if any"""
    data = b""
    if img:
        params["filename"], data = img
    try:
        # query params, since headers can't carry non-latin1 titles
        urllib.request.urlopen(
            f"{NTFY}/{to}?{urllib.parse.urlencode(params)}", data, timeout=30
        )
    except OSError as e:
        print(e, file=sys.stderr)


def show(conn, ev):
    """posts a message from this host's topic as a desktop notification"""
    origin = ",".join(ev.get("tags", []))
    message = ev.get("message", "")
    hints = {}
    if origin and origin != HOST:
        hints["x-forwarded"] = ("s", origin)
    if (att := ev.get("attachment")) and att.get("type", "").startswith("image/"):
        os.makedirs(IMAGES, exist_ok=True)
        path = os.path.join(IMAGES, ev["id"] + "-" + att["name"])
        urllib.request.urlretrieve(att["url"], path)
        hints["image-path"] = ("s", path)
    elif att:  # other files stay on the server, reachable over the tailnet
        message += f"\n{att['url']}"
    title = ev.get("title") or message
    body = message if ev.get("title") else ""
    conn.send_and_get_reply(
        new_method_call(
            notifications,
            "Notify",
            "susssasa{sv}i",
            (origin or "ntfy", 0, "", title, body, [], hints, -1),
        )
    )


def subscribe():
    conn = open_dbus_connection("SESSION")
    since = ""
    while True:
        try:
            url = f"{NTFY}/{topic(HOST)}/json" + (f"?since={since}" if since else "")
            # ntfy sends a keepalive every 45s
            with urllib.request.urlopen(url, timeout=90) as stream:
                for line in stream:
                    ev = json.loads(line)
                    if ev["event"] == "message":
                        since = ev["id"]
                        show(conn, ev)
        except (OSError, ValueError, DBusErrorResponse) as e:
            print(e, file=sys.stderr)
            time.sleep(5)


def destinations(hints):
    """topics to route a local notification to"""
    # the phone's own notifications, mirrored by ancs4linux
    if "x-ancs4linux" in hints or hints.get("desktop-entry", ("", ""))[1] in SKIP:
        return []
    if unlocked(HOST):
        return []
    # one that came from a peer only ever moves on to the phone, so that
    # notifications can't bounce between hosts
    if "x-forwarded" in hints:
        return [PHONE]
    return [topic(p) for p in PEERS if unlocked(p)] or [PHONE]


def monitor():
    bus = DBusAddress(
        "/org/freedesktop/DBus",
        bus_name="org.freedesktop.DBus",
        interface="org.freedesktop.DBus.Monitoring",
    )
    rule = (
        "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"
    )
    conn = open_dbus_connection("SESSION")
    conn.send_and_get_reply(new_method_call(bus, "BecomeMonitor", "asu", ([rule], 0)))
    sent, dropped = [], 0
    while True:
        msg = conn.receive()
        if msg.header.fields.get(8) != "susssasa{sv}i":  # 8: signature
            continue
        app, _, _, summary, body, _, hints, _ = msg.body
        to = destinations(hints)
        if not to:
            continue
        now = time.monotonic()
        sent = [t for t in sent if now - t < WINDOW]
        if len(sent) >= BURST:
            dropped += 1
            continue
        sent.append(now)
        if dropped:
            body += f"\n(+{dropped} dropped)"
            dropped = 0
        params = {
            "title": f"[{app}] {summary}" if app else summary,
            "message": body.strip() or summary,
            "tags": hints.get("x-forwarded", ("s", HOST))[1],  # the origin host
        }
        img = image(hints)
        for t in to:
            publish(t, params, img)


threading.Thread(target=subscribe, daemon=True).start()
monitor()
