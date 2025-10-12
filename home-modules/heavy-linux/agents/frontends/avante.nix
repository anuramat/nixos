# TODO commands (shortcuts)
# NOTE reads most context file names, but only reads the first one
# TODO only allow file edits without asking for permission every time
{
  config,
  pkgs,
  osConfig ? null,
  lib,
  hax,
  ...
}:
let
  inherit (config.lib) agents;
  inherit (lib) mapAttrs;

  shortcuts =
    agents.commands
    |> mapAttrs (
      n: v: with v; {
        inherit description;
        name = n;
        prompt = text;
        details = text;
      }
    );
in
{
  home.shellAliases = {
    avante = ''nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"'';
  };
  programs.nixvim = {
    plugins.blink-cmp.settings.sources = {
      per_filetype = {
        AvanteInput = hax.vim.lua ''
          { "avante", inherit_defaults = true }
        '';
      };
      providers.avante = {
        module = "blink-cmp-avante";
        name = "avante";
      };
    };
    plugins = {
      avante = {
        enable = true;
        settings = {
          inherit shortcuts;
          behaviour = {
            auto_approve_tool_permissions = true;
            enable_token_counting = false;
          };
          system_prompt =
            let
              path = pkgs.writeText "instructions.md" agents.instructions.generic;
            in
            hax.vim.luaf ''
              local file = io.open("${path}", "r")
              if file then
                local instructions = file:read("*a")
                file:close()
                return instructions
              end
            '';
          disabled_tools = [
            # "read_file"
            # "bash"
            "rag_search"
            "python"
            "git_diff"
            "git_commit"
            "glob"
            "search_keyword"
            "read_file_toplevel_symbols"
            "create_file"
            "move_path"
            "copy_path"
            "delete_path"
            "create_dir"
            "web_search"
            "fetch"
          ];
          # TODO hook up litellm
          provider = "cerebras";
          providers = {
            cerebras = {
              endpoint = "https://api.cerebras.ai/v1";
              __inherited_from = "openai";
              model = "qwen-3-coder-480b";
              api_key_name = if osConfig != null then "cmd:cat ${osConfig.age.secrets.cerebras.path}" else "";
            };
            copilot = {
              model = "gpt-4.1";
            };
          };
        };
      };
    };
  };
}
