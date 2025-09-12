{ lib, ... }:
with lib;
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
  config.services.llama-cpp = {
    extraFlags = [ ]; # TODO build from modelExtra
  };
}
