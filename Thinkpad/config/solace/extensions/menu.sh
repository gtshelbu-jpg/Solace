# Overwrite parts of the solace-menu with user-specific submenus.
# See $SOLACE_PATH/bin/solace-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when Solace changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) solace-lock-screen ;;
#   *Shutdown*) solace-cmd-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
