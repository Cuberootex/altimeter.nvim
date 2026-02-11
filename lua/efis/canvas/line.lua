local M_line = {}
local Character = require("efis.canvas.character")

function M_line:new(length)
    local instance = {
        characters = {},
        length = length
    }
    for i = 1, length do
        table.insert(instance.characters, Character:new(nil))
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

function M_line.create_from_str(str)
    local line = M_line:new(#str)
    for i = 1, #str do
        local char = str:sub(i, i)
        line:set_character_at(i, Character:new(char))
    end
    return line
end

return M_line
