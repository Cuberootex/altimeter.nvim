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

local function get_hsl_from_color(color)
    local rgb = extract_rgb_from_color(color)
    local r = rgb.r
    local g = rgb.g
    local b = rgb.b
    local r_norm = r / 255
    local g_norm = g / 255
    local b_norm = b / 255
    local max = math.max(r_norm, g_norm, b_norm)
    local min = math.min(r_norm, g_norm, b_norm)
    local delta = max - min
    local l = (max + min) / 2
    local s
    if delta == 0 then
        s = 0
    else
        s = delta / (1 - math.abs(2 * l - 1))
    end
    local h
    if delta == 0 then
        h = 0
    elseif max == r_norm then
        h = ((g_norm - b_norm) / delta) % 6
    elseif max == g_norm then
        h = (b_norm - r_norm) / delta + 2
    else
        h = (r_norm - g_norm) / delta + 4
    end
    h = h * 60
    if h < 0 then
        h = h + 360
    end
    return { h = h, s = s, l = l }
end

local function generate_fade_highlights(base_hl_name, new_hl_prefix)
    local base_hl = vim.api.nvim_get_hl(0, { name = base_hl_name })
    local fade_highlights = {}
    local base_hl_rgb = extract_rgb_from_color(base_hl.fg or 0)
    local base_hl_hsl = get_hsl_from_color(base_hl.fg or 0)
    local decrease_brightness = base_hl_hsl.l > 0.5
    for i = 1, 10 do
        local factor = i / 10
        local hl_name = new_hl_prefix .. i
        local hl_def = {}
        if base_hl.fg then
            local r, g, b
            if decrease_brightness then
                r = math.floor(base_hl_rgb.r * (1 - factor))
                g = math.floor(base_hl_rgb.g * (1 - factor))
                b = math.floor(base_hl_rgb.b * (1 - factor))
            else
                local inv_r = 255 - base_hl_rgb.r
                local inv_g = 255 - base_hl_rgb.g
                local inv_b = 255 - base_hl_rgb.b
                r = math.floor(base_hl_rgb.r + factor * (inv_r - base_hl_rgb.r))
                g = math.floor(base_hl_rgb.g + factor * (inv_g - base_hl_rgb.g))
                b = math.floor(base_hl_rgb.b + factor * (inv_b - base_hl_rgb.b))
            end
            hl_def.fg = string.format("#%02x%02x%02x", r, g, b)
        end
        fade_highlights[hl_name] = hl_def
    end
    return fade_highlights
end


function M_highlights:setup()
    for _, hl_table in ipairs({
        -- todo configurable, obviously
        generate_fade_highlights("Normal", "NormalFade"),
        generate_fade_highlights("@method", "VisualModeFade"),
        generate_fade_highlights("Normal", "LineNrPositiveFade"),
        generate_fade_highlights("Normal", "LineNrNegativeFade")
        -- the colors below resemble more the attitude indicators
        -- or artificial horizons
        -- generate_fade_highlights("@attribute", "LineNrPositiveFade"),
        -- generate_fade_highlights("@boolean", "LineNrNegativeFade")
    }) do
        for hl_name, hl_def in pairs(hl_table) do
            self:set_hl(hl_name, hl_def)
        end
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
