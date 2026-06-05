return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg         = "#00020a",
        dark_bg    = "#000208",
        darker_bg  = "#000105",
        lighter_bg = "#1a1b23",

        fg         = "#ffffff",
        dark_fg    = "#bfbfbf",
        light_fg   = "#ffffff",
        bright_fg  = "#ffffff",
        muted      = "#54565a",

        red        = "#74661a",
        yellow     = "#749951",
        orange     = "#897d3c",
        green      = "#458d59",
        cyan       = "#2c8478",
        blue       = "#3b6aa5",
        purple     = "#7b5daf",
        brown      = "#524b24",

        bright_red    = "#9b8d19",
        bright_yellow = "#9fd068",
        bright_green  = "#66c677",
        bright_cyan   = "#36ceb8",
        bright_blue   = "#6298ea",
        bright_purple = "#bca0ec",

        accent               = "#3b6aa5",
        cursor               = "#ffffff",
        foreground           = "#ffffff",
        background           = "#00020a",
        selection             = "#1a1b23",
        selection_foreground = "#ffffff",
        selection_background = "#1a1b23",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
