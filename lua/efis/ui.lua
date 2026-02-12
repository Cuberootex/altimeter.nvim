local api = vim.api
local altimeter = require("efis.altimeter")
local Canvas = require("efis.canvas.canvas")
local Character = require("efis.canvas.character")
local Line = require("efis.canvas.line")

local M_ui = {}

function M_ui:new()
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
            anchor = "NE",
            border = { "·", "─", "·", "", "·", "─", "·", "" },
            zindex = 1,
            winblend = 100,
        }
    }
    setmetatable(instance, { __index = self })
    return instance
end

-- Evaluates how wide the floating window should be based on the number of lines in the file, and the number of digits in that number
function M_ui:calculate_floating_window_width(number_of_lines)
    local digits = math.max(2, math.floor(math.log10(number_of_lines)) + 1)
    return digits + 4
end

function M_ui:get_floating_window_options()
    -- TODO: read these default values from config later
    local lines = vim.api.nvim_buf_line_count(0)
    local default_width = self:calculate_floating_window_width(lines)
    local lines_above_and_below_indicator = 8
    -- we add 2 extra lines above and belowe on top of 
    -- the 'lines_above_and_below_indicator' count
    -- to draw a border and to display extra text$
    -- hence the +4 on computed_height
    local default_anchor = "NE"
    local default_padding_x = 0
    local vim_window_width = vim.o.columns
    local vim_window_height = vim.o.lines - vim.o.cmdheight

    local width = math.min(default_width, vim_window_width)
    local computed_height = 4 + lines_above_and_below_indicator * 2 + 1 -- +1 for the line the indicator is on
    local height = math.min(computed_height, vim_window_height - 5)

    local row = math.floor(vim_window_height - height - 5)

    local column = vim_window_width - default_padding_x -- cause anchor at NE by default

    local new_window_options = {
        width = width,
        height = height,
        row = row,
        col = column,
        anchor = default_anchor,

    }
    return new_window_options
end

function M_ui:redraw()
    if not self.active then
        return
    end
    self:close_window()
    self:open_window()
    self:draw()
end


local function window_should_autohide(cursor_row, cursor_col, window_options)
    -- hide window if cursor approaches the area where the window is, to prevent it from being in the way when editing near the edges of the screen
    local padding_x_perc = 0.2 -- TODO extract to config
    local padding_x = math.ceil(vim.o.columns * padding_x_perc)
    if window_options.anchor == "NE" then
        return cursor_col >= window_options.col - window_options.width - padding_x
    elseif window_options.anchor == "NW" then
        return cursor_col <= window_options.col + window_options.width + padding_x
    else 
        vim.print("wtf?", window_options)
        return false
    end
end

function M_ui:create_autocmds()
    self.augrp = api.nvim_create_augroup("altimeter_ui", { clear = true })
    -- TODO listen for when the buffer gains more lines and update the floating window dimensions accordingly,
    local refresh_events = {
        "CursorMoved",
        "CursorMovedI",
        "TextChanged",
        "TextChangedI",
        "WinScrolled",
        "ModeChanged",
    }
    vim.api.nvim_create_autocmd(refresh_events, {
        callback = function()
            -- TODO config: autohide can be based on absolute cursor position OR 
            -- on "character column" position 
            -- which will hide the window if the user positions himself
            -- at the end of a wrapped line, even if the window is not actually 
            -- in the way
            local cursor_pos = vim.fn.getcursorcharpos()
            local cursor_row = cursor_pos[2]
            local cursor_col = cursor_pos[3]
            -- local lnum = vim.fn.line('.')
            -- local col = vim.fn.col('.')
            -- local pos = vim.fn.screenpos(0, lnum, col)
            -- local cursor_row = pos.row
            -- local cursor_col = pos.col
            self.autohide.should_autohide = window_should_autohide(cursor_row, cursor_col, self.window_options)
            if self.autohide.should_autohide and not self.autohide.window_visibility_updated then
                self.autohide.window_visibility_updated = true
                self:close_window()
            elseif not self.autohide.should_autohide and self.autohide.window_visibility_updated then
                self.autohide.window_visibility_updated = false
                self:open_window()
            end
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

function M_ui:open_window()
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
    end
end

function M_ui:close_window()
    if self.buffer ~= -1 and api.nvim_buf_is_valid(self.buffer) then
        api.nvim_buf_delete(self.buffer, { force = true })
        self.buffer = -1
    end
    if self.window ~= -1 and api.nvim_win_is_valid(self.window) then
        api.nvim_win_close(self.window, true)
        self.window = -1
    end
end

function M_ui:toggle()
    if self.active then
        self:close_window()
    else
        self:open_window()
    end
    self.active = not self.active
end

function M_ui:get_lines_blank_canvas(current_line, total_lines)
    local lines = {}
    for i = 1, self.window_options.height do
        table.insert(lines, string.rep(" ", self.window_options.width))
    end
    return lines
end

function M_ui:draw()
    if not self.active or self.autohide.should_autohide then
        return
    end

    local line = api.nvim_win_get_cursor(0)[1]
    local total_lines = api.nvim_buf_line_count(0)

    local canvas = Canvas:new(self.window_options.width, self.window_options.height)
    canvas = altimeter:draw_top_and_bottom_borders(canvas)
    canvas = altimeter:draw_altimeter_analog_tape(canvas, line, total_lines)
    canvas = altimeter:draw_altimeter_line_indicator(canvas, line, total_lines)
    local current_line_graphic = canvas:convert_to_lines()


    local ns = api.nvim_create_namespace("altimeter")
    api.nvim_buf_clear_namespace(self.buffer, ns, 0, -1)
    api.nvim_buf_set_lines(self.buffer, 0, -1, false, current_line_graphic)
end

return M_ui
