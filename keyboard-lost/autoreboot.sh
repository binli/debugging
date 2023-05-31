#!/bin/bash
# autoreboot.sh
# automatically reboot the system 30 times
# and check journalctl's result if there is 'Elan TrackPoint' in the output
#
# Usage:
#  ./autoreboot.sh 30

# check if the argument is empty
if [ -z "$1" ]; then
    echo "Usage: $0 <number>"
    exit 1
fi
# check if the argument is greater than 0
# if not, exit
if [ "$1" -le 0 ]; then
    echo "Usage: $0 <number>"
    exit 1
fi

TIMES=$1
USER=$(whoami)
# copy this script into the home directory
if [ ! -f "/home/$USER/autoreboot.sh" ]; then
    cp $0 /home/$USER/autoreboot.sh
fi

# check if the autostart directory exists
if [ ! -d "/home/$USER/.config/autostart" ]; then
    mkdir -p /home/$USER/.config/autostart
fi

# check if the autostart file exists
# if not, create it
if [ ! -f "/home/$USER/.config/autostart/autoreboot.desktop" ]; then
    cat <<EOF | tee /home/$USER/.config/autostart/autoreboot.desktop > /dev/null
[Desktop Entry]
Type=Application
Exec=/usr/bin/gnome-terminal --maximize -- /bin/bash -c "cd /home/$USER ; ./autoreboot.sh $TIMES ; exec bash"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=autoreboot
Comment=autoreboot
EOF
fi

# decrease the reboot times by 1
# if the reboot times is 0, remove the autostart file
# and exit
# if the reboot times is not 0, reboot the system
# and check journalctl's result if there is 'Elan TrackPoint' in the output
# if there is, exit
# if not, continue
# after reboot, the autostart file will be executed again
# and the reboot times will be decreased by 1
if [ "$TIMES" -eq 0 ]; then
    rm -f /home/$USER/.config/autostart/autoreboot.desktop
    exit 0
fi

sed -i "s/autoreboot.sh $TIMES/autoreboot.sh $(( $TIMES - 1 ))/g" /home/$USER/.config/autostart/autoreboot.desktop

if journalctl | grep -q 'Elan TrackPoint'; then
    echo "Elan TrackPoint is still there"
else
    echo "Elan TrackPoint is gone"
    exit 1
fi
echo "Rebooting... $TIMES"
sleep 10
reboot
# End of autoreboot.sh
