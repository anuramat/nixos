return {
  {
    'goerz/jupytext.nvim',
    version = '0.2.0',
    opts = {
      format = 'py:light',
    },
    lazy = false,
  },
  {
    'kiyoon/jupynium.nvim',
    ft = 'python',
    opts = {
      python_host = 'python',
      jupynium_file_pattern = { '*.ju.py' },
    },
  },
}
