local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
    error('This plugins requires nvim-telescope/telescope.nvim')
end

local vim = vim
local api = vim.api
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local entry_display = require('telescope.pickers.entry_display')
local sorters = require('telescope.sorters')

local function goto_line(prompt_bufnr)
    actions.close(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    vim.api.nvim_win_set_cursor(0, {entry.line_number, 0})
end

local function make_entry()
    local make_display = function(entry)

        local displayer = entry_display.create {separator = "", items = {{width = 250}}}

        return displayer {{"" .. entry.name}}
    end

    return function(entry)
        return {valid = true, display = make_display, ordinal = entry.name, line_number = entry.line_number, name = entry.name}
    end
end

local function list(opts)
    opts = opts or {}
    local buff_number = api.nvim_get_current_buf()

    local buffer = vim.api.nvim_buf_get_lines(buff_number, 0, -1, false)
    local functions = {}

    for i, line in ipairs(buffer) do
        if line:sub(1, 4) == "func" then
            table.insert(functions, {name = line:sub(1, -3), line_number = i})
        end
    end

    opts.layout_strategy = "horizontal"
    opts.layout_config = {
        center = {preview_cutoff = 0},
        cursor = {preview_cutoff = 0},
        height = 0.8,
        horizontal = {preview_cutoff = 10, prompt_position = "bottom"},
        vertical = {preview_cutoff = 0},
        width = 0.8
    }
    pickers.new(opts, {
        prompt_title = 'Functions',
        finder = finders.new_table {results = functions, entry_maker = opts.entry_maker or make_entry()},
        sorter = sorters.get_fzy_sorter(opts),
        attach_mappings = function(_, map)
            map('i', '<CR>', goto_line)
            map('n', '<CR>', goto_line)
            return true
        end
    }):find()
end

return telescope.register_extension {exports = {list = list}}
