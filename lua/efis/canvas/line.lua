local M_line = {}
local Character = require("efis.canvas.character")

function M_line:new(length, hl_group)
    local instance = {
        characters = {},
        length = length
    }
    for i = 1, length do
        table.insert(instance.characters, Character:new(nil, hl_group))
    end
    setmetatable(instance, { __index = self })
    return instance
end

function M_line:get_character_at(index)
    return self.characters[index]
end

function M_line:set_character_at(index, char)
    self.characters[index] = char
end

function M_line:get_str_for_display()
    local str = ""
    for _, char in ipairs(self.characters) do
        str = str .. char:get_str_for_display()
    end
    return str
end

function M_line.create_from_str(str, hl_group)
    local hl = hl_group or "Normal"
    local line = M_line:new(#str)
    for i = 1, #str do
        local char = str:sub(i, i)
        line:set_character_at(i, Character:new(char, hl))
    end
    return line
end

function M_line:overlay(at_column, other_line)
    for i = 1, other_line.length do
        local other_char = other_line:get_character_at(i)
        local new_index = at_column + i - 1
        if new_index > self.length then
            break
        end
        self:set_character_at(at_column + i - 1, other_char)
    end

end

return M_line
