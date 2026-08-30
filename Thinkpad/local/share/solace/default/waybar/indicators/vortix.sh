#!/bin/bash

set -u

mode="${1:-json}"

json_escape() {
  if command -v jq >/dev/null 2>&1; then
    jq -Rn --arg value "$1" '$value'
  else
    local value="${1//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    printf '"%s"' "$value"
  fi
}

emit() {
  local text="$1"
  local tooltip="$2"
  local class="${3:-}"

  if [[ "$mode" == "--tooltip" ]]; then
    printf '%s\n' "$tooltip"
    exit 0
  fi

  if [[ -n "$class" ]]; then
    printf '{"text":%s,"tooltip":%s,"class":%s}\n' \
      "$(json_escape "$text")" \
      "$(json_escape "$tooltip")" \
      "$(json_escape "$class")"
  else
    printf '{"text":%s,"tooltip":%s}\n' \
      "$(json_escape "$text")" \
      "$(json_escape "$tooltip")"
  fi

  exit 0
}

vortix_available=false
status_json='{"data":{"connections":[],"security":{"killswitch_mode":"unknown","killswitch_state":"unknown"}}}'

if command -v vortix >/dev/null 2>&1; then
  vortix_available=true
  status_json="$(vortix status --json 2>/dev/null || true)"

  if [[ -z $status_json ]] || ! jq -e . >/dev/null 2>&1 <<<"$status_json"; then
    emit "󰦝!" "Vortix status unavailable" "warning"
  fi
fi

connected_count="$(jq '(.data.connections // []) | length' <<<"$status_json" 2>/dev/null || printf '0')"
killswitch_mode="$(jq -r '.data.security.killswitch_mode // "unknown"' <<<"$status_json" 2>/dev/null || printf 'unknown')"
killswitch_state="$(jq -r '.data.security.killswitch_state // "unknown"' <<<"$status_json" 2>/dev/null || printf 'unknown')"
connection_json="$(jq -c '.data.primary // .data.connection // .data.connections[0] // {}' <<<"$status_json" 2>/dev/null || printf '{}')"

detect_tunnel_interfaces() {
  local interface_path interface flags routes wireguard_interfaces=""
  local tunnel_interfaces=()

  [[ -d /sys/class/net ]] || return

  if command -v wg >/dev/null 2>&1; then
    wireguard_interfaces="$(wg show interfaces 2>/dev/null || true)"
  fi

  routes="$(ip -o route show table all 2>/dev/null; ip -o -6 route show table all 2>/dev/null)"

  for interface_path in /sys/class/net/*; do
    [[ -e $interface_path ]] || continue
    interface="${interface_path##*/}"
    flags="$(<"$interface_path/flags")"
    (( flags & 1 )) || continue

    if [[ ! -e $interface_path/tun_flags &&
          ! " $wireguard_interfaces " =~ [[:space:]]$interface[[:space:]] &&
          ! $interface =~ ^(ppp|wg|vpn|tailscale|ipsec|xfrm|vti|zt|nordlynx)[0-9_-] ]]; then
      continue
    fi

    if awk -v interface="$interface" '
      $1 !~ /^(local|broadcast|unreachable|prohibit|blackhole)$/ {
        for (i = 1; i < NF; i++)
          if ($i == "dev" && $(i + 1) == interface)
            found = 1
      }
      END { exit !found }
    ' <<<"$routes"; then
      tunnel_interfaces+=("$interface")
    fi
  done

  printf '%s' "${tunnel_interfaces[*]}"
}

tunnel_interfaces="$(detect_tunnel_interfaces)"

if (( connected_count == 0 )) && [[ -z $tunnel_interfaces ]]; then
  if $vortix_available; then
    emit "" "$(printf 'Vortix disconnected\nKill switch: %s (%s)' "$killswitch_mode" "$killswitch_state")" "disconnected"
  else
    emit "" "No active VPN tunnel" "disconnected"
  fi
fi

profile_name="$(jq -r '.name // .profile // .profile_name // .interface // .id // empty' <<<"$connection_json" 2>/dev/null || true)"
if [[ -z "$profile_name" || "$profile_name" == "null" ]]; then
  profile_name="${tunnel_interfaces%% *}"
  [[ -n "$profile_name" ]] || profile_name="VPN"
fi

state="$(jq -r '.state // .status // empty' <<<"$connection_json" 2>/dev/null || true)"
if [[ -z "$state" || "$state" == "null" ]]; then
  state="connected"
fi

exit_state="$(jq -r '.exit // .exit_state // .exit_status // .exit_node // .egress // empty' <<<"$connection_json" 2>/dev/null || true)"
public_ipv4="$(jq -r '.public_ipv4 // .ipv4 // .public_ip // empty' <<<"$connection_json" 2>/dev/null || true)"
public_ipv6="$(jq -r '.public_ipv6 // .ipv6 // empty' <<<"$connection_json" 2>/dev/null || true)"

if (( connected_count > 0 )); then
  tooltip_lines=(
    "Vortix: ${profile_name}"
    "State: ${state}"
    "Connections: ${connected_count}"
    "Kill switch: ${killswitch_mode} (${killswitch_state})"
  )

  if [[ -n "$exit_state" && "$exit_state" != "null" ]]; then
    tooltip_lines+=("Exit: ${exit_state}")
  else
    tooltip_lines+=("Exit: split tunnel / LAN access")
  fi
else
  tooltip_lines=(
    "VPN: ${profile_name}"
    "State: ${state}"
  )
fi

if [[ -n "$public_ipv4" && "$public_ipv4" != "null" ]]; then
  tooltip_lines+=("Public IPv4: ${public_ipv4}")
fi

if [[ -n "$public_ipv6" && "$public_ipv6" != "null" ]]; then
  tooltip_lines+=("Public IPv6: ${public_ipv6}")
fi

if [[ -n $tunnel_interfaces ]]; then
  tooltip_lines+=("Tunnel: ${tunnel_interfaces}")
fi

tooltip="$(printf '%s\n' "${tooltip_lines[@]}")"

case "$state" in
  *drop*|*fail*|*error*|*disconnect*)
    emit "󰦝!" "$tooltip" "warning"
    ;;
  *)
    emit "󰖂 ${profile_name}" "$tooltip" "connected"
    ;;
esac
