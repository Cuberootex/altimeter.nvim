local M_altimeter = {}

local Canvas = require("efis.canvas.canvas")
local Character = require("efis.canvas.character")
local Line = require("efis.canvas.line")

-- hmm this function is not pure since it modifies the canvas passed in
function M_altimeter:draw_altimeter_analog_tape(canvas, current_line, total_lines)
    -- for every line of the canvas, determine which line number it corresponds to on the tape
    -- (we know the middle of the canvas corresponds to the current line number
    -- first column of the canvas will be used to draw a vertical line
    -- then we mark the positions % 5 and % 10
    local canvas_width = canvas.properties.width
    local canvas_height = canvas.properties.height

    local symbols = {
        mark_top_vertical = Character:new("Ⓣ"),
        mark_top_line = Character:new("═"),
        vertical_tape_line = Character:new("│"),
        mark_5_vertical = Character:new("├"),
        mark_5_line = Character:new(nil),
        mark_10_vertical = Character:new("├"),
        mark_10_line = Character:new("─"),
        mark_bottom_vertical = Character:new("🅑"),
        mark_bottom_line = Character:new("═"),
    }

    local file_progression_symbols = {
        mark_10_perc = Character:new("①"),
        mark_20_perc = Character:new("②"),
        mark_30_perc = Character:new("③"),
        mark_40_perc = Character:new("④"),
        mark_50_perc = Character:new("⑤"),
        mark_60_perc = Character:new("⑥"),
        mark_70_perc = Character:new("⑦"),
        mark_80_perc = Character:new("⑧"),
        mark_90_perc = Character:new("⑨"),
    }

    local function write_tape_vertical(line_number_represented, canvas_line)
        local symbol_to_write = symbols.vertical_tape_line
        if line_number_represented == 1 then
            symbol_to_write = symbols.mark_top_vertical
        elseif line_number_represented == total_lines then
            symbol_to_write = symbols.mark_bottom_vertical
        elseif line_number_represented % 10 == 0 then
            symbol_to_write = symbols.mark_10_vertical
        elseif line_number_represented % 5 == 0 then
            symbol_to_write = symbols.mark_5_vertical
        end
        canvas:write_char(symbol_to_write, canvas_line, 1)
    end

    local function write_tape_vertical_percentage(line_number_represented, canvas_line)
        if total_lines < canvas_height then
            return
        end
        if line_number_represented == 1 or line_number_represented == total_lines then
            return
        end
        local percentage_prev_line = math.floor(((line_number_represented - 1) / total_lines) * 100)
        local percentage_current_line = math.floor((line_number_represented / total_lines) * 100)
        local percentage_next_line = math.floor(((line_number_represented + 1) / total_lines) * 100)
        if (percentage_prev_line / 10) % 10 == (percentage_current_line / 10) % 10 then
            return
        end
        if percentage_current_line % 10 == 0 then
            local symbol_to_write = file_progression_symbols["mark_" .. percentage_current_line .. "_perc"]
            canvas:write_char(symbol_to_write, canvas_line, 1)
        end
    end

    local function write_tape_lines(line_number_represented, canvas_line)
        local symbol_to_write = nil
        if line_number_represented == 1 then
            symbol_to_write = symbols.mark_top_line
        elseif line_number_represented == total_lines then
            symbol_to_write = symbols.mark_bottom_line
        elseif line_number_represented % 10 == 0 then
            symbol_to_write = symbols.mark_10_line
        elseif line_number_represented % 5 == 0 then
            symbol_to_write = symbols.mark_5_line
        end
        local length_line_number_str = math.floor(math.log10(line_number_represented)) + 1
        if not symbol_to_write then
            return
        end
        local length_marker_line = canvas_width - length_line_number_str - 3
        if length_marker_line < 1 then
            return
        end
        local line_to_write = Line:new(length_marker_line)
        for i = 1, length_marker_line do
            line_to_write:set_character_at(i, symbol_to_write)
        end
        canvas:write_line(line_to_write, canvas_line, 2)
    end

    local function write_line_number(line_number_represented, canvas_line)
        local line_number_str = tostring(line_number_represented)
        local line_number_char_object = Line.create_from_str(line_number_str)
        canvas:write_line(
            line_number_char_object,
            canvas_line,
            canvas_width - line_number_char_object.length
        )
    end

    -- should be an option to display percentage either before or after the line number,
    -- or to not display it at all
    local function write_file_progress_percentage(line_number_represented, canvas_line)
        if total_lines < canvas_height then
            return
        end
        if line_number_represented <= 1 or line_number_represented >= total_lines - 1 then
            return
        end
        -- ₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉﹪
        local disable_percentage_symbol = true
        local subscript_digits = {
            ["0"] = Character:new("₀"),
            ["1"] = Character:new("₁"),
            ["2"] = Character:new("₂"),
            ["3"] = Character:new("₃"),
            ["4"] = Character:new("₄"),
            ["5"] = Character:new("₅"),
            ["6"] = Character:new("₆"),
            ["7"] = Character:new("₇"),
            ["8"] = Character:new("₈"),
            ["9"] = Character:new("₉"),
            ["%"] = Character:new("%"),
        }
        local percentage = math.floor((line_number_represented / total_lines) * 100)
        local percentage_str = tostring(percentage) .. "%"
        if disable_percentage_symbol then
            percentage_str = percentage_str:sub(1, #percentage_str - 1)
        end
        local percentage_line = Line:new(#percentage_str)
        for i = 1, #percentage_str do
            local char = subscript_digits[percentage_str:sub(i, i)]
            percentage_line:set_character_at(i, char)
        end
        canvas:write_line(
            percentage_line,
            canvas_line,
            2
        )
    end

    for canvas_line = 1, canvas_height do
        local line_number_represented = current_line - math.ceil(canvas_height / 2) + canvas_line
        if line_number_represented < 1 or line_number_represented > total_lines then
            goto continue
        end
        write_tape_vertical(line_number_represented, canvas_line)
        write_tape_vertical_percentage(line_number_represented, canvas_line)
        write_tape_lines(line_number_represented, canvas_line)
        if line_number_represented % 5 == 0 or line_number_represented == 1 or line_number_represented == total_lines then
            write_file_progress_percentage(line_number_represented - 1, canvas_line - 1)
            write_line_number(line_number_represented, canvas_line)
        end
        ::continue::
    end

    return canvas
end

function M_altimeter:draw_altimeter_line_indicator(canvas, current_line, total_lines)
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

    local opaque_right_align_space = Line:new(spaces_needed_to_right_align_line_count)
    for i = 1, spaces_needed_to_right_align_line_count do
        opaque_right_align_space:set_character_at(i, Character:new(" "))
    end

    canvas:write_line(
        middle_line_left_graphic,
        start_row_offset + 2,
        start_col_for_middle_graphic
    )
    canvas:write_line(
        opaque_right_align_space,
        start_row_offset + 2,
        start_col_for_middle_graphic + 2
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

return M_altimeter
