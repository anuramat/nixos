{ lib, config, ... }:
let
  inherit (lib)
    optionals
    types
    mkOption
    ;

  port = 11343;
in
{
  options.services.llama-cpp = {
    modelDir = mkOption {
      type = types.str;
    };
    modelWrapped = mkOption {
      type = types.submodule {
        options = {
          filename = mkOption {
            type = types.str;
          };
          params = mkOption {
            type = types.submodule {
              options = {
                mmprojFile = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                minP = mkOption {
                  type = types.nullOr types.float;
                  default = null;
                };
                temp = mkOption {
                  type = types.nullOr types.float;
                  default = null;
                };
                topK = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                };
                topP = mkOption {
                  type = types.nullOr types.float;
                  default = null;
                };
                jinja = mkOption {
                  type = types.bool;
                  default = true;
                };
                chatTemplateFile = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                chatTemplateKwargs = mkOption {
                  type = types.nullOr types.attrs;
                  default = null;
                };
                ctxSize = mkOption {
                  type = types.int;
                };
                parallel = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                };
              };
            };
          };
        };
      };
    };
  };
  config =
    let
      cfg = config.services.llama-cpp;
    in
    {

      environment = {
        systemPackages = [
          cfg.package
        ];
        sessionVariables = {
          LLAMA_CACHE = cfg.modelDir;
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        port
      ];

      services.llama-cpp = {
        openFirewall = false;
        host = "0.0.0.0";
        inherit port;
        model = "${cfg.modelDir}/${cfg.modelWrapped.filename}";
        extraFlags =
          let
            mkFlags =
              p:
              optionals (p.mmprojFile != null) [
                "--mmproj"
                p.mmprojFile
              ]

              ++ optionals (p.minP != null) [
                "--min-p"
                (toString p.minP)
              ]
              ++ optionals (p.temp != null) [
                "--temp"
                (toString p.temp)
              ]
              ++ optionals (p.topK != null) [
                "--top-k"
                (toString p.topK)
              ]
              ++ optionals (p.topP != null) [
                "--top-p"
                (toString p.topP)
              ]

              ++ optionals p.jinja [ "--jinja" ]
              ++ optionals (p.chatTemplateFile != null) [
                "--chat-template-file"
                p.chatTemplateFile
              ]
              ++ optionals (p.chatTemplateKwargs != null) [
                "--chat-template-kwargs"
                (builtins.toJSON p.chatTemplateKwargs)
              ]

              ++ [
                "--fit-ctx"
                (toString p.ctxSize)
              ]
              ++ optionals (p.parallel != null) [
                "-np"
                (toString p.parallel)
              ];
          in
          mkFlags cfg.modelWrapped.params;
      };
    };
}
