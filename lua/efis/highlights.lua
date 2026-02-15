local M_highlights = {}



function M_highlights:set_hl(name, properties)
    local hl_def = {}
    for key, value in pairs(properties) do
        hl_def[key] = value
    end
    vim.api.nvim_set_hl(0, name, hl_def)
end

-- TODO FIXME:
-- when you toggle the theme
-- with navarasu/onedark.nvim, it voids all highlights...

function M_highlights:setup()
    -- EFIS PFD Altimeter
    self:set_hl("AltimeterCurrentLine", vim.api.nvim_get_hl(0, { name = "@attribute" }))
    -- self:set_hl("AltimeterBorderLineWindow", { fg = "#c8c857", bold = false })
    -- self:set_hl("AltimeterCurrentLineArrow", { fg = "#c8c857", bold = false })
    self:set_hl("AltimeterBorderLineWindow", vim.api.nvim_get_hl(0, { name = "LineNr" }))
    self:set_hl("AltimeterCurrentLineArrow", vim.api.nvim_get_hl(0, { name = "@attribute" }))
    -- self:set_hl("AltimeterLinePrevNextDigit", { fg = "#00ff00", bold = false })
    self:set_hl("AltimeterLinePrevNextDigit", vim.api.nvim_get_hl(0, { name = "Normal" }))
    self:set_hl("AltimeterVisualSelection", vim.api.nvim_get_hl(0, { name = "@function" }))
    self:set_hl("AltimeterTopBottomBorder", vim.api.nvim_get_hl(0, { name = "LineNr" }))
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
end

return M_highlights
