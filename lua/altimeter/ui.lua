local api = vim.api
local Canvas = require("altimeter.canvas.canvas")
local Character = require("altimeter.canvas.character")
local Line = require("altimeter.canvas.line")

local M_ui = {}

function M_ui:new()
    local instance = {
        active = false,
        buffer = -1,
        window = -1,
        augrp = -1,
        window_options = {
            row = -1,
            col = -1,
            width = -1,
            height = -1,
            anchor = "NE",
        }
    }
    setmetatable(instance, { __index = self })
    return instance
end

-- Evaluates how wide the floating window should be based on the number of lines in the file, and the number of digits in that number
function M_ui:calculate_floating_window_width(number_of_lines)
    local digits = math.max(2, math.floor(math.log10(number_of_lines)) + 1)
    return digits + 5
end

function M_ui:get_floating_window_dimensions()
    -- TODO: read these default values from config later
    local lines = vim.api.nvim_buf_line_count(0)
    local default_width = self:calculate_floating_window_width(lines)
    local lines_above_and_below_indicator = 8
    local default_anchor = "NE"
    local default_padding_x = 1
    local vim_window_width = vim.o.columns
    local vim_window_height = vim.o.lines - vim.o.cmdheight

    local width = math.min(default_width, vim_window_width)
    local computed_height = lines_above_and_below_indicator * 2 + 1 -- +1 for the line the indicator is on
    local height = math.min(computed_height, vim_window_height)

    local row = vim_window_height - height * 2

    local column = vim_window_width - default_padding_x -- cause anchor at NE by default
    if default_anchor == "NW" then
        column = default_padding_x
    end

    print("window dimensions: ", width, height, "on:", row, column)

    local new_window_options = {
        width = width,
        height = height,
        row = row,
        col = column,
    }
    return new_window_options
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
    }
    vim.api.nvim_create_autocmd(refresh_events, {
        callback = function()
            self:draw()
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
            print("resizing window")
        end,
        group = self.augrp,
    })
end

function M_ui:open_window()
    if self.buffer == -1 or not api.nvim_buf_is_valid(self.buffer) then
        self.buffer = api.nvim_create_buf(false, true)
    end
    if self.window == -1 or not api.nvim_win_is_valid(self.window) then
        local window_options = self:get_floating_window_dimensions()
        self.window_options = window_options
        self.window = api.nvim_open_win(self.buffer, false, {
            relative = "editor",
            width = self.window_options.width,
            height = self.window_options.height,
            row = self.window_options.row,
            col = self.window_options.col,
            anchor = self.window_options.anchor,
            border = "single",
            style = "minimal",
            focusable = false,
            noautocmd = true,
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

local function draw_altimeter_line_indicator(canvas, current_line, total_lines)
    -- Draw the current line number in the middle of the floating window, and show the extra digit for the preceding and following line number.
    -- Example graphic:
    --    ┌─┐
    --   ┌┘4│
    --  ◁│ 5│
    --   └┐6│
    --    └─┘

    local canvas_width = canvas.properties.width
    local canvas_height = canvas.properties.height
    local borders = {
        top_left = Character:new("┌"),
        top_right = Character:new("┐"),
        bottom_left = Character:new("└"),
        bottom_right = Character:new("┘"),
        vertical = Character:new("│"),
        horizontal = Character:new("─"),
    }
    local symbols = {
        arrow_pointing_left = Character:new("◁"),
    }

    local start_row_offset = math.floor((canvas_height - 5) / 2) + 1

    local analog_window_width = math.max(2, math.floor(math.log10(total_lines)) + 1)

    local top_line = Line:new(3)
    top_line:set_character_at(1, borders.top_left)
    top_line:set_character_at(2, borders.horizontal)
    top_line:set_character_at(3, borders.top_right)
    canvas:write_line(top_line, start_row_offset, canvas_width - 2)

    local second_line_horizontal_char_count = analog_window_width - 2
    local second_line = Line:new(4 + second_line_horizontal_char_count)
    for i = 1, second_line_horizontal_char_count do
        second_line:set_character_at(1 + i, borders.horizontal)
    end
    second_line:set_character_at(1, borders.top_left)
    second_line:set_character_at(2 + second_line_horizontal_char_count, borders.bottom_right)
    second_line:set_character_at(
        3 + second_line_horizontal_char_count,
        Character:new(tostring((current_line - 1) % 10))
    )
    second_line:set_character_at(4 + second_line_horizontal_char_count, borders.vertical)
    canvas:write_line(
        second_line,
        start_row_offset + 1,
        canvas_width - second_line.length + 1
    )

    local middle_line_left_graphic = Line:new(2)
    middle_line_left_graphic:set_character_at(1, symbols.arrow_pointing_left)
    middle_line_left_graphic:set_character_at(2, borders.vertical)
    local line_object_line_count = Line.create_from_str(tostring(current_line))

    local spaces_needed_to_right_align_line_count =
        analog_window_width - line_object_line_count.length
    local middle_graphic_length =
        2 -- middle_line_left_graphic length
        + spaces_needed_to_right_align_line_count
        + line_object_line_count.length
        + 1 -- to account for the vertical border on the right side
    local start_col_for_middle_graphic = canvas_width - middle_graphic_length + 1

    canvas:write_line(
        middle_line_left_graphic,
        start_row_offset + 2,
        start_col_for_middle_graphic
    )
    canvas:write_line(
        line_object_line_count,
        start_row_offset + 2,
        start_col_for_middle_graphic + 2 + spaces_needed_to_right_align_line_count
    )
    canvas:write_char(
        borders.vertical,
        start_row_offset + 2,
        start_col_for_middle_graphic + middle_graphic_length - 1
    )

    local fourth_line_horizontal_char_count = second_line_horizontal_char_count
    local fourth_line = Line:new(4 + fourth_line_horizontal_char_count)
    for i = 1, fourth_line_horizontal_char_count do
        fourth_line:set_character_at(1 + i, borders.horizontal)
    end
    fourth_line:set_character_at(1, borders.bottom_left)
    fourth_line:set_character_at(2 + fourth_line_horizontal_char_count, borders.top_right)
    fourth_line:set_character_at(
        3 + fourth_line_horizontal_char_count,
        Character:new(tostring((current_line + 1) % 10))
    )
    fourth_line:set_character_at(4 + fourth_line_horizontal_char_count, borders.vertical)
    canvas:write_line(
        fourth_line,
        start_row_offset + 3,
        canvas_width - fourth_line.length + 1
    )

    local bottom_line = Line:new(3)
    bottom_line:set_character_at(1, borders.bottom_left)
    bottom_line:set_character_at(2, borders.horizontal)
    bottom_line:set_character_at(3, borders.bottom_right)
    canvas:write_line(bottom_line, start_row_offset + 4, canvas_width - 2)

    return canvas
end

function M_ui:get_lines_graphic_altimeter_line_indicator(current_line, total_lines)
    -- Draw the current line number in the middle of the floating window, and show the extra digit for the preceding and following line number.
    -- Example graphic:
    --    ┌─┐
    --   ┌┘4│
    -- ├◁│ 5│
    --   └┐6│
    --    └─┘

    local window_width = self.window_options.width
    local window_height = self.window_options.height
    local lines = {}
    local borders = {
        top_left = "┌",
        top_right = "┐",
        bottom_left = "└",
        bottom_right = "┘",
        vertical = "│",
        horizontal = "─",
    }
    local symbols = {
        arrow_pointing_left = "◁",
    }

    -- considering that the graphic is always 5 lines high,
    -- we therefore need to insert (window_height - 5) / 2 blank lines before and after the graphic to center it vertically in the window
    local blank_lines_before = math.floor((window_height - 5) / 2)
    local blank_lines_after = math.ceil((window_height - 5) / 2)
    for i = 1, blank_lines_before do
        table.insert(lines, "")
    end

    local analog_window_width = math.max(2, math.floor(math.log10(total_lines)) + 1)
    local char_length_current_line_number = math.floor(math.log10(current_line)) + 1

    local top_line =
        string.rep(" ", window_width - 3) ..
        borders.top_left ..
        borders.horizontal ..
        borders.top_right

    -- 2nd top line
    local second_line_horizontal_char_count = analog_window_width - 2
    local second_line =
        string.rep(" ", window_width - (4 + second_line_horizontal_char_count)) ..
        borders.top_left ..
        string.rep(borders.horizontal, second_line_horizontal_char_count) ..
        borders.bottom_right ..
        tostring((current_line - 1) % 10) ..
        borders.vertical

    -- one space, left arrow, vertical, current line (right aligned), vertical
    local right_aligned_current_line =
        string.rep(" ", analog_window_width - char_length_current_line_number) ..
        tostring(current_line)
    local middle_line_graphic =
        symbols.arrow_pointing_left ..
        borders.vertical ..
        right_aligned_current_line ..
        borders.vertical

    -- have to compute length manually because of utf8 chars
    local middle_line_graphic_length = 2 + #right_aligned_current_line


    local middle_line =
        string.rep(" ", window_width - middle_line_graphic_length - 1) ..
        middle_line_graphic

    -- graphic always 4 chars wide so need blank spaces.
    -- graphic: bottom left, top right, ((line number % 10) + 1) % 10), vertical

    local fourth_line_horizontal_char_count = second_line_horizontal_char_count

    local fourth_line =
        string.rep(" ", window_width - (4 + fourth_line_horizontal_char_count)) ..
        borders.bottom_left ..
        string.rep(borders.horizontal, fourth_line_horizontal_char_count) ..
        borders.top_right ..
        tostring((current_line + 1) % 10) ..
        borders.vertical

    local fifth_line =
        string.rep(" ", window_width - 3) ..
        borders.bottom_left ..
        borders.horizontal ..
        borders.bottom_right

    table.insert(lines, top_line)
    table.insert(lines, second_line)
    table.insert(lines, middle_line)
    table.insert(lines, fourth_line)
    table.insert(lines, fifth_line)

    for i = 1, blank_lines_after do
        table.insert(lines, "")
    end

    return lines
end

function M_ui:draw()
    if not self.active then
        return
    end

    local line = api.nvim_win_get_cursor(0)[1]
    local total_lines = api.nvim_buf_line_count(0)

    local canvas = Canvas:new(self.window_options.width, self.window_options.height)
    canvas = draw_altimeter_line_indicator(canvas, line, total_lines)
    local current_line_graphic = canvas:convert_to_lines()


    local ns = api.nvim_create_namespace("altimeter")
    api.nvim_buf_clear_namespace(self.buffer, ns, 0, -1)
    api.nvim_buf_set_lines(self.buffer, 0, -1, false, current_line_graphic)
end

return M_ui
