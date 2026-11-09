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
    gh("maxmx03/solarized.nvim", "solarized"),
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

-- Solarized Light.
vim.opt.background = "light"
vim.cmd.colorscheme("solarized")

require("config.plugins")
require("config.options")
require("config.keymaps")
require("config.lsp")
require("config.markdown")
