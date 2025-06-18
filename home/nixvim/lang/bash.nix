{
  plugins.lsp.servers.bashls = {
    enable = true;
    settings = {
      bashIde = {
        shfmt = {
          binaryNextLine = true;
          caseIndent = true;
          simplifyCode = true;
          spaceRedirects = true;
        };
      };
    };
  };
}
