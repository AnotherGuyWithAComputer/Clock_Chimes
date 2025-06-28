#!/usr/bin/env bash
# clock_chimes_suspend_installer.sh
# Clock Chimes Suspend & Resmue service installer

if [ -e $(which systemctl) ]; then
    installPATH_XDG_CONFIG_HOME="$HOME/.config"
    systemdPATH="/etc/systemd/system/"
    clock_chimes_path="$(grep ExecStart "$installPATH_XDG_CONFIG_HOME"/systemd/user/clock_chimes.service | sed -e 's/ExecStart=//')"

    echo "Installing Clock Chimes Suspend & Resmue services."
    sudo install -v -o "$USER" -g "$(id -gn)" -m 640 clock_chimes_suspend.service clock_chimes_resume.service \
        "$systemdPATH/"

    echo "Configuring service."
    sudo sed -i -e "s|/home/user/bin/clock_chimes.sh|$clock_chimes_path|" -e "s|/home/user/.config|$installPATH_XDG_CONFIG_HOME|" "$systemdPATH"/clock_chimes_suspend.service
    sudo sed -i -e "s|/home/user/bin/clock_chimes.sh|$clock_chimes_path|" -e "s|/home/user/.config|$installPATH_XDG_CONFIG_HOME|" "$systemdPATH"/clock_chimes_resume.service

    echo "Registering services."
    sudo systemctl daemon-reload
    sudo systemctl enable "$systemdPATH"/clock_chimes_suspend.service
    sudo systemctl enable "$systemdPATH"/clock_chimes_resume.service

    echo "Clock Chimes Suspend & Resume service installer has finished."
else
    echo "Error: Could not detect systemd. Installation could not proceed."
    exit 1
fi
