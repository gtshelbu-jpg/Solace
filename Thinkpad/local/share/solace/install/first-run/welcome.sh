#!/usr/bin/env bash

if command -v solace-welcome >/dev/null 2>&1; then
  solace-welcome --force
else
  notify-send "Welcome to Solace" "Super + K opens keybindings. Super + Space opens the app launcher." -u critical
fi
