#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

SYSTEM_SERVICES=("NetworkManager.service")
USER_SERVICES=(
  "elephant.service"
  "solace-recover-internal-monitor.service"
  "swayosd-server.service"
)

for service_name in "${SYSTEM_SERVICES[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: sudo systemctl enable --now $service_name"
  else
    run_cmd sudo systemctl enable --now "$service_name"
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: systemctl --user daemon-reload"
else
  systemctl --user daemon-reload || warn "Could not reload user systemd manager; user services will be picked up after login."
fi

for service_name in "${USER_SERVICES[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: systemctl --user enable $service_name"
  else
    systemctl --user enable "$service_name" || warn "Could not enable user service: $service_name"
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: systemctl --user enable --now solace-battery-monitor.timer if a battery is present"
elif compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
  systemctl --user enable --now solace-battery-monitor.timer || warn "Could not enable battery monitor timer."
fi

log "System and user services configured."
