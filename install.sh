#!/usr/bin/env bash
#
# USAGE
#   INSTALLATION INSTRUCTIONS
#   To install the script, sound files and systemd components, run one of the
#   commands which follow:
#       - bash ./install.sh
#       - bash ./install.sh install
#
#   REMOVAL INSTRUCTIONS
#   To uninstall or remove the script and all parts, run:
#       bash ./install.sh uninstall
#
# NOTES
#   - If using cron for scheduling, administrative rights will be necessary to
#   write to /etc/cron.d/.
#
#   - The installer only has partial support for the XDG Base directory scheme.
#     Paths to the XDG_CONFIG_HOME and XDG_DATA_HOME directories are hard coded.
#
# ----------------------------------------------------------------------------
# Configuration
installPATH_XDG_CONFIG_HOME="$HOME/.config"
installPATH_XDG_DATA_HOME="$HOME/.local/share"
installPATH_bin_dir=""

# ----------------------------------------------------------------------------
# Main Program execution begins here
# Inputs: None
# Work: Determine whether program execution should display help, install or
# remove software components.
# Output: Messages related to which function is run
# ----------------------------------------------------------------------------
function main() {
  case "$1" in
  "-h" | help)
    echo -e "\n\n\033[1mClock Chimes Installer Help\n\n\033[0m"
    echo -e "\033[1mInstallation\n\033[0m"
    echo -e "To install Clock Chimes, run: \n\tbash ./install.sh install\n"
    echo -e "\n\033[1mRemoval\n\033[0m"
    echo -e "To remove or uninstall Clock Chimes, run: \n\tbash ./install.sh uninstall\n\n"
    ;;
  "" | install)
    echo -e "\n\n\033[1mClock Chimes Install Script\n\n\033[0m"
    if [ "$installPATH_bin_dir" == "-1" ]; then
      installPATH_bin_dir="$HOME/bin"
      mkdir -v -p "$installPATH_bin_dir"
    fi
    # Determine if we are using systemd or cron scheduling
    if [ -e $(which systemctl) ]; then
      # Install systemd timer components
      echo "Installing systemd service and timer."
      mkdir -v -p "$installPATH_XDG_CONFIG_HOME"/systemd/user
      install -v -o "$USER" -g "$(id -gn)" -m 640 clock_chimes.timer \
        clock_chimes.service \
        "$installPATH_XDG_CONFIG_HOME"/systemd/user
      # Update paths within config to match actual used paths
      echo "Configuring service."
      sed -i "s|/home/user/bin|$installPATH_bin_dir|" "$installPATH_XDG_CONFIG_HOME"/systemd/user/clock_chimes.service
      # Register components
      echo "Registering service."
      systemctl --user daemon-reload
      systemctl --user enable clock_chimes.timer clock_chimes.service
      systemctl --user start clock_chimes.timer
    elif [ -e $(which cron) ]; then
      # Install cron script
      echo "Installing cron script."
      sudo install -v -o "root" -g "root" -m 644 clock_chimes.cron /etc/cron.d
      echo "Configuring cron script ."
      sudo sed -i -e "s|/home/user/bin|$installPATH_bin_dir|g" -e "s|root|$USER|" /etc/cron.d/clock_chimes.cron
    else
      echo "Error: Could not detect systemd or cron. Installation could not proceed."
      exit 0
    fi
    # Install sound files
    echo "Installing sound files."
    mkdir -v -p "$installPATH_XDG_DATA_HOME"/sounds/chimes
    install -v -o "$USER" -g "$(id -gn)" -m 644 \
      chimes/chime-final.mp3 \
      chimes/chime.mp3 \
      chimes/Westminster_Half.mp3 \
      chimes/Westminster_Hour.mp3 \
      chimes/Westminster_Quarter.mp3 \
      chimes/Westminster_Three_Quarter.mp3 \
      "$installPATH_XDG_DATA_HOME"/sounds/chimes
    # Install config files
    echo "Installing config files."
    mkdir -v -p "$installPATH_XDG_CONFIG_HOME"/chimes
    install -v -o "$USER" -g "$(id -gn)" -m 644 \
      clock_chimes.config \
      clock_chimes.config.dist \
      "$installPATH_XDG_CONFIG_HOME"/chimes
    # Install script file
    install -v -o "$USER" -g "$(id -gn)" -m 750 clock_chimes.sh "$installPATH_bin_dir/"
    echo -e "\n\n\033[1mClock Chimes Installed\n\n\033[0m"
    # "$installPATH_bin_dir/clock_chimes.sh" -r
    ;;
  uninstall)
    echo -e "\n\n\033[1mClock Chimes Uninstall Script\n\n\033[0m"
    # Unregister systemd timer components
    if [ -e $(which systemctl) ]; then
      systemctl --user daemon-reload
      systemctl --user stop clock_chimes.timer clock_chimes.service
      systemctl --user disable clock_chimes.timer clock_chimes.service
      systemctl --user daemon-reload
      # Begin nested if statement
      if [ -e "$installPATH_XDG_CONFIG_HOME/systemd/user/clock_chimes_suspend.service" ]; then
        sudo systemctl stop clock_chimes_suspend.service
        sudo systemctl disable clock_chimes_suspend.service
        rm -v "$installPATH_XDG_CONFIG_HOME/systemd/user/clock_chimes_suspend.service"
        sudo systemctl daemon-reload
      fi
      if [ -e "$installPATH_XDG_CONFIG_HOME/systemd/user/clock_chimes_resume.service" ]; then
        sudo systemctl stop clock_chimes_resume.service
        sudo systemctl disable clock_chimes_resume.service
        rm -v "$installPATH_XDG_CONFIG_HOME/systemd/user/clock_chimes_resume.service"
        sudo systemctl daemon-reload
      fi
      # End nested if statement
    fi
    # Check for and remove systemd timer, service and cron script.
    echo "Removing service files."
    rm -fv "$installPATH_XDG_CONFIG_HOME"/systemd/user/{clock_chimes.timer,clock_chimes.service}
    sudo rm -fv /etc/cron.d/clock_chimes.cron
    # Remove sound files
    echo "Removing sound files."
    rm -v "$installPATH_XDG_DATA_HOME"/sounds/chimes/{chime-final,chime,Westminster_Half,Westminster_Hour,Westminster_Quarter,Westminster_Three_Quarter}.mp3
    rm -vd "$installPATH_XDG_DATA_HOME"/sounds/chimes
    # Remove config files
    echo "Removing configuration files."
    rm -fv "$installPATH_XDG_CONFIG_HOME"/chimes/clock_chimes{.config,.config.dist}
    rm -vd "$installPATH_XDG_CONFIG_HOME"/chimes
    # Remove script file
    if [ -e "$installPATH_bin_dir/clock_chimes.sh" ]; then
      echo "Removing script file."
      rm -v "$installPATH_bin_dir"/clock_chimes.sh
    elif [ "$installPATH_bin_dir" == "-1" ]; then
      echo "Failed to locate script file."
    else
      echo "Failed to locate script file at expected location: $installPATH_bin_dir/clock_chimes.sh"
      echo "Attempting alternate locations."
      rm -v "$HOME/.local/bin/clock_chimes.sh" "$HOME/.bin/clock_chimes.sh" "$HOME/bin/clcock_chimes.sh"
    fi
    echo -e "\n\n\033[1mClock Chimes Removed\n\n\033[0m"
    ;;
  esac
}

# ----------------------------------------------------------------------------
# Function configure_installPATH_bin_dir
# Inputs: None
# Work: Determine path to use for installPATH_bin_dir
# Output: None
# ----------------------------------------------------------------------------
function configure_installPATH_bin_dir() {
  if [ -e "$HOME/.local/bin" ]; then
    installPATH_bin_dir="$HOME/.local/bin"
  elif [ -e "$HOME/.bin" ]; then
    installPATH_bin_dir="$HOME/.bin"
  elif [ -e "$HOME/bin" ]; then
    installPATH_bin_dir="$HOME/bin"
  else
    installPATH_bin_dir="-1"
  fi
  echo "$installPATH_bin_dir"
}
# ----------------------------------------------------------------------------

if [ -z "$installPATH_bin_dir" ]; then
  installPATH_bin_dir="$(configure_installPATH_bin_dir)"
fi

main "$@"
