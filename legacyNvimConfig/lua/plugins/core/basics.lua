-- vim: fdl=1
local u = require('utils.helpers')

return {
        -- surround
        {
                'kylechui/nvim-surround',
                opts = {
                        keymaps = {
                                insert = '<C-g>s',
                                insert_line = '<C-g>S',
                                normal = 's',
                                normal_cur = 'ss',
                                normal_line = 'S',
                                normal_cur_line = 'SS',
                                visual = 's',
                                visual_line = 'S',
                                delete = 'ds',
                                change = 'cs',
                                change_line = 'cS',
                        },
                },
                event = 'BufEnter',
        },
        -- improves native commenting
        {
                'folke/ts-comments.nvim',
                opts = {},
                event = 'VeryLazy',
        },
        -- oil.nvim - file manager
        {
                'stevearc/oil.nvim',
                lazy = false, -- so that it overrides `nvim <path>`
                opts = {
                        default_file_explorer = true,
                        columns = {
                                'icon',
                                'permissions',
                                'size',
                                'mtime',
                        },
                        delete_to_trash = true,
                        skip_confirm_for_simple_edits = true,
                        constrain_cursor = 'editable', -- name false editable
                        experimental_watch_for_changes = true,
                        view_options = {
                                -- Show files and directories that start with "."
                                show_hidden = true,
                                natural_order = true,
                                sort = {
                                        -- sort order can be "asc" or "desc"
                                        -- see :help oil-columns to see which columns are sortable
                                        { 'type', 'asc' },
                                        { 'name', 'asc' },
                                },
                        },
                },
                keys = {
                        { '<leader>o', '<cmd>Oil<cr>',   desc = 'File CWD' },
                        { '<leader>O', '<cmd>Oil .<cr>', desc = 'Open Parent Directory' },
                },
        },
        -- eunuch - rm, mv, etc
        {
                -- basic file commads for the current file (remove, rename, etc.)
                -- see also:
                -- chrisgrieser/nvim-genghis - drop in lua replacement with some bloat/improvements
                'tpope/vim-eunuch',
                event = 'VeryLazy',
        },
        -- undotree
        {
                'mbbill/undotree',
                cmd = {
                        'UndotreeHide',
                        'UndotreeShow',
                        'UndotreeFocus',
                        'UndotreeToggle',
                },
                keys = {
                        {
                                '<leader>u',
                                '<cmd>UndotreeToggle<cr>',
                                desc = 'Undotree',
                        },
                },
        },
        -- treesj - splits/joins code using TS
        {
                'Wansmer/treesj',
                enabled = true,
                opts = {
                        use_default_keymaps = false,
                        max_join_length = 500,
                },
                keys = {
                        {
                                '<leader>j',
                                function() require('treesj').toggle() end,
                                desc = 'TreeSJ: Split/Join a Treesitter node',
                        },
                },
        },
        -- flash.nvim - jump around
        {
                'folke/flash.nvim',
                event = 'VeryLazy',
                opts = {
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
                },
                keys = {
                        {
                                '<leader>r',
                                mode = 'n',
                                function() require('flash').jump() end,
                                desc = 'Jump',
                        },
                        {
                                'r',
                                mode = 'o',
                                function() require('flash').treesitter() end,
                                desc = 'TS node',
                        },
                },
        },
        -- wastebin -- (selfhosted) pastebin
        {
                'matze/wastebin.nvim',
                keys = {
                        { '<leader>w', '<cmd>WastePaste<cr>' },
                        { '<leader>w', [[<cmd>'<,'>WastePaste<cr>]], mode = 'v' },
                },
                opts = {
                        url = 'https://bin.ctrl.sn',
                        open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
                        ask = false,
                },
        },
}

-- annotation generation: <https://github.com/danymat/neogen>
-- indentation <https://github.com/lukas-reineke/indent-blankline.nvim>
-- tests 'nvim-neotest/neotest'
-- db stuff:
-- * <https://github.com/kristijanhusak/vim-dadbod-completion>
-- * <https://github.com/tpope/vim-dadbod>
-- * <https://github.com/kristijanhusak/vim-dadbod-ui>
