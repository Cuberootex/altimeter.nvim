local M_character = {}

function M_character:new(char, hl_group)
    local instance = {
        char = char,
        hl_group = hl_group or "Normal",
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

function M_character:set_hl_group(hl_group)
    self.hl_group = hl_group
end

return M_character
