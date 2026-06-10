{
  lib,
  config,
  options,
  inputs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    optionals
    types
    mkOption
    ;

  cfg = config.services.llama-cpp;
  modelDirSet = options.services.llama-cpp.modelDir.isDefined;
  inherit (inputs.self.llama) port;
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
                chatTemplateFile = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                chatTemplateKwargs = mkOption {
                  type = types.nullOr types.attrs;
                  default = null;
                };
                fit = mkOption {
                  type = types.bool;
                  default = false;
                };
                ctxSize = mkOption {
                  type = types.int;
                };
                parallel = mkOption {
                  type = types.int;
                };
              };
            };
          };
        };
      };
    };
  };
  config = mkMerge [
    (mkIf modelDirSet {
      environment.sessionVariables.LLAMA_CACHE = cfg.modelDir;
    })

    (mkIf cfg.enable {

      environment = {
        systemPackages = [
          cfg.package
        ];
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

              ++ optionals (p.chatTemplateFile != null) [
                "--chat-template-file"
                p.chatTemplateFile
              ]
              ++ optionals (p.chatTemplateKwargs != null) [
                "--chat-template-kwargs"
                (builtins.toJSON p.chatTemplateKwargs)
              ]

              ++ [
                (if p.fit then "--fit-ctx" else "-c")
                (toString p.ctxSize)
              ]
              ++ [
                "-np"
                (toString p.parallel)
              ];
          in
          mkFlags cfg.modelWrapped.params;
      };
    })
  ];
}
