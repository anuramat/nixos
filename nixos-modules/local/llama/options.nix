{ lib, config, ... }:
with lib;
let
  cfg = config.services.llama-cpp.modelExtra;
  p = cfg.params;
  f = cfg.files;
  mkFlags =
    p: f:
    [ ]
    ++ optionals p.jinja [ "--jinja" ]
    ++ optionals (p.ctxSize != 0) [
      "-c"
      (toString p.ctxSize)
    ]
    ++ optionals (p.nCpuMoe != null) [
      "-ncmoe"
      (toString p.nCpuMoe)
    ]
    ++ optionals (p.parallel != null) [
      "-np"
      (toString p.parallel)
    ]
    ++ optionals (p.topK != null) [
      "--top-k"
      (toString p.topK)
    ]
    ++ optionals (p.temp != null) [
      "--temp"
      (toString p.temp)
    ]
    ++ optionals (p.minP != null) [
      "--min-p"
      (toString p.minP)
    ]
    ++ optionals (p.topP != null) [
      "--top-p"
      (toString p.topP)
    ]
    ++ optionals (p.chatTemplateKwargs != null) [
      "--chat-template-kwargs"
      (builtins.toJSON p.chatTemplateKwargs)
    ]
    ++ optionals (f.mmproj != null) [
      "--mmproj"
      f.mmproj
    ]
    ++ optionals p.flashAttn [ "-fa" ]
    ++ optionals (p.gpuLayers != null) [
      "-ngl"
      (toString p.gpuLayers)
    ];
in
{
  options.services.llama-cpp.modelExtra = mkOption {
    type = types.submodule (
      { lib, ... }:
      with lib;
      {
        options = {
          id = mkOption { type = types.str; }; # e.g. "qwen3:4b"
          name = mkOption { type = types.nullOr types.str; }; # e.g. "Qwen3 4B"; TODO default to id
          files = mkOption {
            type = types.submodule (
              { lib, ... }:
              with lib;
              {
                mmproj = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                chatTemplate = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
              }
            );
          };
          params = mkOption {
            type = types.submodule (
              { lib, ... }:
              with lib;
              {
                options = {
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
                  chatTemplateKwargs = mkOption {
                    type = types.nullOr types.attrs;
                    default = null;
                  };

                  ctxSize = mkOption {
                    type = types.int;
                    default = 0;
                  };
                  flashAttn = mkOption {
                    type = types.bool;
                    default = true;
                  };
                  gpuLayers = mkOption {
                    type = types.nullOr types.int;
                    default = 999;
                  };
                  nCpuMoe = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                  };
                  parallel = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                  };
                };
              }
            );
          };
        };
      }
    );
  };
  config.services.llama-cpp.extraFlags = mkIf (cfg ? params) (mkFlags p f);
}
