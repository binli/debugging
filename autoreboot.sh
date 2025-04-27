#!/bin/bash
# autoreboot.sh
# automatically reboot the system to check sth from backend script
#
# Usage:
#  ./autoreboot.sh 30 vblank-wait/backend.sh

USER=$(whoami)

# the func to check autologin
function enable_autologin() {
    # only effect on the default custom.conf file
    if grep -q '#  AutomaticLoginEnable = true' /etc/gdm3/custom.conf; then
        echo "Autologin is not enabled"
        sudo cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.bak
        sudo sed -i "s/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/g" /etc/gdm3/custom.conf
        sudo sed -i "s/#  AutomaticLogin = user1/AutomaticLogin = ${USER}/g" /etc/gdm3/custom.conf
    fi
}

# the func to restore custom.conf
function quit_reboot() {
    if [ -f "/etc/gdm3/custom.conf.bak" ]; then
        sudo cp /etc/gdm3/custom.conf.bak /etc/gdm3/custom.conf
    fi
    if [ -f "/home/$USER/.config/autostart/autoreboot.desktop" ]; then
        rm -f /home/$USER/.config/autostart/autoreboot.desktop
    fi
    if [ -f "/home/$USER/autoreboot.sh" ]; then
        rm -f /home/$USER/autoreboot.sh
    fi
    if [ -f "/home/$USER/$BACKEND" ]; then
        rm -f /home/$USER/$BACKEND
    fi
    rm -f /home/$USER/autoreboot_times.txt
    exit 0
}

# check if the argument is empty
if [ -z "$1" ]; then
    echo "Usage: $0 <number> <backend script>"
    exit 1
fi
TIMES=$1{1:-30}
BACKEND=$2

# check if the argument is greater than 0
# if not, exit
if [ "$TIMES" -eq 0 ]; then
    echo "Finish testing..."
    if [ -f failrate.txt ]; then
        failrate=$(cat failrate.txt)
        total=$(cat /home/$USER/autoreboot_times.txt)
        echo "Fail rate: $failrate / $total"
        rm -f failrate.txt
    fi
    quit_reboot
fi

if [ ! -f "/home/$USER/.config/autostart/autoreboot.desktop" ]; then
    enable_autologin
    if [ ! -f "/home/$USER/autoreboot.sh" ]; then
        cp $0 /home/$USER/autoreboot.sh
        cp -r $BACKEND /home/$USER/
    fi
    if [ ! -d "/home/$USER/.config/autostart" ]; then
        mkdir -p /home/$USER/.config/autostart
    fi
    cat <<EOF | tee /home/$USER/.config/autostart/autoreboot.desktop > /dev/null
[Desktop Entry]
Type=Application
Exec=/usr/bin/gnome-terminal --maximize -- /bin/bash -c "cd /home/$USER ; ./autoreboot.sh $TIMES ${BACKEND##*/} ; exec bash"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=autoreboot
Comment=autoreboot
EOF
    echo "First rebooting..."
    echo "$TIMES" > /home/$USER/autoreboot_times.txt
    sleep 1
    reboot
    exit 0
fi

# decrease the reboot times by 1
sed -i "s/autoreboot.sh $TIMES/autoreboot.sh $(( $TIMES - 1 ))/g" /home/$USER/.config/autostart/autoreboot.desktop
echo "Rebooting... $TIMES"
if [ -x "$BACKEND" ]; then
    echo "Call backend script: $BACKEND"
    # get the backend return value
    # if the return value is not 0, exit for debugging
    # if the return value is 0, reboot the system
    /home/$USER/$BACKEND
fi

sleep 3
#reboot
sudo rtcwake -m off -s 10
exit 0
