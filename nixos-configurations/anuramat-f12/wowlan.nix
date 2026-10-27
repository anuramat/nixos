# keep the wifi association through suspend, so that it's up right after
# resume: with a WoWLAN trigger armed, mac80211 leaves the firmware associated
# instead of disconnecting, and NetworkManager skips the takedown before sleep
{ pkgs, ... }:
{
  networking.networkmanager = {
    # stock NM still takes WoWLAN devices down after resume, to recheck
    # connectivity, which means a full reconnect anyway; patched, it only
    # does so if the link was lost while asleep, since otherwise NM waits
    # 30s for the supplicant to get the old AP back before moving on
    package = pkgs.networkmanager.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./networkmanager-keep-wowlan-on-resume.patch ];
    });
    # wake on magic packet; NM disables WoWLAN if this is unset
    settings.connection."wifi.wake-on-wlan" = 8;
  };
}
