{
  config,
  inputs,
  lib,
  osConfig ? null,
  ...
}:
let
  # standalone Home Manager peers with every local host
  hostName = if osConfig == null then "" else osConfig.networking.hostName;
  peers =
    inputs.self.keys
    |> lib.filterAttrs (n: k: inputs.self.hosts.${n}.local && n != hostName && k.syncthingId != null);
  folder = path: {
    inherit path;
    devices = lib.attrNames peers;
  };
in
{
  services.syncthing = {
    enable = true;
    # standalone secret paths contain an unexpanded ${XDG_RUNTIME_DIR}, which
    # the syncthing module doesn't expand
    guiCredentials = lib.mkIf (osConfig != null) {
      inherit (inputs.self.consts.user) username;
      passwordFile = config.lib.secrets.syncthing-gui.path;
    };
    # GUI changes to devices and folders are reverted on restart
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = lib.mapAttrs (_: k: { id = k.syncthingId; }) peers;
      folders = {
        # ids are from the pre-declarative setup, kept to avoid a resync
        fdqhg-aumsk = (folder "~/Zotero/storage") // {
          label = "zotero";
        };
        vrtne-gmxkp = (folder "~/books") // {
          label = "books";
        };
      };
    };
  };
}
