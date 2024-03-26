local minimal_bookmarks = {
    list = nil,
    on_selected = nil,
    close_bookmarks = nil,
    win_id = nil,
    autocmd_bufleave_id = nil,
    autocmd_bufwritepre_id = nil,
}

local function join_paths(...)
    return table.concat({...}, package.config:sub(1,1))
end

local cache_dir = join_paths(vim.fn.stdpath('cache'), 'minimal_bookmarks')
vim.fn.mkdir(cache_dir, 'p')
local db_path = join_paths(cache_dir, 'database')

local function basename(file_path)
    local file_name = file_path:match("[^/\\]+$") -- Match the file name after the last '/' or '\'
    return file_name or file_path -- If no '/' or '\' found, return the whole path as filename
end

local function read_or_create_bookmarks_file(filename)
    local file = io.open(filename, "r")
    if not file then
        local new_file = io.open(filename, "w")
        if not new_file then
            return nil, "Error creating file: " .. filename
        end
        new_file:write('')
        new_file:close()
        return {}
    end

    local content = {}
    for line in file:lines() do
        local lnum, name, filepath, text = line:match('(%d+)|([^|]+)|([^|]+)|(.*)')

        if lnum and name and filepath and text then
            table.insert(content, {name = name, filepath = filepath, lnum = tonumber(lnum), text = text})
        else
            vim.api.nvim_err_writeln("Skipping invalid line in bookmarks file: " .. line)
        end
    end

    file:close()

    return content
end

local function get_current_line_trimmed()
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    local current_line = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]
    current_line = current_line:gsub("^%s*(.-)%s*$", "%1")
    current_line = current_line:sub(1, 80)
    return current_line
end

local function prompt_input(prompt, callback)
    vim.ui.input({ prompt = prompt}, callback)
end

local function apppend_line_to_end_of_file(file_path, line)
    local file = io.open(file_path, "a")
    if not file then
        error("Error opening file: " .. file_path)
    end
    file:write(line .. '\n')
    file:close()
end

local function insert_line_at_beginning_of_file(file_path, line)
    local content = ""
    local file = io.open(file_path, "r")
    if file then
        content = file:read("*a")
        file:close()
    end

    local new_file = io.open(file_path, "w")
    if not new_file then
        error("Error opening file: " .. file_path)
    end
    new_file:write(line .. '\n' .. content)
    new_file:close()
end

local function _add_current_line_to_bookmarks(append, name)
    if name == nil then
        vim.cmd([[redraw]])
        vim.api.nvim_err_writeln("No bookmark name provided.")
        return
    end

    -- Trim newlines and spaces from the input
    name = name:gsub("^%s*(.-)%s*$", "%1")

    if not name or name == '' then
        vim.cmd([[redraw]])
        vim.api.nvim_err_writeln("No bookmark name provided.")
        return
    end
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local file_path = vim.fn.expand("%:p")
    local text = get_current_line_trimmed()
    local item = current_line .. '|' .. name .. '|' .. file_path .. '|' .. text

    if append then
        apppend_line_to_end_of_file(db_path, item)
        vim.cmd([[redraw]])
        vim.api.nvim_echo({{ "Bookmark added: " .. name, "Normal" }}, true, {})
    else
        insert_line_at_beginning_of_file(db_path, item)
        vim.cmd([[redraw]])
        vim.api.nvim_echo({{ "Bookmark inserted: " .. name, "Normal" }}, true, {})
    end
end

local function add_current_line_to_bookmarks(append, bookmark_name)
    if bookmark_name then
        return _add_current_line_to_bookmarks(append, bookmark_name)
    else
        prompt_input(
            "Enter a name for the bookmark: ",
            function(name)
                return _add_current_line_to_bookmarks(append, name)
            end
        )
    end
end

local function add_current_line_to_end_of_bookmarks()
    add_current_line_to_bookmarks(true)
end

local function add_current_line_to_start_of_bookmarks()
    add_current_line_to_bookmarks(false)
end

local function is_buffer_file()
    local bufnr = vim.fn.bufnr('%')
    local file_path = vim.fn.expand("%:p")

    -- Check if buffer exists and if the file is readable
    if bufnr ~= -1 and file_path ~= '' then
        return true
    else
        return false
    end
end

local function add_bookmark(append, name)
    local current_window = vim.api.nvim_get_current_win()
    if current_window == minimal_bookmarks.win_id then
        vim.api.nvim_err_writeln("Cannot add bookmark from the bookmarks window.")
        return
    end
    if not is_buffer_file() then
        vim.api.nvim_err_writeln("Cannot add bookmark from a non-file buffer.")
        return
    end
    add_current_line_to_bookmarks(append, name)
end

function minimal_bookmarks.add_bookmark(fargs)
    if not fargs then
        add_bookmark(true, nil)
        return
    else
        local args = vim.split(fargs, " ", {trimempty = true})
        if #args > 1 then
            vim.api.nvim_err_writeln("Too many arguments provided.")
            return
        end
        local name = args[1]
        add_bookmark(true, name)
    end
end

function minimal_bookmarks.insert_bookmark(fargs)
    if not fargs then
        add_bookmark(false, nil)
        return
    else
        local args = vim.split(fargs, " ", {trimempty = true})
        if #args > 1 then
            vim.api.nvim_err_writeln("Too many arguments provided.")
            return
        end
        local name = args[1]
        add_bookmark(false, name)
    end
end

function minimal_bookmarks.hide_bookmarks()
    if minimal_bookmarks.close_bookmarks then
        minimal_bookmarks.close_bookmarks()
    end
end

function minimal_bookmarks.toggle_bookmarks()
    if minimal_bookmarks.win_id then
        minimal_bookmarks.hide_bookmarks()
    else
        minimal_bookmarks.show_bookmarks()
    end
end

function minimal_bookmarks.show_bookmarks()
    -- Check if the bookmarks window is already open
    if minimal_bookmarks.win_id then
        return
    end

    local content, err = read_or_create_bookmarks_file(db_path)
    if err then
        vim.api.nvim_err_writeln(err)
        return
    else
        if content == nil then -- avoid syntax error for possible nil
            content = {}
            return
        end
    end

    if #content == 0 then
        vim.api.nvim_err_writeln("No bookmarks in database. Use :MinimalBookmarksAdd to bookmark a line.")
        return
    end

    minimal_bookmarks.list = content

    -- Create a new scratch buffer for the floating window
    local buf = vim.api.nvim_create_buf(false, true)

    -- Calculate highest name legth for displaying the names in a nice column
    local highest_length = 0
    for _, item in ipairs(minimal_bookmarks.list) do
        if #item.name > highest_length then
            highest_length = #item.name
        end
    end

    -- Set the buffer content
    for i, item in ipairs(minimal_bookmarks.list) do
        if #item.name < highest_length then
            item.name = item.name .. string.rep(" ", highest_length - #item.name)
        end
        vim.api.nvim_buf_set_lines(buf, i-1, -1, true, {item.name .. "  " .. basename(item.filepath) .. ":" .. item.lnum .. "  " .. item.text})
    end

    local width = math.floor((vim.o.columns) * 0.8)
    local height = math.floor((vim.o.lines) * 0.7)
    local col = math.floor((vim.o.columns - width) / 2)
    -- Define the floating window options
    local opts = {
        title = "Bookmarks",
        relative = "editor",
        width = width,
        height = height,
        row = 2,
        col = col,
        style = "minimal",
        border = "single",
    }

    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')


    -- Set the function to be called when the user selects an item in the floating window
    minimal_bookmarks.on_selected = function()
        local selected_item = minimal_bookmarks.list[vim.api.nvim_win_get_cursor(minimal_bookmarks.win_id)[1]]
        minimal_bookmarks.close_bookmarks()
        if not selected_item then
            vim.api.nvim_err_writeln("Failed to find selected item in bookmarks list.")
            return
        end
        vim.cmd('e ' .. selected_item.filepath)
        vim.cmd('normal! ' .. selected_item.lnum .. 'G')
    end

    -- Set the function to close the floating window
    minimal_bookmarks.close_bookmarks = function()
        vim.api.nvim_del_autocmd(minimal_bookmarks.autocmd_bufleave_id)
        vim.api.nvim_del_autocmd(minimal_bookmarks.autocmd_bufwritepre_id)

        -- Close the floating window
        vim.api.nvim_win_close(minimal_bookmarks.win_id, true)

        -- Reset the global variables
        minimal_bookmarks.list = nil
        minimal_bookmarks.on_selected = nil
        minimal_bookmarks.close_bookmarks = nil
        minimal_bookmarks.win_id = nil
        minimal_bookmarks.autocmd_bufleave_id = nil
        minimal_bookmarks.autocmd_bufwritepre_id = nil
    end

    -- Key mappings for closing the floating window
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua require "minimal_bookmarks".close_bookmarks()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':lua require "minimal_bookmarks".close_bookmarks()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, 'n', '<C-c>', ':lua require "minimal_bookmarks".close_bookmarks()<CR>', {noremap = true, silent = true})

    -- Key mappings for selecting an item in the floating window
    vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', ':lua require "minimal_bookmarks".on_selected()<CR>', {noremap = true, silent = true})

    -- Close floating window when leaving the buffer, it doesn't make sense
    -- to keep it open if the user switches to another buffer
    minimal_bookmarks.autocmd_bufleave_id = vim.api.nvim_create_autocmd({"BufLeave"}, {
      pattern = {"<buffer=" .. buf .. ">"},
      callback = function()
        minimal_bookmarks.close_bookmarks()
      end
    })

    -- For an improved user experience, we give instructions when trying to modify the buffer
    minimal_bookmarks.autocmd_bufwritepre_id = vim.api.nvim_create_autocmd({"BufWritePre"}, {
      pattern = {"<buffer=" .. buf .. ">"},
      callback = function()
        vim.api.nvim_err_writeln("Cannot modify the bookmarks buffer. Use :MinimalBookmarksEdit to edit the bookmarks.")
      end
    })

    -- Create the floating window with the newly created buffer
    local win_id = vim.api.nvim_open_win(buf, true, opts)
    minimal_bookmarks.win_id = win_id
    vim.api.nvim_win_set_option(minimal_bookmarks.win_id, "wrap", false)
end

function minimal_bookmarks.edit_bookmarks()
    vim.api.nvim_echo({{ "Caution: " .. "this file is your bookmarks database, edit it carefully.", "WarningMsg" }}, true, {})
    vim.cmd('e ' .. db_path)
end


vim.cmd('command! MinimalBookmarksShow lua require "minimal_bookmarks".show_bookmarks()')
vim.cmd('command! MinimalBookmarksHide lua require "minimal_bookmarks".hide_bookmarks()')
vim.cmd('command! MinimalBookmarksToggle lua require "minimal_bookmarks".toggle_bookmarks()')
vim.cmd('command! MinimalBookmarksEdit lua require "minimal_bookmarks".edit_bookmarks()')
vim.cmd('command! -nargs=? MinimalBookmarksAdd lua require "minimal_bookmarks".add_bookmark(<f-args>)')
vim.cmd('command! -nargs=? MinimalBookmarksInsert lua require "minimal_bookmarks".insert_bookmark(<f-args>)')

return minimal_bookmarks
