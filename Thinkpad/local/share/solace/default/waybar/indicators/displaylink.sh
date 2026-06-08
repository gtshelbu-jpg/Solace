#!/usr/bin/env bash

set -u

mode="${1:-json}"

service_exists=false
service_state="missing"
evdi_loaded=false
usb_count=0
drm_displaylink_count=0
drm_external_count=0
hypr_external_count=0
hypr_total_count=0
hypr_external_names=""

if systemctl list-unit-files --type=service --no-legend displaylink.service 2>/dev/null | grep -q '^displaylink\.service' \
  || [[ -f /usr/lib/systemd/system/displaylink.service || -f /etc/systemd/system/displaylink.service ]]; then
  service_exists=true
  service_state="$(systemctl is-active displaylink.service 2>/dev/null || true)"
  [[ -n "$service_state" ]] || service_state="unknown"
fi

[[ -d /sys/module/evdi ]] && evdi_loaded=true

if command -v lsusb >/dev/null 2>&1; then
  usb_count="$(lsusb 2>/dev/null | grep -Eic 'DisplayLink|17e9:')"
fi

while IFS= read -r status_file; do
  [[ -r "$status_file" ]] || continue
  [[ "$(cat "$status_file" 2>/dev/null)" == "connected" ]] || continue

  connector="$(basename "$(dirname "$status_file")")"
  case "$connector" in
    *eDP*|*LVDS*) ;;
    *)
      drm_external_count=$((drm_external_count + 1))
      case "$connector" in
        *DVI-I*|*DisplayLink*|*USB*) drm_displaylink_count=$((drm_displaylink_count + 1)) ;;
      esac
      ;;
  esac
done < <(find /sys/class/drm -maxdepth 2 -type f -name status 2>/dev/null)

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  monitors_json="$(hyprctl monitors -j 2>/dev/null || true)"
  if [[ -n "$monitors_json" ]]; then
    hypr_total_count="$(jq '[.[] | select(.disabled != true)] | length' <<<"$monitors_json" 2>/dev/null || printf '0')"
    hypr_external_count="$(jq '[.[] | select(.disabled != true) | select((.name | test("^(eDP|LVDS)")) | not)] | length' <<<"$monitors_json" 2>/dev/null || printf '0')"
    hypr_external_names="$(jq -r '[.[] | select(.disabled != true) | select((.name | test("^(eDP|LVDS)")) | not) | .name] | join(", ")' <<<"$monitors_json" 2>/dev/null || true)"
  fi
fi

class=""
icon="󰍹"
text=""

if ! $service_exists && ! $evdi_loaded && (( usb_count == 0 && drm_external_count == 0 )); then
  text=""
elif ! $service_exists; then
  text="󰍺!"
  class="warning"
elif $service_exists && [[ "$service_state" != "active" && "$service_state" != "unknown" ]]; then
  text="󰍺!"
  class="warning"
elif ! $evdi_loaded; then
  text="󰍺!"
  class="warning"
elif (( hypr_external_count > 0 )); then
  text="$icon $hypr_external_count"
  class="active"
elif (( drm_displaylink_count > 0 )); then
  text="$icon $drm_displaylink_count"
  class="active"
else
  text="$icon"
  class="ready"
fi

tooltip_lines=(
  "DisplayLink"
  "Service: $service_state"
  "EVDI module: $($evdi_loaded && printf loaded || printf missing)"
  "DisplayLink USB devices: $usb_count"
  "DRM external connectors: $drm_external_count"
  "DRM DisplayLink-like connectors: $drm_displaylink_count"
  "Hyprland monitors: $hypr_total_count total, $hypr_external_count external"
)

if [[ -n "$hypr_external_names" ]]; then
  tooltip_lines+=("External outputs: $hypr_external_names")
fi

tooltip="$(printf '%s\n' "${tooltip_lines[@]}")"

if [[ "$mode" == "--tooltip" ]]; then
  printf '%s\n' "$tooltip"
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
    '{text: $text, tooltip: $tooltip} + (if $class == "" then {} else {class: $class} end)'
else
  tooltip="${tooltip//$'\n'/\\n}"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
fi
