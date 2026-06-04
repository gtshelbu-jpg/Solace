return {
    {
        "bjarneo/aether.nvim",
        branch = "v2",
        name = "aether",
        priority = 1000,
        opts = {
            transparent = false,
            colors = {
                -- Background colors
                bg = "#181c22",
                bg_dark = "#181c22",
                bg_highlight = "#898c96",

                -- Foreground colors
                -- fg: Object properties, builtin types, builtin variables, member access, default text
                fg = "#fffefd",
                -- fg_dark: Inactive elements, statusline, secondary text
                fg_dark = "#f3bd92",
                -- comment: Line highlight, gutter elements, disabled states
                comment = "#898c96",

                -- Accent colors
                -- red: Errors, diagnostics, tags, deletions, breakpoints
                red = "#957172",
                -- orange: Constants, numbers, current line number, git modifications
                orange = "#c6aeaf",
                -- yellow: Types, classes, constructors, warnings, numbers, booleans
                yellow = "#f8b280",
                -- green: Comments, strings, success states, git additions
                green = "#5e6360",
                -- cyan: Parameters, regex, preprocessor, hints, properties
                cyan = "#50747f",
                -- blue: Functions, keywords, directories, links, info diagnostics
                blue = "#8c8d9a",
                -- purple: Storage keywords, special keywords, identifiers, namespaces
                purple = "#746b73",
                -- magenta: Function declarations, exception handling, tags
                magenta = "#a8a0a8",
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
