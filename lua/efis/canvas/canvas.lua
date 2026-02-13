local M_canvas = {}
local Character = require("efis.canvas.character")

function M_canvas:new(width, height)
   local instance = {
        contents = {},
        properties = {
            width = width,
            height = height,
        }
    }
    for _ = 1, height do
        local char_table = {}
        for _ = 1, width do
            table.insert(char_table, Character:new(nil))
        end
        table.insert(instance.contents, char_table)
    end
    setmetatable(instance, { __index = self })
    return instance
end

function M_canvas:is_position_valid(row, col)
    return row >= 1 and row <= self.properties.height and col >= 1 and col <= self.properties.width
end

function M_canvas:get_character_at(row, col)
    if not self:is_position_valid(row, col) then
        error("Position out of bounds: (" .. row .. ", " .. col .. ")")
    end
    return self.contents[row][col]
end

function M_canvas:write_char(char, row, col)
    if row < 1 or row > self.properties.height or col < 1 or col > self.properties.width then
        error("Position out of bounds: (" .. row .. ", " .. col .. ")")
    end
    self.contents[row][col] = char
end

function M_canvas:write_line(line, row, col)
    local line_length = line.length
    for i = 1, line_length do
        local col_pos = col + i - 1
        if not self:is_position_valid(row, col_pos) then
            goto continue
        end
        local char = line:get_character_at(i)
        self:write_char(char, row, col_pos)
        ::continue::
    end
end

function M_canvas:convert_to_lines(debug_mode)
    local lines = {}
    for i, line in ipairs(self.contents) do
        local line_str = ""
        if debug_mode then
            line_str = i .. "|"
        end
        for _, char in ipairs(line) do
            local display_char = char and char:get_str_for_display(debug_mode) or " "
            line_str = line_str .. display_char
        end
        table.insert(lines, line_str)
    end
    return lines
end

function M_canvas:display_canvas(debug_mode)
    local lines = self:convert_to_lines(debug_mode)
    for _, line in ipairs(lines) do
        print(line)
    end
end

return M_canvas
