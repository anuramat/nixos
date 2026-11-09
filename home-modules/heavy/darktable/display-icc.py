# usage: display-icc.py EDID OUT
import sys, gi

gi.require_version("Colord", "1.0")
from gi.repository import Colord, Gio, GLib

edid = Colord.Edid.new()
edid.parse(GLib.Bytes.new(open(sys.argv[1], "rb").read()))
icc = Colord.Icc.new()
icc.create_from_edid_data(edid)
icc.set_description("", "display (EDID)")
icc.save_file(Gio.File.new_for_path(sys.argv[2]), Colord.IccSaveFlags.NONE, None)
