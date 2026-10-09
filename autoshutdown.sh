#!/bin/bash
# autoshutdown.sh
# automatically shutdown the system to check sth from backend script
#
# Usage:
#  ./autoshutdown.sh 30 vblank-wait/backend.sh

USER=$(whoami)

if command -v gnome-terminal &> /dev/null; then
    TERMINAL=gnome-terminal
elif command -v ptyxis &> /dev/null; then
    TERMINAL=ptyxis
else
    echo "No terminal emulator found. Please install gnome-terminal or ptyxis."
    exit 1
fi

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
function quit_shutdown() {
    if [ -f "/etc/gdm3/custom.conf.bak" ]; then
        sudo cp /etc/gdm3/custom.conf.bak /etc/gdm3/custom.conf
    fi
    if [ -f "/home/$USER/.config/autostart/autoshutdown.desktop" ]; then
        rm -f /home/$USER/.config/autostart/autoshutdown.desktop
    fi
    if [ -f "/home/$USER/autoshutdown.sh" ]; then
        rm -f /home/$USER/autoshutdown.sh
    fi
    if [ -f "/home/$USER/$BACKEND" ]; then
        rm -f /home/$USER/$BACKEND
    fi
    rm -f /home/$USER/autoshutdown_times.txt
    exit 0
}

# check if the argument is empty
if [ -z "$1" ]; then
    echo "Usage: $0 <number> <backend script>"
    exit 1
fi
TIMES=$1
BACKEND=$2

# check if the argument is greater than 0
# if not, exit
if [ "$TIMES" -eq 0 ]; then
    echo "Finish testing..."
    if [ -f failrate.txt ]; then
        failrate=$(cat failrate.txt)
        total=$(cat /home/$USER/autoshutdown_times.txt)
        echo "Fail rate: $failrate / $total"
        rm -f failrate.txt
    fi
    quit_shutdown
fi

if [ ! -f "/home/$USER/.config/autostart/autoshutdown.desktop" ]; then
    enable_autologin
    if [ ! -f "/home/$USER/autoshutdown.sh" ]; then
        cp $0 /home/$USER/autoshutdown.sh
        cp -r $BACKEND /home/$USER/
    fi
    if [ ! -d "/home/$USER/.config/autostart" ]; then
        mkdir -p /home/$USER/.config/autostart
    fi
    cat <<EOF | tee /home/$USER/.config/autostart/autoshutdown.desktop > /dev/null
[Desktop Entry]
Type=Application
Exec=/usr/bin/$TERMINAL --maximize -- /bin/bash -c "cd /home/$USER ; ./autoshutdown.sh $TIMES ${BACKEND##*/} ; exec bash"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=autoshutdown
Comment=autoshutdown
EOF
    echo "Shutdown... $TIMES"
    echo "$TIMES" > /home/$USER/autoshutdown_times.txt
    sleep 1
    sudo rtcwake -m no -s 30
    sudo systemctl poweroff -i
    exit 0
fi

# decrease the shutdown times by 1
sed -i "s/autoshutdown.sh $TIMES/autoshutdown.sh $(( $TIMES - 1 ))/g" /home/$USER/.config/autostart/autoshutdown.desktop
echo "Shutdown... $TIMES"
if [ -x "$BACKEND" ]; then
    echo "Call backend script: $BACKEND"
    # get the backend return value
    # if the return value is not 0, record failrate
    /home/$USER/$BACKEND
    if [ $? -ne 0 ]; then
        failrate=$(cat failrate.txt)
        if [ -z "$failrate" ]; then
            failrate=1
        else
            failrate=$((failrate + 1))
        fi
        echo "$failrate" > failrate.txt
        echo "Backend script failed"
    fi
fi

sleep 3
# warm boot or cold boot with rtcwake
sudo rtcwake -m no -s 30
sudo systemctl poweroff -i
exit 0
