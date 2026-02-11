local api = vim.api
local ui = require("efis.ui")

local M_core = {}

function M_core:new()
    
end

function M_core:setup_autocmds()
    local augrp = api.nvim_create_augroup("efis", {})
    api.nvim_create_autocmd("CursorMoved", {
        group = augrp,
        callback = function()
            ui:draw()
        end
    })
end

function M_core:clear_autocmds()
    api.nvim_del_augroup_by_name("efis")
end

return M_core
