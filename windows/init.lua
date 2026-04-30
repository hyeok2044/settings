-- Fix broken Lua module search path (Windows env/Lua interference)
-- Append all runtimepath/lua folders to package.path so require() can find plugin modules.
-- do
--   local sep = package.config:sub(1, 1)
--   local function add_lua_paths(p)
--     local lua_dir = p .. sep .. "lua"
--     package.path = package.path
--       .. ";" .. lua_dir .. sep .. "?.lua"
--       .. ";" .. lua_dir .. sep .. "?" .. sep .. "init.lua"
--   end
-- 
--   for _, p in ipairs(vim.api.nvim_list_runtime_paths()) do
--     add_lua_paths(p)
--   end
-- end
-- 1. Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 2. 플러그인 설정
require("lazy").setup({
  spec = {
    -- 테마
    {
      "vague-theme/vague.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        require("vague").setup({})
        vim.cmd.colorscheme("vague")
      end,
    },
    { "nvim-tree/nvim-web-devicons", lazy = true },

    -- Neo-tree (파일 탐색기)
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
      keys = { { "<leader>e", "<cmd>Neotree toggle left<cr>" } },
    },

    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
      },
      config = function()
        require("mason").setup()

        require("mason-lspconfig").setup({
          ensure_installed = { "omnisharp", "clangd", "intelephense" }, -- PHP 추가
        })

        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- 1) 서버별 설정 등록 (vim.lsp.config)
        vim.lsp.config("omnisharp", {
          capabilities = capabilities,
        })

        vim.lsp.config("clangd", {
          capabilities = capabilities,
        })

        vim.lsp.config("intelephense", {
          capabilities = capabilities,
        })

        -- 2) 서버 활성화 (vim.lsp.enable)
        vim.lsp.enable({ "omnisharp", "clangd", "intelephense" })

        -- LSP 키맵
        vim.keymap.set("n", "gd", vim.lsp.buf.definition)
        vim.keymap.set("n", "gr", vim.lsp.buf.references)
        vim.keymap.set("n", "K", vim.lsp.buf.hover)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
      end,
    },


    -- 자동완성
    {
      "hrsh7th/nvim-cmp",
      dependencies = { "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "hrsh7th/cmp-nvim-lsp" },
      config = function()
        local cmp = require("cmp")
        cmp.setup({
          snippet = {
            expand = function(args)
              require("luasnip").lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping.select_next_item(),
            ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          }),
          sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "luasnip" } }),
        })
      end,
    },

    {
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.config").setup({
          ensure_installed = { "php" },
          highlight = { enable = true },
          indent = { enable = true },
        })
      end,
    },
    {
      "akinsho/toggleterm.nvim",
      version = "*",
      config = function()
        require("toggleterm").setup({
          -- 1. 사용할 단축키 설정
          open_mapping = [[<C-\>]], 
          -- 2. 터미널이 뜨는 방식 ('float'가 깔끔합니다)
          direction = 'float', 
          -- 3. 터미널이 열릴 때 자동으로 입력 모드로 전환
          start_in_insert = true,
          -- 4. 플로팅 창 스타일 (선택 사항)
          float_opts = {
            border = "curved", -- 테두리 모양
          },
        })

        -- 터미널 모드에서 탈출하거나 이동하기 편한 키맵 설정
        function _G.set_terminal_keymaps()
          local opts = {buffer = 0}
          -- Esc 대신 jk로 터미널 노멀 모드 전환 (원하는 대로 수정 가능)
          vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
          vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
          -- 터미널 안에서 창 이동
          vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
          vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
          vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
          vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        end

        -- 터미널이 열릴 때만 위 키맵 적용
        vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
      end,
    },
    { 'RaafatTurki/hex.nvim', config = true },
    {
        "tpope/vim-dadbod",
        dependencies = {
          "kristijanhusak/vim-dadbod-ui",
          "kristijanhusak/vim-dadbod-completion",
        },
        config = function()
          -- vim-dadbod-ui 관련 설정
          vim.g.db_ui_save_location = "~/.config/nvim/db_ui" -- UI 설정 저장 위치
          vim.g.db_ui_show_help = 0                         -- 도움말 숨기기 (깔끔하게)
          vim.g.db_ui_win_width = 30                        -- 왼쪽 사이드바 너비

          -- 자동완성 연동 (sql 파일에서 작성 시 자동완성 활성화)
          vim.api.nvim_create_autocmd("FileType", {
            pattern = { "sql", "mysql", "plsql" },
            callback = function()
              require("cmp").setup.buffer({ sources = { { name = "vim-dadbod-completion" } } })
            end,
          })
        end,
        keys = {
          { "<leader>du", "<cmd>DBUIToggle<cr>", desc = "DB UI 토글" },
          { "<leader>df", "<cmd>DBUIFindBuffer<cr>", desc = "현재 버퍼 DB 찾기" },
          { "<leader>dr", "<cmd>DBUIRenameBuffer<cr>", desc = "DB 버퍼 이름 변경" },
          { "<leader>dl", "<cmd>DBUILastQueryInfo<cr>", desc = "마지막 쿼리 정보" },
        },
      },
      {
        'nvim-telescope/telescope.nvim', version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- optional but recommended
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        }
          
      }
  },
  -- autofold
})

-- 3. 유니티 자동 CD 설정
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname == "" or bufname:match("neo%-tree") then
      return
    end
    local root = vim.fs.find({ "*.sln", "Assets" }, { path = vim.fn.fnamemodify(bufname, ":p:h"), upward = true })[1]
    if root then
      vim.cmd("cd " .. vim.fn.fnamemodify(root, ":h"))
    end
  end,
})

-- 4. 기본 옵션
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.clipboard:append("unnamedplus")


-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldenable = true

-- Full path → 클립보드
vim.keymap.set('n', '<leader>fp', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path)
  print('Copied full path: ' .. path)
end, { desc = 'Copy full path' })

-- Relative path → 클립보드
vim.keymap.set('n', '<leader>rp', function()
  local path = vim.fn.expand('%')
  vim.fn.setreg('+', path)
  print('Copied relative path: ' .. path)
end, { desc = 'Copy relative path' })

-- File name only → 클립보드
vim.keymap.set('n', '<leader>fn', function()
  local name = vim.fn.expand('%:t')
  vim.fn.setreg('+', name)
  print('Copied file name: ' .. name)
end, { desc = 'Copy file name' })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
