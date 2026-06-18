# Solace Alpha Install Guide

## Disclaimer

**This is a super alpha build of Solace, my personal Arch dotfiles and OS project inspired by and based on Omarchy. You will run into issues, there will be problems, and I don't recommend this project to anyone not already familiar with Arch and Hyprland. I've put together a gum guide that will do its best to guide you through usage and configuration. It will come up on the first install, and it's accessible through the Learn section in the system menu.**

*For quick monitor configuration, use the Solace DisplayLink Waybar widget in the top right. Clicking it will open Hyprmon, a nice little TUI for Hyprland monitor configuration.*

## Solace Things To Know

- Solace is built around a normal upstream Arch install, then bootstraps the Hyprland desktop, themes, apps, services, and helper scripts on top.
- The current ISO path is still intentionally simple: boot the live image, run `solace-install`, use `archinstall`, then let Solace stage the desktop bootstrap for first login.
- Solace includes a system menu, theme picker, first-run guide, screenshot workflow, Hyprland/Waybar configuration, Aether-backed theme sync, and a bunch of helper commands for the desktop experience.
- This is not meant to hide Arch from you. It tries to give you a friendly path through the install, but this is still Arch underneath, and you should be comfortable fixing Arch things when they happen.

## Install Instructions

1. Flash the ISO to a stick and boot the live image on your desired machine connected to Ethernet.
2. Enter the Arch install medium and run `solace-install`.
3. From `solace-install`, read the install guide.
4. Once you've read and understand the install instructions, return to the `solace-install` menu and enter `archinstall`.
5. Go through `archinstall` and set up the system with a minimum of these config changes: mirror locations, root password set, add user account, set user password, and add the user to sudoers. Solace sets certain defaults for best compatibility, so try not to change those.
6. Let `archinstall` run. Once it finishes, **do not reboot**. Instead, exit `archinstall`. Once you're back in the `solace-install` menu, you must let it copy over the bootstrap installers. Once `solace-install` prompts you to reboot, you are good to do so.
7. Once booted into Arch, log in to your user account and enter `y` to start the Solace bootstrap installer.
   - After about the third password prompt, not including login, you can walk away if needed. The rest of the installer can proceed without user input, if there is no catastrophic failure. This is an alpha.
8. After you've been put back into your shell and Solace says the install ran successfully, you can reboot.
9. Congratulations. You're done. Welcome to Solace. There is a first-time startup guide waiting for you.

## Before You Wipe A Real Machine

- Back up your home folder and anything you would be upset to lose.
- Keep a known-good recovery USB nearby.
- Make sure you know how to get back into your firmware boot menu.
- If you dual boot, pay very close attention in `archinstall`. Solace is not responsible for choosing the right disk or partition layout for you.
- If something breaks, assume it is fixable before assuming the install is dead. This project is young, but most issues so far have been narrow handoff problems, not the whole desktop falling apart.
