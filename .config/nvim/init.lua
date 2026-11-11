vim.g.mapleader = " "

vim.pack.add({
    { src = "https://github.com/junegunn/seoul256.vim", name = "seoul256" },
    { src = "https://github.com/nvim-lua/plenary.nvim", name = "plenary" },
    { src = "https://github.com/nvim-telescope/telescope.nvim", name = "telescope" },
    { src = "https://github.com/kdheepak/lazygit.nvim", name = "lazygit" },
    { src = "https://github.com/sindrets/diffview.nvim", name = "diffview" },
    { src = "https://github.com/echasnovski/mini.nvim", name = "mini" },
    { src = "https://github.com/neovim/nvim-lspconfig", name = "nvim-lspconfig" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", name = "nvim-treesitter" },
    { src = "https://github.com/stevearc/conform.nvim", name = "conform" },
    { src = "https://github.com/mfussenegger/nvim-lint", name = "nvim-lint" },
    { src = "https://github.com/3rd/image.nvim", name = "image" },
}, { confirm = false })

-- seoul256, darkest variant (233); this range also selects the dark style.
vim.g.seoul256_background = 233
vim.cmd.colorscheme("seoul256")

-- Options ---------------------------------------------------------------------

-- First, so later modules see its options (mini.diff picks 'number' style).
require("mini.basics").setup()
-- Give back Neovim defaults that mini.basics' mappings take over: LSP outline
-- (gO; ]<Space>/[<Space> add empty lines) and Vim's gp (plain p already uses
-- the system clipboard here). <C-s> stays mini.basics' save in every mode.
vim.keymap.set("n", "gO", vim.lsp.buf.document_symbol, { desc = "Document symbols" })
vim.keymap.del({ "n", "x" }, "gp")

-- Only options that differ from Neovim and mini.basics defaults.
vim.o.title = true -- expose the file name as the terminal window title (outside tmux)
vim.o.titlestring = "%t"
vim.o.relativenumber = true
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.clipboard = "unnamedplus"
vim.o.confirm = true
vim.o.updatetime = 250
vim.o.completeopt = "menu,menuone,noselect,popup"
vim.o.winborder = "rounded"
vim.o.pumborder = "rounded"
vim.o.timeoutlen = 300
vim.o.showcmd = false

-- 'autoread' only reloads when Neovim checks the file; check on these events too.
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
    group = vim.api.nvim_create_augroup("external-file-sync", { clear = true }),
    command = "checktime",
})

-- UI --------------------------------------------------------------------------

require("mini.icons").setup({ style = "ascii" })
MiniIcons.mock_nvim_web_devicons()
require("mini.statusline").setup({ use_icons = false })
local starter = require("mini.starter")
starter.setup({
    footer = "",
    content_hooks = {
        starter.gen_hook.adding_bullet("> "),
        starter.gen_hook.aligning("center", "center"),
    },
})
require("mini.notify").setup({
    -- pyright reports "Analyzing..." progress on every edit, which spams popups
    lsp_progress = { enable = false },
})

-- Editing ---------------------------------------------------------------------

-- mini.surround uses s-prefixed keys; stop the bare `s` from deleting a char.
vim.keymap.set({ "n", "x" }, "s", "<Nop>")
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.cursorword").setup()
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

-- Git -------------------------------------------------------------------------

require("mini.git").setup()
require("mini.diff").setup()
require("diffview").setup({
    icons = { folder_closed = "+", folder_open = "-" },
    signs = { fold_closed = "+", fold_open = "-", done = "x" },
})

-- The lazygit float opens and then settles to its final size inside tmux,
-- leaving stale cells from earlier frames. Repaint once it has settled.
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

-- Telescope -------------------------------------------------------------------

local telescope_actions = require("telescope.actions")
require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<C-j>"] = telescope_actions.move_selection_next,
                ["<C-k>"] = telescope_actions.move_selection_previous,
            },
        },
    },
})

-- Treesitter ------------------------------------------------------------------

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
-- Highlight with treesitter wherever a parser exists; others keep regex syntax.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
    end,
})

-- LSP -------------------------------------------------------------------------

-- Server configs come from nvim-lspconfig; enable those whose binary is installed.
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
        },
    },
})

-- Projects without their own `typescript` dependency fall back to the global one.
-- Resolved when ts_ls starts, so other filetypes don't pay for the npm call.
vim.lsp.config("ts_ls", {
    before_init = function(params)
        local npm_root = vim.trim(vim.fn.system({ "npm", "root", "--global" }))
        params.initializationOptions.tsserver = { fallbackPath = npm_root .. "/typescript/lib" }
    end,
})

local servers = {
    lua_ls = "lua-language-server",
    ts_ls = "typescript-language-server",
    intelephense = "intelephense",
    pyright = "pyright-langserver",
    ruff = "ruff",
    rust_analyzer = "rust-analyzer",
}
for server, binary in pairs(servers) do
    if vim.fn.executable(binary) == 1 then
        vim.lsp.enable(server)
    end
end

-- Show the item's extra detail (signature, module) after its name in the menu.
local function format_completion_item(item)
    local details = item.labelDetails or {}
    local abbr = item.label
    if (details.detail or "") ~= "" then
        abbr = abbr .. " " .. details.detail
    end
    local menu = details.description or item.detail or ""
    return { abbr = abbr .. " ", menu = menu == "" and menu or " " .. menu }
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-completion", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, {
                autotrigger = true,
                convert = format_completion_item,
            })
        end
    end,
})

-- Formatting and linting ------------------------------------------------------

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
        python = { "ruff_format" },
    },
})

local lint = require("lint")
lint.linters_by_ft = {
    javascript = { "eslint" },
    javascriptreact = { "eslint" },
    typescript = { "eslint" },
    typescriptreact = { "eslint" },
    markdown = { "markdownlint-cli2" },
    yaml = { "yamllint" },
    dockerfile = { "hadolint" },
}
-- Lint on save; linters that aren't installed are skipped silently.
vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("lint", { clear = true }),
    callback = function(args)
        lint.try_lint(nil, { bufnr = args.buf, ignore_errors = true })
    end,
})
vim.api.nvim_create_user_command("Lint", function()
    lint.try_lint()
end, { desc = "Lint current buffer" })

-- Markdown --------------------------------------------------------------------

require("image").setup()
vim.g.markdown_folding = 1

-- Add Portuguese only when its dictionary exists; otherwise Neovim prompts to
-- download it on every Markdown buffer.
local has_portuguese = #vim.api.nvim_get_runtime_file("spell/pt*.spl", false) > 0

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("markdown-workflow", { clear = true }),
    pattern = "markdown",
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.wrap = true
        vim.opt_local.showbreak = "  "
        vim.opt_local.conceallevel = 2
        vim.opt_local.spelllang = has_portuguese and "pt,en_us" or "en_us"
        vim.opt_local.spell = has_portuguese
        vim.opt_local.foldlevel = 99
        vim.opt_local.formatoptions:append("jro")
    end,
})

-- :Checkbox toggles "- [ ]" and "- [x]" on the current line or a range.
vim.api.nvim_create_user_command("Checkbox", function(opts)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    for i, line in ipairs(lines) do
        lines[i] = line:gsub("^(%s*[-+*%d.)]+%s+)%[([ xX])%]", function(prefix, state)
            return prefix .. (state == " " and "[x]" or "[ ]")
        end, 1)
    end
    vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, lines)
end, { range = true, desc = "Toggle Markdown checkboxes" })

-- Keymaps ---------------------------------------------------------------------

local telescope = require("telescope.builtin")

local function map(lhs, rhs, description)
    vim.keymap.set("n", lhs, rhs, { desc = description })
end

map("<leader>ff", telescope.find_files, "Files")
map("<leader>fc", function()
    telescope.find_files({ cwd = vim.fn.expand("%:p:h") })
end, "Files here")
map("<leader>fg", telescope.live_grep, "Search")
vim.keymap.set("x", "<leader>fg", telescope.grep_string, { desc = "Search selected text" })
map("<leader>fb", telescope.buffers, "Buffers")
map("<leader>fh", telescope.help_tags, "Help tags")
map("<leader>fm", function()
    require("conform").format({ async = true, lsp_format = "fallback" })
end, "Format buffer")

map("<leader>gg", "<cmd>LazyGit<cr>", "Git UI")
map("<leader>gd", function()
    if require("diffview.lib").get_current_view() then
        vim.cmd("DiffviewClose")
    else
        vim.cmd("DiffviewOpen")
    end
end, "Toggle diff view")
map("<leader>gh", "<cmd>DiffviewFileHistory %<cr>", "File history")
map("<leader>gH", "<cmd>DiffviewFileHistory<cr>", "Repo history")

map("<leader>bn", "<cmd>enew<cr>", "New buffer")
map("<leader>bd", "<cmd>bdelete<cr>", "Close buffer")

map("<leader>dd", function()
    telescope.diagnostics({ bufnr = 0 })
end, "Buffer diagnostics")
map("<leader>dw", telescope.diagnostics, "Workspace diagnostics")

map("<leader>l", "<cmd>Lint<cr>", "Lint")
map("gd", vim.lsp.buf.definition, "Go to definition")
map("<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
-- Built-in commenting (gc) on <leader>c in Visual mode.
vim.keymap.set("x", "<leader>c", "gc", { remap = true, desc = "Comment" })

-- Completion: <Tab>/<S-Tab> move through the menu (or jump snippet placeholders),
-- <CR> accepts the selected item, <C-Space> opens the menu by hand.
local function tab_key(forward)
    if vim.fn.pumvisible() == 1 then
        return forward and "<C-n>" or "<C-p>"
    end
    local direction = forward and 1 or -1
    if vim.snippet.active({ direction = direction }) then
        return string.format("<Cmd>lua vim.snippet.jump(%d)<CR>", direction)
    end
    return forward and "<Tab>" or "<S-Tab>"
end
vim.keymap.set({ "i", "s" }, "<Tab>", function()
    return tab_key(true)
end, { expr = true, desc = "Next completion or snippet placeholder" })
vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
    return tab_key(false)
end, { expr = true, desc = "Previous completion or snippet placeholder" })
-- MiniPairs.cr() returns ready-made keys, hence replace_keycodes = false.
vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected >= 0 then
        return vim.keycode("<C-y>")
    end
    return MiniPairs.cr() -- keeps mini.pairs' Enter between brackets
end, { expr = true, replace_keycodes = false, desc = "Accept completion" })
vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, { desc = "Trigger completion" })

local clue = require("mini.clue")
clue.setup({
    triggers = {
        { mode = { "n", "x" }, keys = "<Leader>" },
        { mode = { "n", "x" }, keys = "s" },
    },
    clues = {
        { mode = "n", keys = "<Leader>b", desc = "+Buffers" },
        { mode = "n", keys = "<Leader>d", desc = "+Diagnostics" },
        { mode = { "n", "x" }, keys = "<Leader>f", desc = "+Find" },
        { mode = "n", keys = "<Leader>g", desc = "+Git" },
    },
})
-- The initial buffer enters its window before this module is loaded.
clue.ensure_buf_triggers()
