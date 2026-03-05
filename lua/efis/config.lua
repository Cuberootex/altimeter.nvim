local M_config = {}

M_config.defaults = {
    -- Altimeter UI
    altimeter = {
        enabled = true,
        enabled_on_vim_enter = true,
        autohide = {
            enabled = true,
            padding_x_percent = 0.2,
            use_character_column_position = false,
        },
        fade = {
            enabled = true,
            threshold = 1,
        },
        file_progression = {
            show_percentage = true,
            percentage_offset = 3,
            show_on_mod_n = 5,
            show_symbol = false,
        },
        length_marker_line = 1,
        top_bottom_borders = false,
        tape_start_col = 2,
    },

    -- Heading UI
    heading = {
        enabled = true,
        enabled_on_vim_enter = true,
        autohide = {
            enabled = false,
            padding_x_percent = 0.2,
            use_character_column_position = false,
        },
        fade = {
            enabled = true,
            threshold = 3,
        },
        char_limit = 100,
        show_analog_scale = true,
        show_scale_beyond_total_chars = false,
        show_tape_limits = false,
        show_total_chars = true,
    },

    -- Attitude Indicator (status column)
    attitude = {
        enabled = true,
        fade = {
            normal_mode_limit = 6,
            insert_mode_limit = 8,
            insert_mode_faded_limit = 4,
        },
        show_motion_indicators = true,
        show_relnum_in_insert = false,
    },

    -- Buffers UI
    buffers = {
        enabled = true,
        enabled_on_vim_enter = true,
        autohide = {
            enabled = true,
            padding_x_percent = 0.2,
            use_character_column_position = false,
        },
    },

    -- Window options for all UIs
    window = {
        winblend = 100,
        focusable = false,
        style = "minimal",
    },

    -- Symbols for altimeter
    symbols = {
        altimeter = {
            mark_top_vertical = "Ⓣ",
            mark_top_line = "═",
            vertical_tape_line = "│",
            mark_5_vertical = "├",
            mark_5_line = "╴",
            mark_10_vertical = "┝",
            mark_10_line = "╸",
            mark_bottom_vertical = "🅑",
            mark_bottom_line = "═",
            mark_visual_sel_vertical_start = "╈",
            mark_visual_sel_vertical = "┇",
            mark_visual_sel_vertical_end = "╀",
            mark_visual_sel_vertical_one_line = "┿",
            icon_visual_sel_line = "󰒅",
            top_left = "┯",
            top_right = "┄",
            bottom_left = "┷",
            bottom_right = "┄",
            horizontal_border = "┄",
            arrow_pointing_left = "◁",
            border_top_left = "┌",
            border_top_right = "┐",
            border_bottom_left = "└",
            border_bottom_right = "┘",
            border_vertical = "│",
            border_horizontal = "─",
        },
        heading = {
            downward_pointing_arrow = "🮮",
            horizontal_line = "─",
            horizontal_line_not_reached = " ",
            start_of_tape = "┠",
            end_of_tape = "┨",
            start_and_end_of_tape = "┃",
            mark_type_1 = "┴",
            mark_type_2 = "┸",
            mark_type_1_past_limit = "╧",
            mark_type_2_past_limit = "╩",
            horizontal_line_past_limit = "═",
            mark_char_limit = "╬",
            tape_left_limit = "┋",
            tape_right_limit = "┋",
            modifier_right_arrowhead = "›",
        },
        attitude = {
            vertical_tape_line = "│",
            mark_5_vertical = "┤",
            mark_5_line = "╶",
            mark_10_vertical = "┥",
            mark_10_line = "╺",
            current_line_indicator = "▷",
        },
    },

    -- Highlight groups (can be customized)
    highlights = {
        enabled = true,
        custom_groups = {},
    },
}

function M_config:setup(opts)
    opts = opts or {}

    M_config.values = vim.deepcopy(M_config.defaults)

    if opts.altimeter then
        M_config.values.altimeter = vim.tbl_deep_extend("force", M_config.values.altimeter, opts.altimeter)
    end
    if opts.heading then
        M_config.values.heading = vim.tbl_deep_extend("force", M_config.values.heading, opts.heading)
    end
    if opts.attitude then
        M_config.values.attitude = vim.tbl_deep_extend("force", M_config.values.attitude, opts.attitude)
    end
    if opts.buffers then
        M_config.values.buffers = vim.tbl_deep_extend("force", M_config.values.buffers, opts.buffers)
    end
    if opts.window then
        M_config.values.window = vim.tbl_deep_extend("force", M_config.values.window, opts.window)
    end
    if opts.symbols then
        M_config.values.symbols = vim.tbl_deep_extend("force", M_config.values.symbols, opts.symbols)
    end
    if opts.highlights then
        M_config.values.highlights = vim.tbl_deep_extend("force", M_config.values.highlights, opts.highlights)
    end
end

function M_config.get(section, key)
    if not M_config.values then
        return M_config.defaults[section][key]
    end
    if section and key then
        return M_config.values[section][key]
    end
    if section then
        return M_config.values[section]
    end
    return M_config.values
end

return M_config