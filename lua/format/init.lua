local static = require("format.static")
local core = require("niuiic-core")
local job = require("format.job")
local utils = require("format.utils")
local uv = vim.loop

local setup = function(new_config)
	static.config = vim.tbl_deep_extend("force", static.config, new_config or {})
end

local cp_file = function(bufnr, file_path)
	local new_file_path = utils.parent_path(file_path) .. "/_" .. utils.file_name(file_path)
	utils.copy_buf_to_file(bufnr, file_path)
	return new_file_path
end

local use_on_job_success = function(temp_file, bufnr, changed_tick)
	return function()
		local valid, err = utils.buf_is_valid(bufnr, changed_tick)
		if not valid then
			vim.notify(err, vim.log.levels.ERROR, { title = "Format" })
			return false
		end

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		vim.schedule(function()
			local new_lines = vim.fn.readfile(temp_file)
			if static.config.update_same or not utils.lists_are_same(lines, new_lines) then
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
			end
			uv.fs_unlink(temp_file)
		end)

		return true
	end
end

local format = function()
	local changed_tick = vim.api.nvim_buf_get_changedtick(0)
	local bufnr = vim.api.nvim_win_get_buf(0)
	local filetype = vim.api.nvim_get_option_value("filetype", {
		buf = 0,
	})
	if not filetype then
		utils.on_not_support()
		return
	end
	local supported_filetypes = core.lua.table.keys(static.config.filetypes)
	if not core.lua.list.find(supported_filetypes, function(ft)
		return ft == filetype
	end) then
		utils.on_not_support()
		return
	end
	local file_path = vim.api.nvim_buf_get_name(0)
	local temp_file = cp_file(bufnr, file_path)
	-- local conf_list = static.config.filetypes[filetype](temp_file)
	-- local on_job_success = use_on_job_success(temp_file, bufnr, changed_tick)
	-- job(conf_list, on_job_success, function()
	-- 	uv.fs_unlink(temp_file)
	-- end)
end

return { setup = setup, format = format }