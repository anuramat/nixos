# 'ray-x/go.nvim', -- golang aio plugin
{
  plugins.lsp.servers.gopls = {
    enable = true;
    settings = {
      gopls = {
        analyses = {
          shadow = true;
          unusedvariable = true;
          unusedwrite = true;
          useany = true;
        };
        codelenses = {
          gc_details = true;
          generate = true;
          regenerate_cgo = true;
          tidy = true;
          upgrade_dependency = true;
          vendor = true;
        };
        gofumpt = true;
        hints = {
          assignVariableTypes = false;
          compositeLiteralFields = false;
          compositeLiteralTypes = false;
          constantValues = false;
          functionTypeParameters = false;
          parameterNames = false;
          rangeVariableTypes = false;
        };
        semanticTokens = true;
        staticcheck = true;
        usePlaceholders = true;
      };
    };
  };
}
