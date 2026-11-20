{
  # snacks converts non-png images with imagemagick
  dependencies.imagemagick.enable = true;
  plugins = {
    img-clip.enable = true;
    # kitty protocol only; also used by fzf-lua previews; too slow over ssh; inside zellij the
    # environment is that of the client that created the session, so zellij's answer decides
    snacks = {
      enable = true;
      settings.image.enabled.__raw = "vim.env.SSH_CONNECTION == nil or vim.env.ZELLIJ ~= nil";
    };
  };
  # snacks takes zellij to have no images; ours has them, with unicode placeholders, and
  # answers the query for the attached clients
  extraConfigLua = ''
    if vim.env.ZELLIJ then
      vim.api.nvim_create_autocmd("TermResponse", {
        callback = function(ev)
          local reply = ev.data.sequence:match("^\27_Gi=31;(%a+)")
          if reply then
            local zellij = vim.iter(Snacks.image.terminal.envs()):find(function(env)
              return env.name == "zellij"
            end)
            zellij.supported, zellij.placeholders = reply == "OK", reply == "OK"
            return true
          end
        end,
      })
      vim.api.nvim_ui_send("\27_Gi=31,s=1,v=1,a=q,t=d,f=24,U=1;AAAA\27\\")
    end
  '';
}
