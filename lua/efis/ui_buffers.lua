-- a really terrible copy paste for now.

local api = vim.api
local buffers = require("efis.buffers")
local Canvas = require("efis.canvas.canvas")
local Character = require("efis.canvas.character")
local Line = require("efis.canvas.line")

local M_ui_buffers = {}

function M_ui_buffers:new()
    local instance = {
        active = false,
        autohide = {
            currently_autohidden = false,
            window_visibility_updated = false
        },
        buffer = -1,
        window = -1,
        augrp = -1,
        window_options = {
            row = -1,
            col = -1,
            width = -1,
            height = -1,
            anchor = "SE",
            border = { "", "", "", "", "", "", "", "" },
            zindex = 1,
            winblend = 100,
        }
    }
    setmetatable(instance, { __index = self })
    return instance
end

function M_ui_buffers:get_floating_window_options()
    -- TODO: read these default values from config later
    local lines = vim.api.nvim_buf_line_count(0)

    local default_anchor = "NW"
    local default_padding_x = 0
    local vim_window_width = vim.o.columns
    local vim_window_height = vim.o.lines - vim.o.cmdheight

    local width = 28 -- width needs to be ODD
    local height = 4


    local row = math.floor(vim_window_height - height - 3)
    local column = math.floor((vim_window_width - width))

    local new_window_options = {
        width = width,
        height = height,
        row = row,
        col = column,
        anchor = default_anchor,

    }
    return new_window_options
end

function M_ui_buffers:redraw()
    if not self.active then
        return
    end
    self:close_window()
    self:open_window()
    self:draw()
end

function M_ui_buffers:create_autocmds()
    self.augrp = api.nvim_create_augroup("efis_buffer_ui", { clear = true })
    -- TODO listen for when the buffer gains more lines and update the floating window dimensions accordingly,
    local refresh_events = {
        "CursorMoved",
        "TextChanged",
        "WinScrolled",
        "BufEnter",
        "BufLeave",
        "BufWritePost",
        "ModeChanged",
    }
    vim.api.nvim_create_autocmd(refresh_events, {
        callback = function()
            -- TODO config: autohide can be based on absolute cursor position OR
            -- on "character column" position
            -- which will hide the window if the user positions himself
            -- at the end of a wrapped line, even if the window is not actually
            -- in the way
            -- local cursor_pos = vim.fn.getcursorcharpos()
            -- local cursor_row = cursor_pos[2]
            -- local cursor_col = cursor_pos[3]
            -- local lnum = vim.fn.line('.')
            -- local col = vim.fn.col('.')
            -- local pos = vim.fn.screenpos(0, lnum, col)
            -- local cursor_row = pos.row
            -- local cursor_col = pos.col
            -- self.autohide.should_autohide = window_should_autohide(cursor_row, cursor_col, self.window_options)
            -- if self.autohide.should_autohide and not self.autohide.window_visibility_updated then
            --     self.autohide.window_visibility_updated = true
            --     self:close_window()
            -- elseif not self.autohide.should_autohide and self.autohide.window_visibility_updated then
            --     self.autohide.window_visibility_updated = false
            --     self:open_window()
            -- end
            self:draw()
        end,
        group = self.augrp,
    })
    -- persistent window that survives kills
    local exiting = false
    vim.api.nvim_create_autocmd({
        "TabEnter",
        "WinClosed"
    }, {
        callback = function(event)
            if self.active and not self.autohide.should_autohide and not exiting and (event.event == "TabEnter" or tonumber(event.match) == tonumber(self.window)) then
                exiting = true
                vim.schedule(function()
                    self:redraw()
                    exiting = false
                end)
            end
        end,
        group = self.augrp,
    })
    --TODO: this should be configurable
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            self:toggle()
            if self.active then
                self:draw()
            end
        end,
        group = self.augrp,
    })
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            --TODO cheap solution for now...
            self:toggle()
            self:toggle()
            if self.active then
                self:draw()
            end
        end,
        group = self.augrp,
    })
end

function M_ui_buffers:open_window()
    if self.buffer == -1 or not api.nvim_buf_is_valid(self.buffer) then
        self.buffer = api.nvim_create_buf(false, true)
    end
    if self.window == -1 or not api.nvim_win_is_valid(self.window) then
        local window_options = self:get_floating_window_options()
        self.window_options = window_options
        self.window = api.nvim_open_win(self.buffer, false, {
            relative = "editor",
            width = self.window_options.width,
            height = self.window_options.height,
            row = self.window_options.row,
            col = self.window_options.col,
            anchor = self.window_options.anchor,
            border = { "", "", "", "", "", "", "", "" },
            style = "minimal",
            focusable = false,
            noautocmd = true,
            winblend = self.window_options.winblend,
        })
        -- print("heading window opened with id", self.window)
    end
end

function M_ui_buffers:close_window()
    if self.buffer ~= -1 and api.nvim_buf_is_valid(self.buffer) then
        api.nvim_buf_delete(self.buffer, { force = true })
        self.buffer = -1
    end
    if self.window ~= -1 and api.nvim_win_is_valid(self.window) then
        api.nvim_win_close(self.window, true)
        self.window = -1
    end
end

function M_ui_buffers:toggle()
    if self.active then
        self:close_window()
    else
        self:open_window()
    end
    self.active = not self.active
end

function M_ui_buffers:get_lines_blank_canvas(current_line, total_lines)
    local lines = {}
    for i = 1, self.window_options.height do
        table.insert(lines, string.rep(" ", self.window_options.width))
    end
    return lines
end

function M_ui_buffers:draw()
    if not self.active or self.autohide.should_autohide then
        return
    end

    local cur_char = api.nvim_win_get_cursor(0)[2] + 1
    -- TODO: this is really bad, we should be able to get the total number of characters in the file without having to read the entire line every time we redraw the window
    local total_chars = #api.nvim_get_current_line()

    local mode = vim.api.nvim_get_mode().mode

    local buffer_info = vim.fn.getbufinfo({ buflisted = 1 })
    local buffer_count = vim.fn.len(buffer_info)
    local modified_buffer_count = 0
    for _, buffer in ipairs(buffer_info) do
        if buffer.changed == 1 then
            modified_buffer_count = modified_buffer_count + 1
        end
    end

    local function get_buf_info(cmd)
        -- Temporarily get the buffer number without switching focus
        local bufnr = vim.fn.bufnr(cmd)
        if bufnr == -1 then return { name = "[None]", is_modified = false } end
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
        if name == "" then
            name = "[No Name]"
        end

        return {
            name = name,
            is_modified = vim.bo[bufnr].modified,
        }
    end

    local current_bufnr = vim.api.nvim_get_current_buf()

    local current_idx = 0
    for i, info in ipairs(buffer_info) do
        if info.bufnr == current_bufnr then
            current_idx = i
            break
        end
    end

    local function get_neighbor_info(index)
        local count = #buffer_info
        if count == 0 then return { name = "[None]", is_modified = false } end

        local wrapped_index = (index - 1) % count + 1
        local target_buf = buffer_info[wrapped_index]
        local name = vim.fn.fnamemodify(target_buf.name, ":t")
        if name == "" then
            name = "[No Name]"
        end

        return {
            name = name,
            is_modified = target_buf.changed == 1
        }
    end

    local function get_current_buf_name()
        local name = vim.fn.expand("%:t")
        if name == "" then
            return "[No Name]"
        end
        return name
    end

    local buffer_infos = {
        ["current"] = {
            name = get_current_buf_name(),
            is_modified = vim.bo.modified,
        },
        ["alternate"] = get_buf_info("#"),
        ["previous"] = get_neighbor_info(current_idx - 1),
        ["next"] = get_neighbor_info(current_idx + 1)
    }



    local canvas = Canvas:new(self.window_options.width, self.window_options.height)

    canvas = buffers:draw_buffer_counters(canvas, buffer_count, modified_buffer_count)
    if buffer_count > 1 then
        canvas = buffers:draw_buffer_name(
            canvas,
            1,
            buffer_infos["previous"].name,
            "p",
            buffer_infos["previous"].is_modified,
            "BufferDisplayOtherBuffers"
        )
        canvas = buffers:draw_buffer_name(
            canvas,
            3,
            buffer_infos["next"].name,
            "n",
            buffer_infos["next"].is_modified,
            "BufferDisplayOtherBuffers"
        )
    end
    canvas = buffers:draw_buffer_name(
        canvas,
        2,
        buffer_infos["current"].name,
        "%",
        buffer_infos["current"].is_modified,
        "BufferDisplayCurrentBuffer"
    )
    canvas = buffers:draw_buffer_name(
        canvas,
        4,
        buffer_infos["alternate"].name,
        "#",
        buffer_infos["alternate"].is_modified,
        "BufferDisplayOtherBuffers"
    )

    -- canvas = heading:draw_file_name(canvas, vim.fn.expand("%:t"), is_file_modified)

    local current_line_graphic = canvas:convert_to_lines()
    local ns = api.nvim_create_namespace("efis_buffer_ns")
    api.nvim_buf_clear_namespace(self.buffer, ns, 0, -1)
    api.nvim_buf_set_lines(self.buffer, 0, -1, false, current_line_graphic)
    canvas:call_extmark_hl(self.buffer, ns)
end

return M_ui_buffers
