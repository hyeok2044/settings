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
  },
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
