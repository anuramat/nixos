{ lib, config, ... }:
let
  inherit (lib)
    optionals
    types
    mkOption
    mkIf
    ;
in
{
  options.services.llama-cpp.modelExtra = mkOption {
    type = types.submodule {
      options = {
        id = mkOption { type = types.str; }; # e.g. "qwen3:4b"
        name = mkOption { type = types.nullOr types.str; }; # e.g. "Qwen3 4B"; TODO default to id
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
          };
        };
      };
    };
  };
  config.services.llama-cpp.extraFlags =
    let
      mkFlags =
        p:
        [ ]
        ++ optionals (p.mmprojFile != null) [
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

        ++ optionals (p.ctxSize != 0) [
          "-c"
          (toString p.ctxSize)
        ]
        ++ optionals p.flashAttn [ "-fa" ]
        ++ optionals (p.gpuLayers != null) [
          "-ngl"
          (toString p.gpuLayers)
        ]
        ++ optionals (p.nCpuMoe != null) [
          "-ncmoe"
          (toString p.nCpuMoe)
        ]
        ++ optionals (p.parallel != null) [
          "-np"
          (toString p.parallel)
        ];
    in
    mkFlags config.services.llama-cpp.modelExtra.params;
}
