local u = require('utils')
return u.join_map({
  configs = {
    'zathurarc',
    'ssh_config',
    'tmux',
  },
  data = {
    'json',
    'json5',
    'jsonc',
    'tsv',
    'psv',
  },
  langs = {
    'awk',
    'bash',
    'c',
    'go',
    'haskell',
    'lua',
    'typescript',
    'perl',
    'python',
    'sql',
    'javascript',
    'rust',
  },
  go = {
    'gomod',
    'gosum',
    'gotmpl',
    'gowork',
  },
  misc = {
    'css',
    'haskell_persistent',
    'html',
    'http',
    'jq',
    'latex',
    'luadoc',
    'luap',
    'make',
    'markdown',
    'markdown_inline',
    'nix',
    'printf',
    'proto',
    'query',
    'readline',
    'regex',
    'requirements', -- python requirements.txt
    'scss',
    'toml',
    'udev',
    'vim',
    'vimdoc',
    'xml',
    'yaml',
  },
  git = {
    'git_config',
    'git_rebase',
    'gitattributes',
    'gitcommit',
    'gitignore',
  },
})
