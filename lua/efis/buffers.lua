local M_buffers = {}

local Canvas = require("efis.canvas.canvas")
local Character = require("efis.canvas.character")
local Line = require("efis.canvas.line")



-- local function zero_pad_number(number_str, desired_length)
--     if #number_str >= desired_length then
--         return number_str
--     else
--         return zero_pad_number("0" .. number_str, desired_length)
--     end
-- end


function M_buffers:draw_buffer_counters(canvas, open_buffers_count, buffers_with_modif_count)
    -- draw at the right hand side of the screen.
    local symbols = {
        vertical_line = Character:new("│", "BufferDisplaySeparator"),
    }
    local open_buffers_str = tostring(open_buffers_count)
    local open_buffers_line_object = Line.create_from_str(open_buffers_str)
    local open_buffers_col = canvas.properties.width
    if open_buffers_count > 10 then
        open_buffers_col = open_buffers_col - 1
    end
    local buffers_with_modif_str = tostring(buffers_with_modif_count)
    local modif_hl = "Normal"
    if buffers_with_modif_count > 0 then
        modif_hl = "BufferDisplayModifiedCountDigitsNonZero"
    end
    local buffers_with_modif_line_object = Line.create_from_str(buffers_with_modif_str, modif_hl)
    canvas:write_char(Character:new("B", "BufferDisplayLabels"), 1, canvas.properties.width)
    canvas:write_line(open_buffers_line_object, 2, open_buffers_col)
    canvas:write_char(Character:new("M", "BufferDisplayLabels"), 3, canvas.properties.width)
    canvas:write_line(buffers_with_modif_line_object, 4, open_buffers_col)
    for row = 1, canvas.properties.height do
        canvas:write_char(symbols.vertical_line, row, canvas.properties.width - 2)
    end
    return canvas
end

local function get_truncated_buffer_name_object(buffer_name, max_length)
    if #buffer_name <= max_length then
        return {
            ["truncated_name"] = buffer_name,
            ["extension"] = "",
            ["was_truncated"] = false
        }
    end
    -- we truncate by removing characters before the extension '.ext'
    local extension_start_index = buffer_name:find("%.[^%.]*$")
    if extension_start_index == nil then
        -- if there is no extension, we just truncate from the start
        return {
            ["truncated_name"] = buffer_name:sub(1, max_length - 1),
            ["extension"] = "",
            ["was_truncated"] = true
        }
    end
    local extension = buffer_name:sub(extension_start_index)
    local name_without_extension = buffer_name:sub(1, extension_start_index - 1)
    local truncated_name_without_extension = name_without_extension:sub(1, max_length - #extension - 1)
    return {
        ["truncated_name"] = truncated_name_without_extension,
        ["extension"] = extension,
        ["was_truncated"] = true
    }
end

function M_buffers:draw_buffer_name(canvas, row, buffer_name, symbol, is_modified, hl)
    local symbols = {
        buffer_modified = Character:new("+", "BufferDisplaySymbolModified"),
        truncated_indicator = Character:new("…", hl),
    }
    if is_modified then
        canvas:write_char(symbols.buffer_modified, row, canvas.properties.width - 3)
    end
    local symbol_char = Character:new(symbol, "BufferDisplaySymbols")
    canvas:write_char(symbol_char, row, canvas.properties.width - 4)
    local truncated_buffer_name_object = get_truncated_buffer_name_object(buffer_name, canvas.properties.width - 6)
    local buffer_name_line_obj_len = #truncated_buffer_name_object.truncated_name + #truncated_buffer_name_object.extension
    if truncated_buffer_name_object.was_truncated then
        buffer_name_line_obj_len = buffer_name_line_obj_len + 1
    end
    local buffer_name_line_object = Line:new(buffer_name_line_obj_len)

    buffer_name_line_object:overlay(
        1,
        Line.create_from_str(truncated_buffer_name_object.truncated_name, hl)
    )
    local extension_offset = #truncated_buffer_name_object.truncated_name + 1
    if truncated_buffer_name_object.was_truncated then
        buffer_name_line_object:set_character_at(
            #truncated_buffer_name_object.truncated_name + 1,
            symbols.truncated_indicator
        )
        extension_offset = extension_offset + 1
    end
    buffer_name_line_object:overlay(
        extension_offset,
        Line.create_from_str(truncated_buffer_name_object.extension, "BufferDisplayCurrentBuffer")
    )

    canvas:write_line(
        buffer_name_line_object,
        row,
        canvas.properties.width - 5 - buffer_name_line_obj_len
    )
    return canvas
end

return M_buffers
