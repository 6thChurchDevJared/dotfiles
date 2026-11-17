-- Shell scripting: LazyVim has no bash extra, so wire it up here.
-- bashls gives completion/hover and runs shellcheck diagnostics as you type;
-- shfmt (already in LazyVim's mason list) formats on save via conform.
-- Indent style matches bin/ and packages/: 2 spaces, indented case arms.
return {
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { bashls = {} } },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "shellcheck" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = { shfmt = { prepend_args = { "-i", "2", "-ci" } } },
    },
  },
}
