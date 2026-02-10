local cfg = require("altimeter.config")

local M = {}

function M.setup(opts)
    cfg:setup(opts)
    local altimeter_ui = require("altimeter.ui")
    local ui_instance = altimeter_ui:new()

    ui_instance:create_autocmds()

    vim.api.nvim_create_user_command("AltimeterToggle", function()
        ui_instance:toggle()
        if ui_instance.active then
            ui_instance:draw()
        end
    end, {
        desc = "Toggle altimeter UI",
        bang = true,
    })


    print("hi from setup")
end

return M
