local cfg = require("efis.config")

local M = {}

function M.setup(opts)
    cfg:setup(opts)
    local highlights = require("efis.highlights")
    local altimeter_ui = require("efis.ui")
    local ui_instance = altimeter_ui:new()
    local heading_ui = require("efis.ui_heading")
    local heading_ui_instance = heading_ui:new()
    local heading_buffers = require("efis.ui_buffers")
    local heading_buffers_instance = heading_buffers:new()

    highlights:setup()
    ui_instance:create_autocmds()
    heading_ui_instance:create_autocmds()
    heading_buffers_instance:create_autocmds()

    vim.api.nvim_create_user_command("AltimeterToggle", function()
        ui_instance:toggle()
        if ui_instance.active then
            ui_instance:draw()
        end
    end, {
        desc = "Toggle altimeter UI",
        bang = true,
    })
end

return M
