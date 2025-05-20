local modelname = 'qwen3:8b'
return {
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false,
    opts = {
      system_prompt = '\\no_think',
      -- mode = 'legacy', -- BUG required by models that don't support tools (tools are broken for ollama)
      provider = 'pollinations',
      vendors = {
        pollinations = {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = 'https://text.pollinations.ai/openai',
          model = 'openai',
        },
        -- TODO github models is not available yet <https://github.com/yetone/avante.nvim/issues/2042>
      },
      ollama = {
        endpoint = 'http://anuramat-ll7:11434',
        model = modelname,
        reasoning_effort = 'low', -- low|medium|high, only used for reasoning models
      },
    },
    build = 'make',
    dependencies = {
      'Kaiser-Yang/blink-cmp-avante',
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'MunifTanjim/nui.nvim',
      'ibhagwan/fzf-lua',
    },
  },
  -- {
  --   'ravitemer/mcphub.nvim',
  --   build = 'npm install -g mcp-hub@latest', -- installs `mcp-hub` node binary globally
  --   opts = {},
  -- },
  -- <https://ravitemer.github.io/mcphub.nvim/configuration.html>
}
