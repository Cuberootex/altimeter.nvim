local api = vim.api
local ui_altimeter = require("efis.ui")
local ui_heading = require("efis.ui_heading")
local ui_buffers = require("efis.ui_buffers")

local M_core = {}

function M_core:new()
    
end

function M_core:setup_autocmds()
    local augrp = api.nvim_create_augroup("efis", {})
    api.nvim_create_autocmd("CursorMoved", {
        group = augrp,
        callback = function()
            ui_altimeter:draw()
            ui_heading:draw()
            ui_buffers:draw()
        end
    })
end

function M_core:clear_autocmds()
    api.nvim_del_augroup_by_name("efis")
end

return M_core
