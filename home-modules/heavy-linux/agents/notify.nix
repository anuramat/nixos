# notifies the user wherever they are: shown on this host, then routed by
# notify-forward to an unlocked peer or the phone
{
  config,
  lib,
  osConfig ? null,
  ...
}:
{
  config = {
    home.packages = lib.mkIf (osConfig != null) [
      (config.lib.ntfy.send "notify" "desktop-${osConfig.networking.hostName}")
    ];
    # `notifyHook AGENT { dir, name } JQ`: a hook matcher group, shared by
    # claude and codex, that notifies with the title "AGENT(HOST:DIR): NAME"
    # and the body JQ applied to the hook's input, cut to stay under ntfy's
    # size limit; DIR is a shell word and NAME an optional shell command, both
    # with the hook's input in $hook; unlike the agents' built-in
    # notifications, it doesn't depend on terminal focus
    lib.agents.notifyHook =
      agent:
      {
        dir,
        name ? "",
      }:
      jqMessage: {
        hooks = [
          {
            command = # bash
              ''
                hook=$(cat)
                dir=${dir}
                name=$(${name})
                printf '%s' "$hook" | jq -r '(${jqMessage})[:500]' |
                  notify -t "${agent}($(uname -n):''${dir##*/})''${name:+: $name}"
              '';
            type = "command";
          }
        ];
      };
  };
}
