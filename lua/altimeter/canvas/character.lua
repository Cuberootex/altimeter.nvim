local M_character = {}

function M_character:new(char, char_properties)
    local instance = {
        char = char,
        properties = char_properties or {},
    }
    setmetatable(instance, { __index = self })
    return instance
end

function M_character:get_str_for_display(debug_mode)
    local blank_char = " "
    if debug_mode then
        blank_char = "."
    end
    return self.char or blank_char
end

return M_character
