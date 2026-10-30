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
    # `notifyHook AGENT JQ`: a hook matcher group, shared by claude and codex,
    # that notifies with "AGENT (HOST:DIR): " and JQ applied to the hook's
    # input, cut to stay under ntfy's size limit; unlike the agents' built-in
    # notifications, it doesn't depend on terminal focus
    lib.agents.notifyHook = agent: jqMessage: {
      hooks = [
        {
          command = # bash
            ''jq -r --arg host "$(uname -n)" '"${agent} (\($host):\(.cwd | split("/") | last)): " + (${jqMessage})[:500]' | notify'';
          type = "command";
        }
      ];
    };
  };
}
