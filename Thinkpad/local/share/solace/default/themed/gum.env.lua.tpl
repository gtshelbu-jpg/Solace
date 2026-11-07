-- Read legacy environment output as data, never as executable Hyprland syntax.
-- This keeps both compositor formats on the same generated palette.
local path = os.getenv("HOME") .. "/.config/solace/current/theme/gum.env.conf"
for line in io.lines(path) do
  local name, value = line:match("^env%s*=%s*([A-Z_]+),(.+)$")
  if name then
    hl.env(name, (value:gsub("^##", "#")))
  end
end
