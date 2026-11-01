#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Host networking, SSH, VPNs, firewall rules and Docker are not desktop settings.
log "Leaving the existing network stack and network configuration untouched."
USER_SERVICES=(
  "elephant.service"
  "solace-recover-internal-monitor.service"
  "swayosd-server.service"
)
USER_SERVICES_NOW=(
  "hypridle.service"
)

policy="${SOLACE_LID_POLICY:-keep}"
case "$policy" in
  keep) log "Leaving system lid-close policy unchanged.";;
  docked|suspend|awake)
    src="$SCRIPT_DIR/../config/power/lid-$policy.conf"
    dest=/etc/systemd/logind.conf.d/30-solace-lid.conf
    if [[ $DRY_RUN -eq 1 ]]; then
      log "DRY: would install lid policy '$policy' at $dest (effective after reboot)"
    else
      backup_target "$dest"
      run_cmd sudo install -Dm644 "$src" "$dest"
      log "Lid policy takes effect after reboot; logind will not be restarted in this session."
    fi
    ;;
  *) die "Unknown lid policy: $policy";;
esac

power_key=/etc/systemd/logind.conf.d/30-solace-power-key.conf
if [[ ! -e $power_key ]]; then
  run_cmd sudo install -Dm644 "$SCRIPT_DIR/../config/power/power-key.conf" "$power_key"
fi

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

for service_name in "${USER_SERVICES_NOW[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: systemctl --user enable --now $service_name"
  else
    systemctl --user enable --now "$service_name" || warn "Could not enable and start user service: $service_name"
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "DRY: systemctl --user enable --now solace-battery-monitor.timer if a battery is present"
elif compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
  systemctl --user enable --now solace-battery-monitor.timer || warn "Could not enable battery monitor timer."
fi

log "Desktop services configured; unrelated host services preserved."
