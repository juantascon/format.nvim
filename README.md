# format.nvim

An asynchronous, multitasking, and highly configurable formatting plugin.

## Dependencies

- [core.nvim](https://github.com/niuiic/core.nvim)

## Usage

Just call `require("format").format()`.

The plugin applies changes with lsp api, thus the buffer's folding, highlighting, etc, will not be affected. (Same effect as `null-ls.nvim`).

## Config

Default configuration here.

```lua
require("format").setup({
	allow_update_if_buf_changed = false,
	hooks = {
		---@type fun(code: integer, signal: integer) | nil
		on_success = function()
			vim.notify("Formatting Succeed", vim.log.levels.INFO, { title = "Format" })
		end,
		---@type fun(err: string | nil, data: string | nil) | nil
		on_err = function()
			vim.notify("Formatting Failed", vim.log.levels.ERROR, { title = "Format" })
		end,
		on_timeout = function()
			vim.notify("Formatting Timeout", vim.log.levels.ERROR, { title = "Format" })
		end,
	},
	filetypes = {
		-- see format configuration below
		lua = require("format.builtins.stylua"),
		rust = require("format.builtins.rustfmt"),
		javascript = require("format.builtins.prettier"),
		typescript = require("format.builtins.prettier"),
		-- ...
	},
})
```

Format configuration sample.

```lua
javascript = function(file_path)
	return {
		-- the first task
		{
			cmd = "prettier",
			args = {
				-- this plugin copies content of current buffer to a temporary file, and format this file, then write back to the buffer, thus, you need to make sure the formatter can write to the file
				"-w",
				file_path,
			},
			-- some formatters may output to stderr when formatted successfully, use this function to ignore these errors
			ignore_err = function(err, data)
				return err == nil and data == nil
			end,
		},
		-- the second task
		{
			cmd = "eslint",
			args = {
				"--fix",
				file_path,
			},
			-- just try to fix error with eslint, ignore the errors if it succeed or not
			ignore_err = function()
				return true
			end,
		},
	}
end
```

## How it works

1. Copy buffer content into a temp file.
2. Apply commands to this file.
3. Read file and write back to the buffer.
4. Remove the file.

> Why create a temp file?
> This plugin is designed to apply various commands to the buffer. Some commands, like `cargo fix`, cannot work if file not exists.
