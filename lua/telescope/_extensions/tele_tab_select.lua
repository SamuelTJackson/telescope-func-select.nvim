local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
    error('This plugins requires nvim-telescope/telescope.nvim')
end

local actions = require('telescope.actions')
local state = require('telescope.state')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local entry_display = require('telescope.pickers.entry_display')
local sorters = require('telescope.sorters')
local Previewer = require('telescope.previewers.previewer')
local icons = require('nvim-web-devicons')

local function goto_window(prompt_bufnr)
    actions.close(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    vim.api.nvim_set_current_tabpage(entry.tabnr)
end

local function get_filename(path)
    return path:match("([^/]+)$")
end

local function get_file_extension(path)
    return path:match("[^.]+$")
end

local function make_entry()
    local make_display = function(entry)

        local displayer = entry_display.create {
            separator = "",
            items = {{width = 10}, {width = 15}}
        }
        return displayer {
            {"Tab: " .. entry.tabnr}, {entry.windows_count .. " window(s)"}
        }
    end

    return function(entry)
        return {
            valid = true,
            path_start = entry.path_start,

            display = make_display,
            ordinal = "Tab: " .. entry.tabidx .. " : " .. entry.windows_count ..
                " window(s)",
            tabnr = entry.tabnr,
            windows_count = entry.windows_count,
            windows = entry.windows
        }
    end
end

local function preview_function()
    return function(_, entry, status)
        local pr_win = status.preview_win;
        local bufnr = vim.api.nvim_win_get_buf(pr_win)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, entry.windows)
    end
end

local function preview_title()
    return function()
        return "Files"
    end
end

local function list(opts)
    opts = opts or {}

    local tabnrs = vim.api.nvim_list_tabpages()
    local tabs = {}

    for tabidx, tabnr in ipairs(tabnrs) do
        local windownrs = vim.api.nvim_tabpage_list_wins(tabnr)
        local tab = {windows_count = 0, windows = {}}

        for windownr, windowid in ipairs(windownrs) do

            local bufnr = vim.api.nvim_win_get_buf(windowid)
            local buf_name = vim.api.nvim_buf_get_name(bufnr)

            if buf_name ~= "" then
                tab.tabnr = tabnr
                tab.tabidx = tabidx
                tab.windownr = windownr
                tab.windowid = windowid

                if not string.find(buf_name, "NvimTree") then
                    tab.windows_count = tab.windows_count + 1
                    local file_name = get_filename(buf_name)
                    local file_extension = get_file_extension(buf_name)
                    local file_icon = icons.get_icon(file_name, file_extension)
                    if file_icon then
                        table.insert(tab.windows, file_icon .. " " .. file_name)
                    else
                        table.insert(tab.windows, "  " .. file_name)
                    end
                end
            end
        end
        table.insert(tabs, tab)
    end

    opts.layout_strategy = "horizontal"
    opts.layout_config = {
        center = {preview_cutoff = 0},
        cursor = {preview_cutoff = 0},
        height = 0.2,
        horizontal = {preview_cutoff = 10, prompt_position = "bottom"},
        vertical = {preview_cutoff = 0},
        width = 0.8
    }
    pickers.new(opts, {
        prompt_title = 'Tabs',
        finder = finders.new_table {
            results = tabs,
            entry_maker = opts.entry_maker or make_entry()
        },
        previewer = Previewer:new{
            title = preview_title(),
            preview_fn = preview_function()
        },
        sorter = sorters.get_fzy_sorter(opts),
        attach_mappings = function(_, map)
            -- use our custom action to go the window id
            map('i', '<CR>', goto_window)
            map('n', '<CR>', goto_window)
            return true
        end
    }):find()
end

return telescope.register_extension {exports = {list = list}}
