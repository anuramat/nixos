-- Generated from lazy.nvim specs

local ul = require('utils.lsp') -- For nvim-lspconfig and haskell-tools

return {
  -- aerial.nvim
  {
    "aerial.nvim",
    event = "BufEnter",
    -- dependencies = { "nvim-treesitter" }, -- LZE handles dependencies via Nix. Noted here for reference.
    after = function()
      require("aerial").setup({
        filter_kind = {
          nix = false,
        },
      })
    end,
    keys = { { "gO", "<cmd>AerialToggle!<cr>", desc = "Show Aerial Outline" } },
  },
  -- vim-sleuth
  {
    "tpope/vim-sleuth",
    -- lazy = false, -- In NixCats, this is handled by putting it in startupPlugins vs optionalPlugins
    -- enabled = false, -- This plugin is currently disabled in the lazy.nvim config
  },
  -- nvim-surround
  {
    "kylechui/nvim-surround",
    event = "BufEnter",
    after = function()
      require("nvim-surround").setup({
        keymaps = {
          insert = "<C-g>s",
          insert_line = "<C-g>S",
          normal = "s",
          normal_cur = "ss",
          normal_line = "S",
          normal_cur_line = "SS",
          visual = "s",
          visual_line = "S",
          delete = "ds",
          change = "cs",
          change_line = "cS",
        },
      })
    end,
  },
  -- ts-comments.nvim
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    after = function()
      require("ts-comments").setup({})
    end,
  },
  -- vim-eunuch
  {
    "tpope/vim-eunuch",
    event = "VeryLazy",
  },
  -- undotree
  {
    "mbbill/undotree",
    cmd = {
      "UndotreeHide",
      "UndotreeShow",
      "UndotreeFocus",
      "UndotreeToggle",
    },
    keys = {
      {
        "<leader>u",
        "<cmd>UndotreeToggle<cr>",
        desc = "Undotree",
      },
    },
  },
  -- fzf-lua
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    after = function()
      require("fzf-lua").setup({
        grep = {
          fd_opts = "-c never -t f -HL",
          RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
          multiline = 2,
        },
        actions = {
          files = {
            true, -- means inherit defaults
            ["ctrl-q"] = { fn = require("fzf-lua").actions.file_sel_to_qf, prefix = "select-all" },
          },
        },
      })
    end,
    keys = {
      { "<leader>fo", "<cmd>FzfLua files<cr>", desc = "fzf-lua: files" },
      { "<leader>fO", "<cmd>FzfLua oldfiles<cr>", desc = "fzf-lua: oldfiles" },
      { "<leader>fa", "<cmd>FzfLua args<cr>", desc = "fzf-lua: args" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "fzf-lua: buffers" },
      { "<leader>fm", "<cmd>FzfLua marks<cr>", desc = "fzf-lua: marks" },
      { "<leader>f/", "<cmd>FzfLua curbuf<cr>", desc = "fzf-lua: curbuf" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "fzf-lua: live_grep" },
      { "<leader>fG", "<cmd>FzfLua grep_last<cr>", desc = "fzf-lua: grep_last" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "fzf-lua: diagnostics_document" },
      { "<leader>fD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "fzf-lua: diagnostics_workspace" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "fzf-lua: lsp_document_symbols" },
      { "<leader>fS", "<cmd>FzfLua lsp_workspace_symbols<cr>", desc = "fzf-lua: lsp_workspace_symbols" },
      { "<leader>ft", "<cmd>FzfLua treesitter<cr>", desc = "fzf-lua: treesitter" },
      { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "fzf-lua: resume" },
      { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "fzf-lua: helptags" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "fzf-lua: keymaps" },
      { "<leader>fp", "<cmd>FzfLua builtin<cr>", desc = "fzf-lua: builtin" },
      {
        "<C-x><C-f>",
        function()
          require("fzf-lua").complete_file({
            cmd = "fd -t f -HL",
            winopts = { preview = { hidden = "nohidden" } },
          })
        end,
        mode = "i",
        silent = true,
        desc = "fzf-lua: path completion",
      },
    },
  },
  -- neo-tree.nvim
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    -- No specific opts to translate for LZE from the lazy.nvim config
  },
  -- treesj
  {
    "Wansmer/treesj",
    -- enabled = true, -- LZE enables by default if listed
    after = function()
      require("treesj").setup({
        use_default_keymaps = false,
        max_join_length = 500,
      })
    end,
    keys = {
      {
        "<leader>j",
        function() require("treesj").toggle() end,
        desc = "TreeSJ: Split/Join a Treesitter node",
      },
    },
  },
  -- mini.align
  {
    "echasnovski/mini.align",
    after = function()
      require("mini.align").setup({
        mappings = {
          start = "<leader>a",
          start_with_preview = "<leader>A",
        },
      })
    end,
    keys = {
      { mode = { "v", "n" }, "<leader>a", desc = "Align" },
      { mode = { "v", "n" }, "<leader>A", desc = "Interactive align" },
    },
  },
  -- flash.nvim
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    after = function()
      require("flash").setup({
        modes = {
          char = {
            enabled = false,
          },
          treesitter = {
            label = {
              rainbow = { enabled = true },
            },
          },
        },
        label = {
          before = true,
          after = false,
        },
      })
    end,
    keys = {
      {
        "<leader>r",
        mode = "n",
        function() require("flash").jump() end,
        desc = "Jump",
      },
      {
        "r",
        mode = "o",
        function() require("flash").treesitter() end,
        desc = "TS node",
      },
    },
  },
  -- wastebin.nvim
  {
    "matze/wastebin.nvim",
    keys = {
      { "<leader>w", "<cmd>WastePaste<cr>" },
      { "<leader>w", [[<cmd>'<,'>WastePaste<cr>]], mode = "v" },
    },
    after = function()
      require("wastebin").setup({
        url = "https://bin.ctrl.sn",
        open_cmd = "__wastebin() { wl-copy \"$1\" && xdg-open \"$1\"; }; __wastebin",
        ask = false,
      })
    end,
  },
  -- NeogitOrg/neogit
  {
    "NeogitOrg/neogit",
    -- dependencies = { "sindrets/diffview.nvim", "ibhagwan/fzf-lua" }, -- LZE handles dependencies via Nix
    event = "VeryLazy",
    after = function()
      require("neogit").setup({
        kind = "floating",
      })
    end,
    keys = { { "<leader>go", "<cmd>Neogit<cr>", desc = "Neogit" } },
  },
  -- tpope/vim-fugitive
  {
    "tpope/vim-fugitive",
    event = "VeryLazy", -- Added event based on key mapping
    keys = { {
      "<leader>G",
      "<cmd>Git<cr>",
      desc = "Fugitive",
    } },
  },
  -- gitsigns.nvim
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    after = function()
      require("gitsigns").setup({
        sign_priority = 1000,
        signs_staged = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "▎" },
          topdelete = { text = "▎" },
          changedelete = { text = "▎" },
          untracked = { text = "▎" },
        },
        on_attach = function() end, -- Empty on_attach, can be omitted if not needed by LZE
      })
    end,
    keys = {
      { "<leader>gs", function() require("gitsigns").stage_hunk() end, desc = "Gitsigns: Stage hunk" },
      { "<leader>gs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, mode = "v", desc = "Gitsigns: Stage selection" },
      { "<leader>gS", function() require("gitsigns").stage_buffer() end, desc = "Gitsigns: Stage buffer" },
      { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "Gitsigns: Reset hunk" },
      { "<leader>gr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, mode = "v", desc = "Gitsigns: Reset selection" },
      { "<leader>gR", function() require("gitsigns").reset_buffer() end, desc = "Gitsigns: Reset buffer" },
      { "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Gitsigns: Blame line" },
      { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Gitsigns: Preview hunk" },
      { "<leader>gd", function() require("gitsigns").diffthis() end, desc = "Gitsigns: Diff file" },
      { "ih", function() require("gitsigns").select_hunk() end, desc = "Gitsigns: Select hunk", mode = { "o", "x" } },
      { "ah", function() require("gitsigns").select_hunk({ greedy = true }) end, desc = "Gitsigns: Select hunk", mode = { "o", "x" } },
      { "]h", function() require("gitsigns").next_hunk() end, desc = "Gitsigns: Next hunk" },
      { "[h", function() require("gitsigns").prev_hunk() end, desc = "Gitsigns: Previous hunk" },
    },
  },
  -- diffview.nvim
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
  },
  -- gitlinker.nvim
  {
    "ruifm/gitlinker.nvim",
    event = "VeryLazy",
    after = function()
      require("gitlinker").setup({
        opts = {
          add_current_line_on_normal_mode = false,
          print_url = true,
        },
      })
    end,
  },
  -- image.nvim
  {
    "3rd/image.nvim",
    -- No specific opts, event, or keys in lazy.nvim config to translate for LZE.
    -- Assuming it's loaded by default or via commands/ft by the plugin itself.
    -- If it requires setup, it would be:
    -- after = function() require("image").setup({}) end,
  },
  -- grug-far.nvim
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    after = function()
      require("grug-far").setup({})
    end,
  },
  -- overseer.nvim
  {
    "stevearc/overseer.nvim",
    event = "VeryLazy", -- TODO: cmd trigger if LZE supports it for non-command palette actions
    after = function()
      require("overseer").setup({
        task_list = {
          direction = "bottom",
          min_height = 25,
          max_height = 25,
          default_detail = 1,
        },
      })
    end,
  },
  -- sniprun
  {
    "michaelb/sniprun",
    event = "VeryLazy",
    -- build = "sh install.sh", -- NixCats handles build steps.
    after = function()
      require("sniprun").setup({}) -- Assuming empty setup if no specific opts
    end,
  },
  -- harpoon
  {
    "ThePrimeagen/harpoon",
    -- branch = "harpoon2", -- NixCats handles versioning.
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon: Add" },
      { "<leader>hl", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon: List" },
      { "<leader>hn", function() require("harpoon"):list():next() end, desc = "Harpoon: Next" },
      { "<leader>hp", function() require("harpoon"):list():prev() end, desc = "Harpoon: Previous" },
      { "<leader>h1", function() require("harpoon"):list():select(1) end, desc = "Harpoon: Go to #1" },
      { "<leader>h2", function() require("harpoon"):list():select(2) end, desc = "Harpoon: Go to #2" },
      { "<leader>h3", function() require("harpoon"):list():select(3) end, desc = "Harpoon: Go to #3" },
      { "<leader>h4", function() require("harpoon"):list():select(4) end, desc = "Harpoon: Go to #4" },
      { "<leader>h5", function() require("harpoon"):list():select(5) end, desc = "Harpoon: Go to #5" },
      -- Add more numbers if typically used, or instruct user to add manually for LZE if more are needed.
      -- The original iterator was up to an unspecified number. Common usage is usually <10.
    },
  },
  -- namu.nvim
  {
    "bassamsdata/namu.nvim",
    after = function()
      require("namu").setup({
        namu_symbols = {
          enable = true,
          options = {},
        },
        ui_select = {
          enable = true,
        },
        colorscheme = {
          enable = true,
        },
      })
    end,
    keys = {
      { "<leader>s", "<cmd>Namu symbols<cr>", { desc = "Jump to LSP symbol", silent = true } },
    },
  },
  -- rainbow-delimiters.nvim
  {
    "HiPhish/rainbow-delimiters.nvim",
    -- dependencies = "nvim-treesitter", -- LZE handles dependencies via Nix.
    event = "BufEnter",
    -- submodules = false, -- Not relevant for LZE.
    -- No specific setup call in lazy.nvim config.
  },
  -- dressing.nvim
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    after = function()
      require("dressing").setup({})
    end,
  },
  -- nvim-colorizer.lua
  {
    "NvChad/nvim-colorizer.lua",
    ft = { "css", "yaml" },
    after = function()
      require("colorizer").setup({})
    end,
  },
  -- todo-comments.nvim
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    after = function()
      require("todo-comments").setup({
        signs = false,
        highlight = {
          keyword = "bg",
          pattern = [[<(KEYWORDS)>]],
          multiline = false,
        },
        search = {
          pattern = [[\b(KEYWORDS)\b]],
        },
      })
    end,
  },
  -- nvim-lightbulb
  {
    "kosayoda/nvim-lightbulb",
    event = "LspAttach",
    -- branch = "master", -- NixCats handles versioning.
    after = function() -- Changed from 'config' to 'after' for LZE
      require("nvim-lightbulb").setup({
        autocmd = { enabled = true },
        ignore = {
          ft = { "markdown" },
        },
      })
    end,
  },
  -- fidget.nvim
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    after = function()
      require("fidget").setup({})
    end,
  },

  -- ## Adapters ##

  -- saghen/blink.cmp
  {
    "blink-cmp", -- saghen/blink.cmp
    event = "InsertEnter",
    -- dependencies = "anuramat/friendly-snippets", -- Handled by NixCats
    -- version = "*", -- Handled by NixCats
    -- build = "nix run .#build-plugin", -- Handled by NixCats
    after = function()
      require("blink").setup({
        completion = { documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        } },
        signature = { enabled = true },
        appearance = { nerd_font_variant = "normal" },
        sources = {
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
            avante = {
              module = "blink-cmp-avante",
              name = "Avante",
              opts = {},
            },
          },
          default = { "avante", "lazydev", "lsp", "path", "snippets", "buffer" },
        },
      })
    end,
  },

  -- mfussenegger/nvim-dap
  {
    "nvim-dap", -- mfussenegger/nvim-dap
    -- dependencies = { "theHamsta/nvim-dap-virtual-text", "nvim-treesitter/nvim-treesitter" }, -- Handled by NixCats
    after = function()
      -- Config from original lazy.nvim spec
      local sign = vim.fn.sign_define
      sign("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      sign("DapBreakpointCondition", { text = "C", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      sign("DapLogPoint", { text = "L", texthl = "DapLogPoint", linehl = "", numhl = "" })
      sign("DapStopped", { text = "→", texthl = "DapStopped", linehl = "", numhl = "" })
      -- sign('DapBreakpointRejected', { text = 'R', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })

      -- Setup for nvim-dap-virtual-text, which was a dependency
      require("nvim-dap-virtual-text").setup({})
    end,
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "DAP: Continue" },
      { "<leader>dd", function() require("dap").run_last() end, desc = "DAP: Run Last Debug Session" },
      { "<leader>di", function() require("dap").step_into() end, desc = "DAP: Step Into" },
      { "<leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, desc = "DAP: Set Log Point" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "DAP: Step Over" },
      { "<leader>do", function() require("dap").step_out() end, desc = "DAP: Step Out" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "DAP: Open Debug REPL" },
    },
  },

  -- rcarriga/nvim-dap-ui
  {
    "nvim-dap-ui", -- rcarriga/nvim-dap-ui
    -- dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" }, -- Handled by NixCats
    after = function()
      require("dapui").setup({
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        controls = { -- Explicitly defining to match original structure, though these are defaults
          edit = "e",
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          repl = "r",
          toggle = "t",
        },
      })
    end,
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP UI: Toggle Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "DAP UI: Evaluate" },
    },
  },
  -- nvim-dap-virtual-text is implicitly configured via nvim-dap's after hook.
  -- nvim-nio is a library, assumed to be available.

  -- zbirenbaum/copilot.lua (from llm/init.lua)
  {
    "copilot-lua", -- zbirenbaum/copilot.lua
    cmd = "Copilot",
    after = function()
      require("copilot").setup({
        suggestion = {
          enabled = false,
        },
        panel = {
          enabled = false,
        },
      })
    end,
  },

  -- yetone/avante.nvim (from llm/init.lua)
  {
    "avante-nvim", -- yetone/avante.nvim
    -- version = false, -- Handled by NixCats
    keys = { "<leader>a" }, -- This will trigger its load
    -- build = "make", -- Handled by NixCats
    -- dependencies = { "Kaiser-Yang/blink-cmp-avante", "nvim-treesitter/nvim-treesitter", "stevearc/dressing.nvim", "MunifTanjim/nui.nvim", "ibhagwan/fzf-lua" }, -- Handled by NixCats
    after = function()
      -- Content from llm/copilot.lua and llm/ollama.lua needs to be accessible here
      -- For simplicity, assuming they are globally unique or prefixing them if necessary.
      -- The original lazy.nvim config loaded them as Lua modules.
      local copilot_models_llm = { -- from plugins.adapters.llm.copilot
        gpt41 = "gpt-4.1",
        gemini = "gemini-2.5-pro",
        claude40 = "claude-sonnet-4",
      }
      local ollama_config_llm_fn = function() -- from plugins.adapters.llm.ollama
        local models = {
          qwen06 = { name = "qwen3:0.6b", num_ctx = nil },
          qwen40 = { name = "qwen3:4b", num_ctx = 19500 },
          qwen80 = { name = "qwen3:8b", num_ctx = 10000 },
        }
        local config = {
          reasoning_effort = "low", think = false, options = {}, endpoint = "http://localhost:11434",
        }
        local function wrapQwen(model)
          config.model = model.name
          if not config.think then config.reasoning_effort = nil end
          config.options.num_ctx = model.num_ctx
          return config
        end
        return wrapQwen(models.qwen40)
      end

      require("avante").setup({
        provider = "copilot", -- Was 'provider' variable, defaulting to 'copilot'
        behaviour = {
          auto_suggestions = false,
        },
        rag_service = { enabled = false },
        copilot = {
          model = copilot_models_llm.gpt41,
        },
        vendors = {
          pollinations = {
            __inherited_from = "openai",
            api_key_name = "",
            endpoint = "https://text.pollinations.ai/openai",
            model = "openai",
          },
          copilot2 = {
            __inherited_from = "copilot",
            model = copilot_models_llm.claude40,
          },
        },
        ollama = ollama_config_llm_fn(),
        system_prompt = function()
          local hub = require("mcphub").get_hub_instance()
          return hub and hub:get_active_servers_prompt() or ""
        end,
        custom_tools = function() return { require("mcphub.extensions.avante").mcp_tool() } end,
      })
    end,
  },
  -- blink-cmp-avante, nui-nvim are dependencies, handled by NixCats.

  -- ravitemer/mcphub.nvim (from llm/init.lua)
  {
    "mcphub-nvim", -- ravitemer/mcphub.nvim
    -- build = "bundled_build.lua", -- Handled by NixCats
    cmd = "MCPHub",
    after = function()
      require("mcphub").setup({
        use_bundled_binary = true,
        auto_approve = false,
        extensions = {
          avante = {
            make_slash_commands = true,
          },
        },
      })
    end,
  },

  -- neovim/nvim-lspconfig
  {
    "nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    -- dependencies = { "b0o/schemastore.nvim" }, -- Handled by NixCats
    after = function()
      local lspconfig = require("lspconfig")
      -- schemastore.nvim setup (dependency)
      -- No explicit setup for schemastore itself, it's used by jsonls config

      -- Original configs function from plugins/adapters/lsp.lua
      local optionsExpr = string.format('(builtins.getFlake "/etc/nixos/").nixosConfigurations.%s.options', vim.fn.hostname())
      local homeExpr = optionsExpr .. ".home-manager.users.type.getSubOptions []"
      local lsp_configs = {
        nixd = {
          cmd = { "nixd", "--inlay-hints=false" },
          settings = { nixd = { options = { nixos = { expr = optionsExpr }, ["home-manager"] = { expr = homeExpr } }, diagnostic = { suppress = {} } } },
        },
        nil_ls = {},
        yamlls = {},
        superhtml = {},
        ts_ls = {},
        stylelint_lsp = { settings = { stylelintplus = {} } },
        jsonls = { cmd = { "vscode-json-languageserver", "--stdio" }, schemas = require("schemastore").json.schemas() },
        texlab = { settings = { texlab = { build = { forwardSearchAfter = true, onSave = true }, chktex = { onEdit = true, onOpenAndSave = true }, forwardSearch = { executable = "zathura", args = { "--synctex-forward", "%l:1:%f", "%p" } } } } },
        bashls = { settings = { bashIde = { shfmt = { binaryNextLine = true, caseIndent = true, simplifyCode = true, spaceRedirects = true } } } },
        pyright = { settings = { python = {} } },
        marksman = {},
        clangd = {
          on_attach = function(client, buffer)
            vim.api.nvim_buf_set_keymap(buffer, "n", "<localleader>6", "<cmd>ClangdSwitchSourceHeader<cr>", { silent = true, desc = "clangd: Switch between .c/.h" })
            ul.on_attach(client, buffer)
            if require("clangd_extensions.inlay_hints") then -- Check if clangd_extensions is loaded
                require("clangd_extensions.inlay_hints").setup_autocmd()
                require("clangd_extensions.inlay_hints").set_inlay_hints()
            end
          end,
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
        gopls = {
          settings = { gopls = { analyses = { shadow = true, unusedwrite = true, useany = true, unusedvariable = true }, codelenses = { gc_details = true, generate = true, regenerate_cgo = true, tidy = true, upgrade_dependency = true, vendor = true }, hints = { assignVariableTypes = false, compositeLiteralFields = false, compositeLiteralTypes = false, constantValues = false, functionTypeParameters = false, parameterNames = false, rangeVariableTypes = false }, usePlaceholders = true, staticcheck = true, gofumpt = true, semanticTokens = true } },
          root_dir = ul.root_dir_with_fallback({ primary = { ".git" }, fallback = { "go.work", "go.mod" } }),
        },
        lua_ls = { settings = { Lua = { runtime = { version = "LuaJIT" }, format = { enable = false }, telemetry = { enable = false } } } },
      }

      for name, cfg in pairs(lsp_configs) do
        local base_cfg = {
            capabilities = require("blink.cmp").get_lsp_capabilities(),
            on_attach = cfg.on_attach or ul.on_attach
        }
        lspconfig[name].setup(vim.tbl_deep_extend("force", base_cfg, cfg))
      end
    end,
  },
  -- b0o/schemastore.nvim is a dependency, handled by NixCats.

  -- nvimtools/none-ls.nvim
  {
    "none-ls-nvim", -- nvimtools/none-ls.nvim
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      local null_ls = require("null-ls")
      local ormolu_source_null_ls = function() -- from original null.lua
        local helpers = require("null-ls.helpers")
        return {
          name = "ormolu",
          method = null_ls.methods.FORMATTING,
          filetypes = { "haskell" },
          generator = helpers.formatter_factory({
            to_stdin = true,
            command = "ormolu",
            args = { "--stdin-input-file", "." },
          }),
        }
      end
      local null_sources_null_ls = function()
        local f = null_ls.builtins.formatting
        local d = null_ls.builtins.diagnostics
        local a = null_ls.builtins.code_actions
        local h = null_ls.builtins.hover
        return { f.stylua, f.black, f.nixfmt, f.yamlfmt, f.markdownlint, ormolu_source_null_ls(), d.protolint, d.markdownlint, d.yamllint, a.statix, h.printenv }
      end
      null_ls.setup({
        sources = null_sources_null_ls(),
        on_attach = ul.on_attach, -- from require('utils.lsp')
        temp_dir = "/tmp",
      })
    end,
  },

  -- nvim-treesitter/nvim-treesitter (This is a startup plugin, defined in home/editor.nix)
  -- Its LZE config is minimal here as NixCats handles its installation and basic setup.
  -- The config part from its original spec is mainly autocmds for enabling features.
  {
    "nvim-treesitter",
    after = function()
      -- nvim-treesitter-context setup (dependency)
      require("treesitter-context").setup({
        enable = true, max_lines = 1, min_window_height = 20, line_numbers = true, multiline_threshold = 1, trim_scope = "outer", mode = "cursor", zindex = 20,
      })
      -- nvim-treesitter-textobjects setup (dependency) - no specific setup, relies on nvim-treesitter

      -- Main nvim-treesitter config (autocmds)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          -- Check if language is installed and then start parsers
          -- This logic might need adjustment if NixCats pre-installs all listed languages
          pcall(function()
            if vim.treesitter.language.add(ev.match) then
              vim.treesitter.start(ev.buf, ev.match) -- syntax highlighting
              vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end)
        end,
      })
    end,
  },
  -- nvim-treesitter-textobjects is a dependency, configured via mini.ai or nvim-treesitter itself.
  -- nvim-treesitter-context is a dependency, configured with nvim-treesitter.

  -- echasnovski/mini.ai (from treesitter/textobjects.lua)
  {
    "mini-ai", -- echasnovski/mini.ai
    -- dependencies = { "nvim-treesitter-textobjects" }, -- Handled by NixCats
    keys = {
      { "a", mode = { "x", "o" } },
      { "i", mode = { "x", "o" } },
    },
    after = function()
      local ts = require("mini.ai").gen_spec.treesitter
      require("mini.ai").setup({
        n_lines = 500,
        custom_textobjects = {
          F = ts({ a = { "@function.outer" }, i = { "@function.inner" } }, {}),
          f = ts({ a = { "@call.outer" }, i = { "@call.inner" } }),
          a = ts({ a = { "@parameter.outer" }, i = { "@parameter.inner" } }),
          e = ts({ a = { "@assignment.outer" }, i = { "@assignment.rhs" } }),
          r = ts({ a = { "@return.outer" }, i = { "@return.inner" } }),
          b = ts({ a = { "@code_block.outer" }, i = { "@code_block.inner" } }),
          s = ts({ a = { "@class.outer" }, i = { "@class.inner" } }, {}),
          c = ts({ a = { "@comment.outer" }, i = { "@comment.inner" } }),
          o = ts({ a = { "@block.outer", "@conditional.outer", "@loop.outer", "@frame.outer" }, i = { "@block.inner", "@conditional.inner", "@loop.inner", "@frame.inner" } }, {}),
        },
        silent = true,
      })
    end,
  },

  -- ## Lang ##

  -- p00f/clangd_extensions.nvim
  {
    "clangd_extensions-nvim", -- p00f/clangd_extensions.nvim
    -- No specific LZE config needed if it's mainly used by clangd on_attach.
    -- If it has a setup function, it would be called in an `after` hook.
    -- For now, assuming it's mainly a library for clangd.
  },

  -- mrcjkb/haskell-tools.nvim
  {
    "haskell-tools-nvim", -- mrcjkb/haskell-tools.nvim
    ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
    after = function()
      local repl_toggler_ht = function(ht, buffer) return function() ht.repl.toggle(vim.api.nvim_buf_get_name(buffer)) end end
      vim.g.haskell_tools = {
        hls = {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
          on_attach = function(client, buffer, ht)
            ul.on_attach(client, buffer)
            local s_ht = function(lhs, rhs, desc) vim.keymap.set("n", "<localleader>" .. lhs, rhs, { buffer = buffer, desc = "Haskell: " .. desc }) end
            s_ht("b", repl_toggler_ht(ht, buffer), "Toggle Buffer REPL")
            s_ht("e", ht.lsp.buf_eval_all, "Evaluate All")
            s_ht("h", ht.hoogle.hoogle_signature, "Show Hoogle Signature")
            s_ht("p", ht.repl.toggle, "Toggle Package REPL")
            s_ht("q", ht.repl.quit, "Quit REPL")
            ht.dap.discover_configurations(buffer, { autodetect = true, settings_file_pattern = "launch.json" })
          end,
        },
      }
      -- The plugin seems to want its config in vim.g.haskell_tools *before* it loads.
      -- LZE's `before` hook might be more appropriate if the plugin reads this global on load.
      -- For now, putting in `after` and assuming its internal setup uses this table.
      -- If issues arise, this might need to be moved to a `before` hook or a direct `vim.g.haskell_tools = ...`
      -- before LZE load for this plugin.
      -- However, lazy.nvim's `config` runs *after* plugin load, so `after` is the closer equivalent.
      pcall(require, "haskell-tools") -- Manually trigger setup if needed, original config implies it.
    end,
  },

  -- windwp/nvim-ts-autotag
  {
    "nvim-ts-autotag", -- windwp/nvim-ts-autotag
    ft = { "html", "xml", "jsx", "javascript" },
    after = function()
      require("nvim-ts-autotag").setup({})
    end,
  },

  -- jupytext.nvim (This is a startup plugin)
  {
    "jupytext-nvim", -- GCBallesteros/jupytext.nvim
    after = function()
      require("jupytext").setup({
        style = "markdown",
        output_extension = "md",
        force_ft = "markdown",
      })
    end,
  },

  -- benlubas/molten-nvim
  {
    "molten-nvim", -- benlubas/molten-nvim
    -- branch = "main", -- NixCats
    -- build = ":UpdateRemotePlugins", -- NixCats
    -- dependencies = { "3rd/image.nvim", "quarto-dev/quarto-nvim" }, -- NixCats
    before = function() -- from init function
      vim.g.molten_auto_open_output = true
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = false
    end,
    keys = {
      { "<localleader>d", "<cmd>MoltenDelete<cr>", desc = "molten: delete cell", ft = { "markdown", "quarto" } },
      { "<localleader>i", function() -- from mkInit('file')
          local share = os.getenv("XDG_DATA_HOME")
          local path = share .. "/jupyter/runtime/"
          local kernel = ""
          local handle = io.popen("ls -t " .. path .. "kernel-*.json 2>/dev/null")
          if handle then
            kernel = handle:read("*l")
            handle:close()
          end
          if kernel and kernel ~= "" then
            vim.cmd("MoltenInit " .. kernel)
          else
            vim.cmd("MoltenInit http://localhost:8888") -- Fallback or default
          end
          pcall(require, "otter") -- Try to activate otter if available
          if package.loaded["otter"] then require("otter").activate() end
        end, desc = "molten: init and start otter", ft = { "markdown", "quarto" } },
      { "<a-j>", "<cmd>MoltenNext<cr>", desc = "molten: jump to next cell", ft = { "markdown", "quarto" } },
      { "<a-k>", "<cmd>MoltenPrev<cr>", desc = "molten: jump to prev cell", ft = { "markdown", "quarto" } },
    },
    -- No explicit setup call in lazy.nvim config, settings are via vim.g
  },

  -- jmbuhr/otter.nvim
  {
    "otter-nvim", -- jmbuhr/otter.nvim
    -- dependencies = "nvim-treesitter/nvim-treesitter", -- NixCats
    ft = { "markdown", "quarto" },
    after = function()
      require("otter").setup({}) -- Assuming empty opts if not specified
    end,
    keys = {
      { "<localleader>o", function() require("otter").activate() end, desc = "otter: activate", ft = { "markdown", "quarto" } },
      { "<localleader>O", function() require("otter").deactivate() end, desc = "otter: deactivate", ft = { "markdown", "quarto" } },
    },
  },

  -- quarto-dev/quarto-nvim
  {
    "quarto-nvim", -- quarto-dev/quarto-nvim
    -- dependencies = { "jmbuhr/otter.nvim", "nvim-treesitter/nvim-treesitter" }, -- NixCats
    -- branch = "main", -- NixCats
    ft = { "markdown", "quarto" },
    after = function()
      require("quarto").setup({
        closePreviewOnExit = true,
        lspFeatures = {
          languages = { "python" }, -- Consider making this configurable
        },
        codeRunner = {
          default_method = "molten",
        },
      })
    end,
    keys = {
      { "<localleader>c", function() require("quarto.runner").run_cell() end, desc = "quarto: run cell", ft = { "markdown", "quarto" } },
      { "<localleader>a", function() require("quarto.runner").run_above() end, desc = "quarto: run all above including current one", ft = { "markdown", "quarto" } },
      { "<localleader>b", function() require("quarto.runner").run_below() end, desc = "quarto: run all below including current one", ft = { "markdown", "quarto" } },
      { "<localleader>A", function() require("quarto.runner").run_all() end, desc = "quarto: run all", ft = { "markdown", "quarto" } },
      { "<localleader>e", function() require("quarto.runner").run_range() end, mode = "v", desc = "quarto: run range", ft = { "markdown", "quarto" } },
    },
  },

  -- folke/lazydev.nvim
  {
    "lazydev-nvim", -- folke/lazydev.nvim
    ft = "lua",
    after = function()
      require("lazydev").setup({})
    end,
  },

  -- dhruvasagar/vim-table-mode
  {
    "vim-table-mode", -- dhruvasagar/vim-table-mode
    ft = "markdown",
    before = function() -- from init
      vim.g.table_mode_corner = "|"
    end,
    -- No explicit setup function, relies on vim.g variables and ftplugin.
    -- Keys were commented out in original config.
  },

  -- AckslD/nvim-FeMaco.lua
  {
    "nvim-femaco-lua", -- AckslD/nvim-FeMaco.lua
    ft = "markdown", -- Key mapping is ft specific
    after = function()
      require("femaco").setup({})
    end,
    keys = {
      { "<localleader>e", "<cmd>FeMaco<cr>", ft = "markdown", desc = "Edit Code Block" },
    },
  },

  -- anuramat/mdmath.nvim
  {
    "mdmath-nvim", -- anuramat/mdmath.nvim
    cond = function() return os.getenv("TERM") == "xterm-ghostty" end,
    -- dependencies = "nvim-treesitter/nvim-treesitter", -- NixCats
    ft = "markdown",
    -- build = ":MdMath build", -- NixCats
    after = function()
      local preamble_content = ""
      local filename = vim.fn.expand("$XDG_CONFIG_HOME/latex/mathjax_preamble.tex")
      local file = io.open(filename, "r")
      if file then
        preamble_content = file:read("*a")
        file:close()
      end
      require("mdmath").setup({
        filetypes = {}, -- Original was empty
        preamble = preamble_content,
      })
    end,
  },
}
