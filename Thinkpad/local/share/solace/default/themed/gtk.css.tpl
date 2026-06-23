/**
 * Solace Theme with Sharp Corners (Hyprland-inspired)
 * GTK4 / libadwaita + GTK3 legacy
 */

/* Dynamic color palette from Solace colors.toml */
@define-color background {{ background }};
@define-color foreground {{ foreground }};

@define-color black {{ color0 }};
@define-color red {{ color1 }};
@define-color green {{ color2 }};
@define-color yellow {{ color3 }};
@define-color blue {{ color4 }};
@define-color magenta {{ color5 }};
@define-color cyan {{ color6 }};
@define-color white {{ color7 }};
@define-color bright_black {{ color8 }};
@define-color bright_red {{ color9 }};
@define-color bright_green {{ color10 }};
@define-color bright_yellow {{ color11 }};
@define-color bright_blue {{ color12 }};
@define-color bright_magenta {{ color13 }};
@define-color bright_cyan {{ color14 }};
@define-color bright_white {{ color15 }};

/* Adwaita color overrides (libadwaita / GTK4) */
@define-color accent_bg_color @blue;
@define-color accent_fg_color @background;
@define-color accent_color @cyan;

@define-color window_bg_color @background;
@define-color window_fg_color @foreground;

@define-color view_bg_color @background;
@define-color view_fg_color @foreground;

@define-color sidebar_bg_color @background;
@define-color sidebar_fg_color @foreground;
@define-color sidebar_backdrop_color @background;
@define-color sidebar_shade_color @background;

@define-color headerbar_bg_color @background;
@define-color headerbar_fg_color @foreground;
@define-color headerbar_backdrop_color @background;
@define-color headerbar_shade_color @background;
@define-color headerbar_border_color alpha(@foreground, 0.06);

@define-color card_bg_color alpha(@foreground, 0.03);
@define-color card_fg_color @foreground;
@define-color card_shade_color @background;

@define-color thumbnail_bg_color @background;
@define-color thumbnail_fg_color @foreground;

@define-color popover_bg_color @background;
@define-color popover_fg_color @foreground;

@define-color dialog_bg_color @background;
@define-color dialog_fg_color @foreground;

@define-color destructive_bg_color @red;
@define-color destructive_fg_color @background;

@define-color success_bg_color @green;
@define-color success_fg_color @background;

@define-color warning_bg_color @yellow;
@define-color warning_fg_color @background;

@define-color error_bg_color @red;
@define-color error_fg_color @background;

@define-color shade_color alpha(@foreground, 0.07);
@define-color scrollbar_outline_color alpha(@foreground, 0.06);
@define-color borders alpha(@foreground, 0.06);

/* GTK3 / Adwaita legacy color variables */
@define-color theme_fg_color @foreground;
@define-color theme_text_color @foreground;
@define-color theme_bg_color @background;
@define-color theme_base_color @background;
@define-color theme_selected_bg_color @blue;
@define-color theme_selected_fg_color @background;
@define-color insensitive_bg_color alpha(@foreground, 0.05);
@define-color insensitive_fg_color @bright_black;
@define-color insensitive_base_color @background;
@define-color theme_unfocused_fg_color @foreground;
@define-color theme_unfocused_text_color @foreground;
@define-color theme_unfocused_bg_color @background;
@define-color theme_unfocused_base_color @background;
@define-color theme_unfocused_selected_bg_color @blue;
@define-color theme_unfocused_selected_fg_color @background;
@define-color unfocused_insensitive_color @bright_black;
@define-color unfocused_borders alpha(@foreground, 0.06);
@define-color warning_color @yellow;
@define-color error_color @red;
@define-color success_color @green;
@define-color destructive_color @red;
@define-color placeholder_text_color alpha(@foreground, 0.5);
@define-color link_color @blue;
@define-color link_visited_color @magenta;

/* Content view colors */
@define-color content_view_bg @background;
@define-color text_view_bg @background;

/* GTK4/libadwaita surface variables and widgets.
 * Newer GNOME apps such as Nautilus do not reliably repaint every surface from
 * @define-color values alone, so keep explicit CSS variables and broad surface
 * selectors in sync with the active Solace palette.
 */
:root {
    --accent-bg-color: @accent_bg_color;
    --accent-fg-color: @accent_fg_color;
    --accent-color: @accent_color;
    --window-bg-color: @window_bg_color;
    --window-fg-color: @window_fg_color;
    --view-bg-color: @view_bg_color;
    --view-fg-color: @view_fg_color;
    --sidebar-bg-color: @sidebar_bg_color;
    --sidebar-fg-color: @sidebar_fg_color;
    --headerbar-bg-color: @headerbar_bg_color;
    --headerbar-fg-color: @headerbar_fg_color;
    --popover-bg-color: @popover_bg_color;
    --popover-fg-color: @popover_fg_color;
    --dialog-bg-color: @dialog_bg_color;
    --dialog-fg-color: @dialog_fg_color;
    --card-bg-color: @card_bg_color;
    --card-fg-color: @card_fg_color;
    --border-color: @borders;
    --shade-color: alpha(@foreground, 0.04);
    --window-outline-color: transparent;
}

window,
window.background,
applicationwindow,
.background {
    background-color: @window_bg_color;
    color: @window_fg_color;
}

headerbar,
toolbar,
toolbarview,
windowhandle {
    background-color: @headerbar_bg_color;
    color: @headerbar_fg_color;
    border-color: transparent;
    box-shadow: inset 0 -1px alpha(@foreground, 0.06);
}

headerbar button,
headerbar menubutton,
headerbar menubutton > button,
headerbar togglebutton,
windowhandle button,
windowhandle menubutton,
windowhandle menubutton > button,
toolbar button,
toolbar menubutton > button {
    background-color: alpha(@foreground, 0.05);
    color: @foreground;
    border: 1px solid transparent;
    box-shadow: none;
}

headerbar button:hover,
headerbar menubutton:hover,
headerbar menubutton > button:hover,
headerbar togglebutton:hover,
windowhandle button:hover,
windowhandle menubutton:hover,
windowhandle menubutton > button:hover,
toolbar button:hover,
toolbar menubutton > button:hover {
    background-color: alpha(@foreground, 0.10);
}

headerbar button:checked,
headerbar menubutton > button:checked,
headerbar togglebutton:checked,
windowhandle button:checked,
windowhandle menubutton > button:checked {
    background-color: alpha(@blue, 0.45);
    color: @foreground;
}

view,
gridview,
listview,
columnview,
treeview,
textview,
textview text,
.view,
.content,
.nautilus-window {
    background-color: @view_bg_color;
    color: @view_fg_color;
}

navigation-sidebar,
placessidebar,
sidebar,
.sidebar {
    background-color: @sidebar_bg_color;
    color: @sidebar_fg_color;
}

row,
list,
list > row,
columnview row,
gridview child {
    background-color: transparent;
    color: @foreground;
}

row:hover,
list > row:hover,
columnview row:hover,
gridview child:hover {
    background-color: alpha(@foreground, 0.07);
}

row:selected,
list > row:selected,
columnview row:selected,
gridview child:selected {
    background-color: @theme_selected_bg_color;
    color: @theme_selected_fg_color;
}

button,
menubutton,
togglebutton {
    color: @foreground;
}

columnview header,
columnviewheader,
columnviewcolumn,
columnview .column-header,
treeview header,
treeview header button {
    background-color: alpha(@foreground, 0.05);
    color: @foreground;
    border-color: transparent;
    box-shadow: none;
}

columnview header button,
columnviewheader button,
columnviewcolumn button,
treeview header button {
    background-color: transparent;
    color: @foreground;
    border: none;
    box-shadow: none;
}

columnview header button:hover,
columnviewheader button:hover,
columnviewcolumn button:hover,
treeview header button:hover {
    background-color: alpha(@foreground, 0.08);
}

popover,
popover contents,
popover.background,
popover.menu,
popover.menu contents,
menu,
menuitem,
modelbutton,
.menu,
.context-menu {
    background-color: @popover_bg_color;
    color: @popover_fg_color;
    border-color: alpha(@foreground, 0.06);
    box-shadow: 0 8px 24px alpha(@background, 0.45);
}

popover modelbutton:hover,
popover row:hover,
menuitem:hover,
modelbutton:hover {
    background-color: alpha(@foreground, 0.08);
    color: @foreground;
}

separator {
    background-color: alpha(@foreground, 0.06);
}

/* Text-selection highlight (entries, labels, text views) */
selection {
    background-color: @blue;
    color: @background;
}

/* Entry styling — readable pinentry-gnome3 password field, Nautilus search, etc. */
entry,
entry > text {
    background-color: alpha(@foreground, 0.05);
    color: @foreground;
}

entry:focus-within,
entry:focus-within > text {
    background-color: alpha(@foreground, 0.08);
}

entry:disabled,
entry:disabled > text {
    color: @bright_black;
}

entry > text > placeholder {
    color: alpha(@foreground, 0.5);
}

/* GtkMessageDialog */
messagedialog {
    background-color: @dialog_bg_color;
    border-color: alpha(@foreground, 0.06);
}

messagedialog label {
    color: @dialog_fg_color;
    font-size: 14pt;
    font-weight: bold;
}

messagedialog .secondary-text {
    font-size: 10pt;
    font-style: italic;
}

messagedialog button {
    background-color: @background;
    color: @foreground;
    border: 1px solid transparent;
}

messagedialog button:hover {
    background-color: @blue;
    color: @background;
}

banner revealer widget {
    background: @bright_black;
    padding: 5px;
    color: @foreground;
}

/* Filechooser */
filechooser .dialog-action-box {
    border-top: 1px solid @borders;
}

filechooser .dialog-action-box:backdrop {
    border-top-color: @borders;
}

filechooser #pathbarbox {
    border-bottom: 1px solid @borders;
}

filechooserbutton:drop(active) {
    box-shadow: none;
    border-color: transparent;
}

/* Toast */
toast {
    background-color: @background;
    color: @foreground;
    border: 1px solid alpha(@foreground, 0.06);
}

toast button.circular.flat.image-button:hover {
    color: @background;
    background-color: @red;
}

/* Sharp corners, Hyprland-inspired */
* {
    border-radius: 0;
}

/* Nautilus / libadwaita hard overrides.
 * Some controls keep Adwaita's widget-level backgrounds unless we override the
 * actual button/header/popover nodes with higher specificity and background
 * shorthand.
 */
window.nautilus-window headerbar,
window.nautilus-window windowhandle,
window.nautilus-window toolbarview,
window.nautilus-window .titlebar {
    background: @background;
    color: @foreground;
    border-color: transparent;
    box-shadow: inset 0 -1px alpha(@foreground, 0.06);
}

window.nautilus-window headerbar button,
window.nautilus-window headerbar button.flat,
window.nautilus-window headerbar button.image-button,
window.nautilus-window headerbar menubutton > button,
window.nautilus-window headerbar togglebutton,
window.nautilus-window windowhandle button,
window.nautilus-window windowhandle button.flat,
window.nautilus-window windowhandle button.image-button,
window.nautilus-window windowhandle menubutton > button,
window.nautilus-window button.path-bar,
window.nautilus-window pathbar button,
window.nautilus-window .path-bar button,
window.nautilus-window .linked button {
    background: alpha(@foreground, 0.035);
    color: @foreground;
    border: 1px solid transparent;
    box-shadow: none;
    text-shadow: none;
}

window.nautilus-window headerbar button:hover,
window.nautilus-window headerbar button.flat:hover,
window.nautilus-window headerbar button.image-button:hover,
window.nautilus-window headerbar menubutton > button:hover,
window.nautilus-window windowhandle button:hover,
window.nautilus-window windowhandle button.flat:hover,
window.nautilus-window windowhandle button.image-button:hover,
window.nautilus-window windowhandle menubutton > button:hover,
window.nautilus-window button.path-bar:hover,
window.nautilus-window pathbar button:hover,
window.nautilus-window .path-bar button:hover,
window.nautilus-window .linked button:hover {
    background: alpha(@foreground, 0.08);
    color: @foreground;
}

window.nautilus-window headerbar button:checked,
window.nautilus-window headerbar togglebutton:checked,
window.nautilus-window headerbar menubutton > button:checked,
window.nautilus-window windowhandle button:checked,
window.nautilus-window windowhandle menubutton > button:checked {
    background: alpha(@blue, 0.55);
    color: @foreground;
}

window.nautilus-window columnview,
window.nautilus-window columnview.view,
window.nautilus-window columnview > header,
window.nautilus-window columnview header,
window.nautilus-window columnviewheader,
window.nautilus-window columnviewcolumn,
window.nautilus-window .column-header,
window.nautilus-window .column-header button {
    background: @background;
    color: @foreground;
    border-color: transparent;
    box-shadow: none;
}

window.nautilus-window columnview > header > button,
window.nautilus-window columnview header button,
window.nautilus-window columnviewheader button,
window.nautilus-window columnviewcolumn button,
window.nautilus-window .column-header button {
    background: alpha(@foreground, 0.035);
    color: @foreground;
    border: 1px solid transparent;
    box-shadow: none;
}

window.nautilus-window columnview > header > button:hover,
window.nautilus-window columnview header button:hover,
window.nautilus-window columnviewheader button:hover,
window.nautilus-window columnviewcolumn button:hover,
window.nautilus-window .column-header button:hover {
    background: alpha(@foreground, 0.08);
}

window.nautilus-window popover,
window.nautilus-window popover contents,
window.nautilus-window popover.background,
window.nautilus-window popover.menu,
window.nautilus-window popover.menu contents,
window.nautilus-window modelbutton,
window.nautilus-window popover row {
    background: @background;
    color: @foreground;
    border-color: alpha(@foreground, 0.06);
    box-shadow: 0 8px 24px alpha(@background, 0.45);
}

window.nautilus-window popover modelbutton:hover,
window.nautilus-window popover row:hover,
window.nautilus-window modelbutton:hover {
    background: alpha(@foreground, 0.08);
    color: @foreground;
}
