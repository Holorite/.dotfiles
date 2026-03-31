return {
    "FluxxField/smart-motion.nvim",
    enabled = false,
    opts = {
        presets = {
            words = true,        -- w, b, e, ge
            lines = true,        -- j, k
            search = true,       -- s, S, f, F, t, T, ;, ,
            delete = true,       -- d + any motion
            yank = true,         -- y + any motion
            change = true,       -- c + any motion
            treesitter = true,   -- ]], [[, af, if, ac, ic, aa, ia, fn, saa, gS, R
            diagnostics = true,  -- ]d, [d, ]e, [e
            misc = true,         -- . g. g1-g9 gp gP gA-gZ gmd gmy (repeat, history, pins, multi-cursor)
        },
    },
}
