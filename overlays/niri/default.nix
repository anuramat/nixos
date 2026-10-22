# touchscreen gestures, which niri lacks, come from the niri-tablet patch
# series. niri hides everything but the lock surface while locked, so a local
# patch adds an `above-lock` layer rule, which can keep an on-screen keyboard
# over the lock screen; another lets an edge swipe fire while locked, like a
# bind's `allow-when-locked`. smithay forwards virtual keyboard keys straight
# to the focused client (niri#2212), so a third matches them against binds
{ inputs, lib, ... }:
_final: prev: {
  niri = prev.niri.overrideAttrs (old: {
    patches =
      (old.patches or [ ])
      ++ (
        lib.filesystem.listFilesRecursive "${inputs.niri-tablet}/pkg" |> lib.filter (lib.hasSuffix ".patch")
      )
      ++ [
        ./niri-above-lock.patch
        ./niri-edge-swipe-when-locked.patch
        ./niri-virtual-keyboard-binds.patch
      ];
  });
}
