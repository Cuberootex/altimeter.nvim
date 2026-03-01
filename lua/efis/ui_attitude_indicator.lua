local M_ui_attitude_indicator = {}
local api = vim.api
local Character = require("efis.canvas.character")

function M_ui_attitude_indicator:new()
    local instance = {
        augrp = -1,
    }
    setmetatable(instance, { __index = self })
    return instance
end

function M_ui_attitude_indicator:create_statuscolumn_fmt()
    -- due to the way this works
    -- I don't think I can use a "canvas" here...
    _G.efis_stylized_line_numbers_fmt = function()
        local symbols = {
            vertical_tape_line = Character:new("│"),
            mark_5_vertical = Character:new("┤"),
            mark_5_line = Character:new("╶"),
            mark_10_vertical = Character:new("┥"),
            mark_10_line = Character:new("╺"),
            current_line_indicator = Character:new("▷"),
        }

        local ft = vim.bo.filetype
        local bt = vim.bo.buftype

        if
            ft == "alpha"
            or ft == "dashboard"
            or bt == "nofile"
            or bt == "terminal"
        then
            return ""
        end

        local lnum = vim.v.lnum
        local relnum = vim.v.relnum
        local cursor = vim.api.nvim_win_get_cursor(0)
        local cursor_lnum = cursor[1]
        local total_lines = vim.api.nvim_buf_line_count(0)

        local relnum_len_delta = #tostring(total_lines) - #tostring(relnum)
        local left_padding_str = string.rep(" ", relnum_len_delta)

        local cur_relnum_str = tostring(vim.v.relnum)
        if vim.fn.mode() == "i" and relnum % 5 ~= 0 then
            cur_relnum_str = string.rep(" ", #cur_relnum_str)
        end


        local vertical_motion = lnum < cursor_lnum and "k" or "j"
        local v_motion_str = " "
        if relnum ~= 0 and relnum % 5 == 0 and vim.fn.mode() ~= "i" then
            v_motion_str = vertical_motion
        end

        local cur_line_indicator_str = " "
        if relnum == 0 then
            cur_line_indicator_str = symbols.current_line_indicator.char
        end

        local rightmost_border = symbols.vertical_tape_line.char
        local mark = " "

        if relnum % 10 == 0 then
            mark = symbols.mark_10_line.char
            rightmost_border = symbols.mark_10_vertical.char
        elseif relnum % 5 == 0 then
            mark = symbols.mark_5_line.char
            rightmost_border = symbols.mark_5_vertical.char
        end

        local line_hl = "Normal"
        local analog_tape_hl = "Normal"
        if relnum > 0 then
            -- todo: config
            local fade_limit = 4
            if vim.fn.mode() == "i" then
                -- todo: config
                fade_limit = 8
            end
            local fade_index = math.min(fade_limit, relnum)
            local hl_prefix = "NormalFade"
            line_hl = hl_prefix .. tostring(fade_index)
            analog_tape_hl = line_hl
        end

        if relnum > 0 and vim.fn.mode() ~= "i" then
            -- todo: config
            local fade_index = math.min(6, relnum)
            if lnum < cursor_lnum then
                analog_tape_hl = "LineNrPositiveFade" .. fade_index
            else
                analog_tape_hl = "LineNrNegativeFade" .. fade_index
            end
        end



        return
            "%#" .. line_hl .. "#"
            .. left_padding_str
            .. cur_relnum_str
            .. "%#" .. analog_tape_hl .. "#"
            .. v_motion_str
            .. cur_line_indicator_str
            .. mark
            .. rightmost_border
            .. " "
    end
    vim.opt.statuscolumn = "%s%{%v:lua.efis_stylized_line_numbers_fmt()%}"
end

function M_ui_attitude_indicator:create_autocmds()
    self.augrp = api.nvim_create_augroup("efis_attitude_ui", { clear = true })
    local events = {
        "TextChanged",
        "TextChangedI",
        "CursorMoved",
        "CursorMovedI",
    }
    api.nvim_create_autocmd(events, {
        callback = function()
            self:create_statuscolumn_fmt()
        end,
        group = self.augrp
    })
end

return M_ui_attitude_indicator
