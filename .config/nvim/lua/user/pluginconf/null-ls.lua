local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local format_on_save = true

local f = null_ls.builtins.formatting
local d = null_ls.builtins.diagnostics

null_ls.setup({
	sources = {
		---- pyhton ----
		d.flake8,
		f.blue,

		---- webdev ----
		d.eslint_d,
		f.prettier.with({
			disabled_filetypes = { "json" }, -- its kinda bad, jsonls does it better
		}),
		d.stylelint,

		---- lua ----
		-- d.selene,
		f.stylua,

		---- php ----
		f.blade_formatter,
		-- f.phpcsfixer,
		d.php,

		---- shells ----
		f.fish_indent,
		d.fish,
		f.shellharden,
		d.shellcheck,
	},

	-- Format on save
	on_attach = function(client, bufnr)
		if format_on_save == true then
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = augroup,
					buffer = bufnr,
					callback = function()
						-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
						vim.lsp.buf.formatting_sync(nil, 1200)
					end,
				})
			end
		end
	end,
})