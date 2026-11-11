vim.g.mapleader = " "
vim.g.maplocalleader = " "

local homebrew_bin = "/opt/homebrew/bin"
local path = vim.env.PATH or ""
if vim.fn.isdirectory(homebrew_bin) == 1 and not path:find(homebrew_bin, 1, true) then
    vim.env.PATH = homebrew_bin .. ":" .. path
end

local function gh(repo, name)
    return { src = "https://github.com/" .. repo, name = name }
end

vim.pack.add({
    gh("junegunn/seoul256.vim", "seoul256"),
    gh("nvim-lua/plenary.nvim", "plenary"),
    gh("nvim-telescope/telescope.nvim", "telescope"),
    gh("mikavilpas/yazi.nvim", "yazi"),
    gh("lewis6991/gitsigns.nvim", "gitsigns"),
    gh("kdheepak/lazygit.nvim", "lazygit"),
    gh("sindrets/diffview.nvim", "diffview"),
    gh("echasnovski/mini.nvim", "mini"),
    gh("nvim-lualine/lualine.nvim", "lualine"),
    gh("akinsho/bufferline.nvim", "bufferline"),
    gh("nvim-treesitter/nvim-treesitter", "nvim-treesitter"),
    gh("stevearc/conform.nvim", "conform"),
    gh("mfussenegger/nvim-lint", "nvim-lint"),
    gh("MeanderingProgrammer/render-markdown.nvim", "render-markdown"),
    gh("3rd/image.nvim", "image"),
}, { confirm = false })

-- seoul256, darkest variant (233).
vim.opt.background = "dark"
vim.g.seoul256_background = 233
vim.cmd.colorscheme("seoul256")

require("config.plugins")
require("config.options")
require("config.keymaps")
require("config.lsp")
require("config.markdown")
