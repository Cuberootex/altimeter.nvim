local M_heading = {}

local Canvas = require("efis.canvas.canvas")
local Character = require("efis.canvas.character")
local Line = require("efis.canvas.line")


local function zero_pad_number_to_nearest_odd_length(number_str)
    if #number_str % 2 == 1 and #number_str > 1 then
        return number_str
    else
        return zero_pad_number_to_nearest_odd_length("0" .. number_str)
    end
end

function M_heading:draw_heading_char_indicator(canvas, current_char, total_chars)
    local canvas_width = canvas.properties.width
    local canvas_height = canvas.properties.height

    local symbols = {
        downward_pointing_arrow = Character:new("🮮"),
    }

    if canvas_width % 2 ~= 1 then
        error("Canvas width must be an odd number to properly center the char indicator")
    end

    local current_char_str = tostring(current_char)
    local current_char_str_zero_padded =
        zero_pad_number_to_nearest_odd_length(current_char_str)

    local current_char_line_object =
        Line.create_from_str(current_char_str_zero_padded)

    local start_col_for_current_char =
        math.floor((canvas_width - current_char_line_object.length) / 2) + 1


    canvas:write_line(
        current_char_line_object,
        1,
        start_col_for_current_char
    )
    canvas:write_char(
        symbols.downward_pointing_arrow,
        2,
        math.floor(canvas_width / 2) + 1
    )
    
    M_heading:temporary_draw_total_char(canvas, current_char, total_chars, canvas_width - 2)

    return canvas
end

local function get_represented_char_number_on_tape(canvas_width, current_char, canvas_col)
    return current_char + canvas_col - math.ceil(canvas_width / 2)
end


local function write_tape_horizontal_line(char_num_represented, canvas_col, total_chars, canvas)
    -- there should be an option in config
    -- whether to display the analog tape beyond the
    -- total number of characters in the line or not
    local symbols = {
        horizontal_line = Character:new("─"),
        -- horizontal_line_not_reached = Character:new("·"),
        horizontal_line_not_reached = Character:new(" "),
        start_of_tape = Character:new("┠"),
        end_of_tape = Character:new("┨"),
        start_and_end_of_tape = Character:new("┃"), -- you can never see this char because of the diamond symbol
        mark_type_1 = Character:new("┴"),
        mark_type_2 = Character:new("┸"),
        mark_type_1_past_limit = Character:new("╧"),
        mark_type_2_past_limit = Character:new("╩"),
        horizontal_line_past_limit = Character:new("═"),
        mark_char_limit = Character:new("╬"),
    }
    -- TODO Config
    local char_limit = 100
    local symbol = symbols.horizontal_line
    if char_num_represented < 1 then
        return
    end
    -- YandereDev engaged??????????
    if char_num_represented == char_limit then
        symbol = symbols.mark_char_limit
    elseif char_num_represented > total_chars then
        symbol = symbols.horizontal_line_not_reached
    elseif char_num_represented == 1 and char_num_represented == total_chars then
        symbol = symbols.start_and_end_of_tape
    elseif char_num_represented % 10 == 0 then
        symbol = symbols.mark_type_2
    elseif char_num_represented % 5 == 0 then
        symbol = symbols.mark_type_1
    end
    if char_num_represented > char_limit then
        symbol = symbols.horizontal_line_past_limit
        if char_num_represented % 10 == 0 then
            symbol = symbols.mark_type_2_past_limit
        elseif char_num_represented % 5 == 0 then
            symbol = symbols.mark_type_1_past_limit
        end
    end
    if char_num_represented == 1 then
        symbol = symbols.start_of_tape
    elseif char_num_represented == total_chars then
        symbol = symbols.end_of_tape
    end
    canvas:write_char(
        symbol,
        2,
        canvas_col
    )
end


local function get_char_number_line_graphic(char_number, digits_character_object_table)
    local char_number_str = tostring(char_number)
    local char_number_str_zero_padded =
        zero_pad_number_to_nearest_odd_length(char_number_str)

    local line_object = Line:new(#char_number_str_zero_padded)
    for i = 1, #char_number_str_zero_padded do
        local digit = char_number_str_zero_padded:sub(i, i)
        line_object.characters[i] = digits_character_object_table[digit]
    end
    return line_object
end

local function write_individual_scale_number(
    canvas,
    represented_char_number,
    total_chars,
    canvas_col
)
    -- TODO: better return statements
    if represented_char_number <= 1 then
        return
    end
    -- TODO config: can be toggled
    if represented_char_number > total_chars then
        return
    end
    -- TODO Config
    if represented_char_number % 10 ~= 0 then
        return
    end
    local digits_character_object_table = {
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
    }
    local line_object = 
        get_char_number_line_graphic(represented_char_number, digits_character_object_table)
    canvas:write_line(
        line_object,
        1,
        canvas_col - math.floor(line_object.length / 2)
    )

end

function M_heading:draw_analog_scale(canvas, current_char, total_chars)
    local canvas_width = canvas.properties.width
    local canvas_height = canvas.properties.height


    local tape_start_col_on_canvas = 3
    local tape_end_col_on_canvas = canvas_width - 2

    for col = tape_start_col_on_canvas, tape_end_col_on_canvas do
        local represented_char_number = 
            get_represented_char_number_on_tape(canvas_width, current_char, col)
        write_individual_scale_number(canvas, represented_char_number, total_chars, col)
    end
    return canvas
end

function M_heading:draw_analog_tape(canvas, current_char, total_chars)
    local canvas_width = canvas.properties.width
    local canvas_height = canvas.properties.height

    local tape_start_col_on_canvas = 3
    local tape_end_col_on_canvas = canvas_width - 2

    local symbols = {
        tape_left_limit = Character:new("┋"),
        tape_right_limit = Character:new("┋")
    }

    canvas:write_char(symbols.tape_left_limit, 2, tape_start_col_on_canvas - 1)
    canvas:write_char(symbols.tape_right_limit, 2, tape_end_col_on_canvas + 1)

    for col = tape_start_col_on_canvas, tape_end_col_on_canvas do
        local represented_char_number = 
            get_represented_char_number_on_tape(canvas_width, current_char, col)
        write_tape_horizontal_line(represented_char_number, col, total_chars, canvas)
    end
    return canvas
end

-- watch this become permanent
function M_heading:temporary_draw_total_char(canvas, current_char, total_chars, tape_end_col_on_canvas)

    -- local superscripts_character_object_table = {
    --     ["0"] = Character:new("⁰"),
    --     ["1"] = Character:new("¹"),
    --     ["2"] = Character:new("²"),
    --     ["3"] = Character:new("³"),
    --     ["4"] = Character:new("⁴"),
    --     ["5"] = Character:new("⁵"),
    --     ["6"] = Character:new("⁶"),
    --     ["7"] = Character:new("⁷"),
    --     ["8"] = Character:new("⁸"),
    --     ["9"] = Character:new("⁹"),
    -- }

    local digits_character_object_table = {
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
    }

    -- draw total_chars in the middle, on row 3
    local line_object = get_char_number_line_graphic(total_chars, digits_character_object_table)
    canvas:write_line(
        line_object,
        3,
        tape_end_col_on_canvas - math.floor(line_object.length / 2)
    )

    local modifier_right_arrowhead = Character:new("›")

    local represented_char_at_end_of_tape = get_represented_char_number_on_tape(canvas.properties.width, current_char, tape_end_col_on_canvas)
    if represented_char_at_end_of_tape < total_chars then
        canvas:write_char(
            modifier_right_arrowhead,
            3,
            tape_end_col_on_canvas + 2
        )
    end

end


function M_heading:draw_mode_indicator(canvas)
    local mode = vim.api.nvim_get_mode()
    local mode_letter = string.upper(string.sub(mode.mode, 1, 1))
    local mode_character_object = Character:new(mode_letter)
    canvas:write_char(
        mode_character_object,
        2,
        canvas.properties.width
    )
    if mode.blocking then
        local block_character_object = Character:new("B")
        canvas:write_char(
            block_character_object,
            1,
            canvas.properties.width
        )
    end
    return canvas
end


return M_heading
