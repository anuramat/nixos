# the desktop layout, without the F-key row, Compose, Caps Lock, AltGr, right
# Ctrl and right Shift, and the layer switch
_: _final: prev: {
  wvkbd = prev.wvkbd.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [ ./wvkbd-layout.patch ];
    makeFlags = [ "LAYOUT=deskintl" ];
  });
}
