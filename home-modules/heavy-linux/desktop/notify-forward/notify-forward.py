# forwards desktop notifications to ntfy: notify-forward TOPIC_URL
import sys
import time
import urllib.parse
import urllib.request

from jeepney import DBusAddress, new_method_call
from jeepney.io.blocking import open_dbus_connection

# apps that notify on the phone natively
SKIP = {"org.telegram.desktop"}
# at most BURST messages per WINDOW seconds, in case a loop slips through
BURST, WINDOW = 10, 60

bus = DBusAddress(
    "/org/freedesktop/DBus",
    bus_name="org.freedesktop.DBus",
    interface="org.freedesktop.DBus.Monitoring",
)
rule = "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"
conn = open_dbus_connection("SESSION")
conn.send_and_get_reply(new_method_call(bus, "BecomeMonitor", "asu", ([rule], 0)))

sent, dropped = [], 0
while True:
    msg = conn.receive()
    if msg.header.fields.get(8) != "susssasa{sv}i":  # 8: signature
        continue
    app, _, _, summary, body, _, hints, _ = msg.body
    # notifications that came from the phone are tagged by ancs4linux
    if "x-ancs4linux" in hints or hints.get("desktop-entry", ("", ""))[1] in SKIP:
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
    # query params, since headers can't carry non-latin1 titles
    title = urllib.parse.urlencode({"title": f"[{app}] {summary}" if app else summary})
    try:
        urllib.request.urlopen(
            f"{sys.argv[1]}?{title}", (body.strip() or summary).encode(), timeout=30
        )
    except OSError as e:
        print(e, file=sys.stderr)
