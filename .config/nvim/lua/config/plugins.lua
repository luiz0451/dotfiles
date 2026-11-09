vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_floating_window_winblend = 0

-- The float opens and then settles to its final size inside tmux, leaving
-- stale cells from earlier frames. Repaint the screen once it has settled.
vim.api.nvim_create_autocmd({ "TermEnter", "WinResized", "VimResized" }, {
    group = vim.api.nvim_create_augroup("lazygit_redraw", { clear = true }),
    callback = function(args)
        if vim.bo[args.buf].filetype ~= "lazygit" and vim.bo.filetype ~= "lazygit" then
            return
        end
        vim.defer_fn(function()
            vim.cmd("redraw!")
        end, 50)
    end,
})

-- Files are browsed with Yazi in a float, so the explorer never becomes a
-- listed buffer and keeps the same keys as Yazi in the shell.
require("yazi").setup({
    floating_window_scaling_factor = 0.9,
})

local telescope_actions = require("telescope.actions")

require("telescope").setup({
    defaults = {
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
            width = 0.9,
            height = 0.85,
            prompt_position = "top",
            preview_width = 0.55,
        },
        path_display = { "truncate" },
        dynamic_preview_title = true,
        results_title = " Results ",
        prompt_title = " Search ",
        preview_title = " Preview ",
        winblend = 0,
        mappings = {
            i = {
                ["<C-j>"] = telescope_actions.move_selection_next,
                ["<C-k>"] = telescope_actions.move_selection_previous,
            },
            n = {
                ["j"] = telescope_actions.move_selection_next,
                ["k"] = telescope_actions.move_selection_previous,
            },
        },
    },
})
require("gitsigns").setup({
    signcolumn = false,
    numhl = true,
    linehl = false,
})

-- Side-by-side diff tabs.
require("diffview").setup({
    enhanced_diff_hl = true,
    view = {
        merge_tool = { layout = "diff3_mixed" },
    },
})

vim.keymap.set({ "n", "x" }, "s", "<Nop>")
require("mini.surround").setup({
    search_method = "cover_or_next",
})
require("mini.pairs").setup({
    mappings = {
        ["<"] = { action = "open", pair = "<>" },
        [">"] = { action = "close", pair = "<>" },
    },
})
require("mini.cursorword").setup({})

require("mini.comment").setup({
    mappings = {
        comment_visual = "<leader>c",
    },
})
require("mini.move").setup({
    mappings = {
        left = "",
        right = "",
        down = "<A-j>",
        up = "<A-k>",
        line_left = "",
        line_right = "",
        line_down = "<A-j>",
        line_up = "<A-k>",
    },
})

vim.opt.termguicolors = true
require("mini.basics").setup()
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("lualine").setup({
    options = {
        theme = "auto",
        section_separators = "",
        component_separators = "",
        globalstatus = false,
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = {
            "branch",
            "diff",
            "diagnostics",
        },
        lualine_c = { "filename" },
        lualine_x = {
            "filetype",
            {
                "lsp_status",
                ignore_lsp = { "GitHub Copilot" },
            },
            "selectioncount",
        },
        lualine_y = { "location" },
        lualine_z = { "progress" },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "filetype", "location" },
        lualine_y = {},
        lualine_z = {},
    },
    extensions = { "quickfix", "man" },
})
local starter = require("mini.starter")
starter.setup({
    footer = "",
    content_hooks = {
        starter.gen_hook.adding_bullet(),
        starter.gen_hook.aligning("center", "center"),
    },
})
local bufferline = require("bufferline")
bufferline.setup({
    options = {
        mode = "buffers",
        style_preset = bufferline.style_preset.no_italic,
        tab_size = 0,
        show_tab_indicators = true,
    },
})
require("mini.notify").setup({
    content = {
        format = function(notif)
            return notif.msg
        end,
    },
    window = {
        config = { title = "" },
    },
    -- pyright reports "Analyzing..." progress on every edit, which spams popups
    lsp_progress = { enable = false },
})

local treesitter_filetypes = {
    "bash",
    "css",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "lua",
    "markdown",
    "php",
    "python",
    "rust",
    "toml",
    "tsx",
    "typescript",
    "typescriptreact",
    "vim",
    "vimdoc",
    "yaml",
}

require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})
-- Also read by install.sh to build every parser before the first real launch.
vim.g.treesitter_parsers = {
    "bash",
    "css",
    "html",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "php",
    "phpdoc",
    "python",
    "rust",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
}
require("nvim-treesitter").install(vim.g.treesitter_parsers)
require("render-markdown").setup({
    render_modes = { "n", "c", "t" },
    latex = {
        enabled = false,
    },
    completions = {
        lsp = {
            enabled = true,
        },
    },
    heading = {
        sign = false,
        position = "inline",
        width = "block",
        -- Plain '#'s instead of the Nerd Font numbered circles.
        icons = function(context)
            return string.rep("#", context.level) .. " "
        end,
    },
    code = {
        sign = false,
        width = "block",
    },
    link = {
        enabled = false,
    },
    win_options = {
        conceallevel = {
            default = 2,
            rendered = 3,
        },
        concealcursor = {
            default = "",
            rendered = "",
        },
    },
})
local treesitter_group = vim.api.nvim_create_augroup("treesitter-start", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = treesitter_group,
    pattern = treesitter_filetypes,
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
    end,
})
require("conform").setup({
    formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        markdown = { "prettier" },
        yaml = { "prettier" },
        php = { "pint" },
        python = function(bufnr)
            if require("conform").get_formatter_info("ruff_format", bufnr).available then
                return { "ruff_format" }
            end
            return {}
        end,
    },
})
require("image").setup({
    backend = "kitty",
    processor = "magick_cli",
    integrations = {
        markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { "markdown", "vimwiki" },
        },
    },
    max_width_window_percentage = 50,
    max_height_window_percentage = 50,
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif", "*.ico" },
})

local lint = require("lint")

local markdown_linters = {}
if vim.fn.executable("markdownlint-cli2") == 1 then
    markdown_linters = { "markdownlint-cli2" }
elseif vim.fn.executable("markdownlint") == 1 then
    markdown_linters = { "markdownlint" }
end
local yaml_linters = {}
if vim.fn.executable("yamllint") == 1 then
    yaml_linters = { "yamllint" }
end

local dockerfile_linters = {}
if vim.fn.executable("hadolint") == 1 then
    dockerfile_linters = { "hadolint" }
end

lint.linters_by_ft = {
    javascript = { "eslint" },
    javascriptreact = { "eslint" },
    typescript = { "eslint" },
    typescriptreact = { "eslint" },
    markdown = markdown_linters,
    yaml = yaml_linters,
    dockerfile = dockerfile_linters,
}

local group = vim.api.nvim_create_augroup("lint", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(args)
        lint.try_lint(nil, { bufnr = args.buf })
    end,
})

vim.api.nvim_create_user_command("MarkdownLint", function()
    if #markdown_linters == 0 then
        vim.notify("No Markdown linter found; install markdownlint-cli2", vim.log.levels.WARN)
        return
    end

    lint.try_lint(nil, { bufnr = 0 })
end, { desc = "Lint current Markdown buffer" })

vim.api.nvim_create_user_command("Lint", function()
    lint.try_lint(nil, { bufnr = 0 })
end, { desc = "Lint current buffer" })

local clue = require("mini.clue")

clue.setup({
    triggers = {
        { mode = { "n", "x" }, keys = "<Leader>" },
    },
    clues = {
        { mode = "n", keys = "<Leader>b", desc = "+Buffers" },
        { mode = "n", keys = "<Leader>c", desc = "+Code" },
        { mode = "n", keys = "<Leader>d", desc = "+Diagnostics" },
        { mode = "n", keys = "<Leader>f", desc = "+Find" },
        { mode = "n", keys = "<Leader>g", desc = "+Git" },
        { mode = "n", keys = "<Leader>m", desc = "+Markdown" },
        { mode = "n", keys = "<Leader>r", desc = "+Config" },
        { mode = "x", keys = "<Leader>f", desc = "+Find" },
        { mode = "x", keys = "<Leader>m", desc = "+Markdown" },
    },
    window = {
        delay = 200,
        config = { width = "auto" },
    },
})
-- The initial buffer enters its window before this module is loaded.
clue.ensure_buf_triggers()
