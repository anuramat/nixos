-- vim: fdl=1
local u = require('utils.helpers')

return {
        -- improves native commenting
        {
                'folke/ts-comments.nvim',
                opts = {},
                event = 'VeryLazy',
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
