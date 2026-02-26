local M_highlights = {}



function M_highlights:set_hl(name, properties)
    local hl_def = {}
    for key, value in pairs(properties) do
        hl_def[key] = value
    end
    vim.api.nvim_set_hl(0, name, hl_def)
end

local function extract_rgb_from_color(color)
    -- without using bitshift operators because unsupported by current
    -- lua version 
    local r = math.floor(color / 65536) % 256
    local g = math.floor(color / 256) % 256
    local b = color % 256
    return { r = r, g = g, b = b }
end

local function generate_fade_highlights()
    local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
    local fade_highlights = {}
    local normal_hl_rgb = extract_rgb_from_color(normal_hl.fg or 0)
    local decrease_brightness = normal_hl_rgb.r > 127 or normal_hl_rgb.g > 127 or normal_hl_rgb.b > 127
    for i = 1, 10 do
        local factor = i / 10
        local hl_name = "NormalFade" .. i
        local hl_def = {}
        if normal_hl.fg then
            local r = math.floor(normal_hl_rgb.r * (decrease_brightness and (1 - factor) or (1 + factor)))
            local g = math.floor(normal_hl_rgb.g * (decrease_brightness and (1 - factor) or (1 + factor)))
            local b = math.floor(normal_hl_rgb.b * (decrease_brightness and (1 - factor) or (1 + factor)))
            hl_def.fg = string.format("#%02x%02x%02x", r, g, b)
        end
        if normal_hl.bg then
            local normal_hl_bg_rgb = extract_rgb_from_color(normal_hl.bg)
            local r = math.floor(normal_hl_bg_rgb.r * (decrease_brightness and (1 - factor) or (1 + factor)))
            local g = math.floor(normal_hl_bg_rgb.g * (decrease_brightness and (1 - factor) or (1 + factor)))
            local b = math.floor(normal_hl_bg_rgb.b * (decrease_brightness and (1 - factor) or (1 + factor)))
            hl_def.bg = string.format("#%02x%02x%02x", r, g, b)
        end
        fade_highlights[hl_name] = hl_def
    end
    return fade_highlights
end

-- TODO FIXME:
-- when you toggle the theme
-- with navarasu/onedark.nvim, it voids all highlights...

function M_highlights:setup()

    local fade_highlights = generate_fade_highlights()
    for hl_name, hl_def in pairs(fade_highlights) do
        self:set_hl(hl_name, hl_def)
    end


    -- EFIS PFD Altimeter
    self:set_hl("AltimeterCurrentLine", vim.api.nvim_get_hl(0, { name = "@attribute" }))
    -- self:set_hl("AltimeterBorderLineWindow", { fg = "#c8c857", bold = false })
    -- self:set_hl("AltimeterCurrentLineArrow", { fg = "#c8c857", bold = false })
    self:set_hl("AltimeterBorderLineWindow", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("AltimeterCurrentLineArrow", vim.api.nvim_get_hl(0, { name = "@attribute" }))
    -- self:set_hl("AltimeterLinePrevNextDigit", { fg = "#00ff00", bold = false })
    self:set_hl("AltimeterLinePrevNextDigit", vim.api.nvim_get_hl(0, { name = "Normal" }))
    self:set_hl("AltimeterVisualSelection", vim.api.nvim_get_hl(0, { name = "@function" }))
    self:set_hl("AltimeterTopBottomBorder", vim.api.nvim_get_hl(0, { name = "Normal" }))
    self:set_hl("AltimeterFileProgressionPerc", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    -- self:set_hl("AltimeterCurrentLine", vim.api.nvim_get_hl(0, { name = "Added" }))
    --
    -- EFIS PFD Heading
    self:set_hl("HeadingBorders", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("HeadingScaleNumbers", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("HeadingCurrentCharPos", vim.api.nvim_get_hl(0, { name = "@attribute" }))

    -- Buffer display highlights
    self:set_hl("BufferDisplayLabels", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("BufferDisplaySeparator", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("BufferDisplayCurrentBuffer", vim.api.nvim_get_hl(0, { name = "Normal" }))
    self:set_hl("BufferDisplayOtherBuffers", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("BufferDisplaySymbols", vim.api.nvim_get_hl(0, { name = "Normal" }))
    self:set_hl("BufferDisplaySymbolModified", { fg = "#00ff00", bold = true })
    self:set_hl("BufferDisplayCountDigits", vim.api.nvim_get_hl(0, { name = "Normal" }))
    self:set_hl("BufferDisplayModifiedCountDigitsNonZero", { fg = "#00ff00", bold = true })

    self:set_hl("AnalogMarkDark1", vim.api.nvim_get_hl(0, { name = "LineNr" }))
end

return M_highlights
