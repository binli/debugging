#!/bin/bash
# autoshutdown.sh
# automatically shutdown the system to check sth from backend script
#
# Usage:
#  ./autoshutdown.sh 30 journalctl/lastboot.sh
# Run files and backend output are kept in ~/autoshutdown_run.

USER=$(whoami)
RUN_DIR="$HOME/autoshutdown_run"
AUTOSTART="$HOME/.config/autostart/autoshutdown.desktop"

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
        sudo cp /etc/gdm3/custom.conf "$RUN_DIR/custom.conf.bak" || return 1
        sudo sed -i "s/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/g" /etc/gdm3/custom.conf || return 1
        sudo sed -i "s/#  AutomaticLogin = user1/AutomaticLogin = ${USER}/g" /etc/gdm3/custom.conf || return 1
    fi
}

# the func to restore custom.conf
function quit_shutdown() {
    if [ -f "$RUN_DIR/custom.conf.bak" ]; then
        sudo cp "$RUN_DIR/custom.conf.bak" /etc/gdm3/custom.conf || return 1
    fi
    if [ -e /etc/sudoers.d/nopasswd ]; then
        sudo rm -f /etc/sudoers.d/nopasswd || return 1
    fi
    rm -f -- "$AUTOSTART" || return 1
    read -p "Do you want to delete the run directory $RUN_DIR? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        rm -rf -- "$RUN_DIR" || return 1
    fi
    exit 0
}

# check if the argument is empty
if [ -z "$1" ]; then
    echo "Usage: $0 <number> [backend script]"
    exit 1
fi
TIMES=$1
BACKEND=$2

if ! [[ $TIMES =~ ^[0-9]+$ ]]; then
    echo "Shutdown count must be a non-negative integer." >&2
    exit 1
fi

# check if the argument is greater than 0
# if not, exit
if [ "$TIMES" -eq 0 ]; then
    echo "Finish testing..."
    if [ -f "$RUN_DIR/failrate.txt" ]; then
        failrate=$(cat "$RUN_DIR/failrate.txt")
        total=$(cat "$RUN_DIR/autoshutdown_times.txt")
        echo "Fail rate: $failrate / $total"
    fi
    quit_shutdown
fi

if [ ! -f "$AUTOSTART" ]; then
    if [ -e "$RUN_DIR" ]; then
        echo "Run dir file already exists: $RUN_DIR" >&2
        exit 1
    fi
    if [ ! -e /etc/sudoers.d/nopasswd ]; then
        printf '%%sudo ALL=(ALL:ALL) NOPASSWD: ALL\n' | sudo install -m 0440 /dev/stdin /etc/sudoers.d/nopasswd || exit 1
    fi
    if ! sudo -k -n true; then
        echo "Passwordless sudo is required for automatic shutdown." >&2
        exit 1
    fi
    mkdir -p -- "$RUN_DIR" || exit 1
    if ! cp -- "$0" "$RUN_DIR/autoshutdown.sh" || ! cp -- "$BACKEND" "$RUN_DIR/backend.sh"; then
        rm -f -- "$RUN_DIR/autoshutdown.sh" "$RUN_DIR/backend.sh"
        exit 1
    fi
    enable_autologin || exit 1
    mkdir -p -- "$HOME/.config/autostart" || exit 1
    cat > "$AUTOSTART" <<EOF || exit 1
[Desktop Entry]
Type=Application
Exec=/usr/bin/$TERMINAL --maximize -- /bin/bash -c "cd $RUN_DIR ; ./autoshutdown.sh $TIMES backend.sh ; cd ; exec bash"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=autoshutdown
Comment=autoshutdown
EOF
    echo "Shutdown... $TIMES"
    echo "$TIMES" > "$RUN_DIR/autoshutdown_times.txt" || exit 1
    sleep 1
    sudo rtcwake -m no -s 30 || exit 1
    sudo systemctl poweroff -i
    exit 0
fi

if [ ! -x "$RUN_DIR/backend.sh" ]; then
    echo "Backend script is missing or not executable: $RUN_DIR/backend.sh" >&2
    exit 1
fi
cd "$RUN_DIR" || exit 1

# decrease the shutdown times by 1
sed -i "s/autoshutdown.sh $TIMES/autoshutdown.sh $(( $TIMES - 1 ))/g" "$AUTOSTART" || exit 1
echo "Shutdown... $TIMES"
echo "Call backend script: $RUN_DIR/backend.sh"
# get the backend return value
# if the return value is not 0, record failrate
if [ -x "$RUN_DIR/backend.sh" ]; then
    "$RUN_DIR/backend.sh"
    if [ $? -ne 0 ]; then
        failrate=$(cat $RUN_DIR/failrate.txt)
        if [ -z "$failrate" ]; then
            failrate=1
        else
            failrate=$((failrate + 1))
        fi
        echo "$failrate" > $RUN_DIR/failrate.txt
        echo "Backend script failed"
    fi
else
    echo "Backend script is not executable: $RUN_DIR/backend.sh" >&2
fi

sleep 3
# cold boot with rtcwake
sudo rtcwake -m no -s 30 || exit 1
sudo systemctl poweroff -i
exit 0
