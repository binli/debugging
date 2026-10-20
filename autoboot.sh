#!/bin/bash
# autoboot.sh
# automatically shut down or reboot the system to check a backend script
#
# Usage:
#  ./autoboot.sh cold 30 journalctl/lastboot.sh
#  ./autoboot.sh warm 30 journalctl/lastboot.sh
# Run files and backend output are kept in ~/autoboot_run.

USER=$(whoami)
RUN_DIR="$HOME/autoboot_run"
AUTOSTART="$HOME/.config/autostart/autoboot.desktop"
SUDOERS="/etc/sudoers.d/autoboot"

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

function rollback_setup() {
    local status=$?
    local cleanup_failed=0
    trap - EXIT
    if [ "$status" -ne 0 ]; then
        echo "Autoboot setup failed; restoring previous configuration." >&2
        if [ -f "$RUN_DIR/custom.conf.bak" ]; then
            sudo cp "$RUN_DIR/custom.conf.bak" /etc/gdm3/custom.conf || {
                echo "Failed to restore GDM configuration." >&2
                cleanup_failed=1
            }
        fi
        if [ "$SUDOERS_CREATED" -eq 1 ]; then
            sudo rm -f "$SUDOERS" || {
                echo "Failed to remove $SUDOERS." >&2
                cleanup_failed=1
            }
        fi
        if [ "$AUTOSTART_CREATED" -eq 1 ]; then
            rm -f -- "$AUTOSTART" || {
                echo "Failed to remove $AUTOSTART." >&2
                cleanup_failed=1
            }
        fi
        if [ "$RUN_DIR_CREATED" -eq 1 ]; then
            if [ "$cleanup_failed" -eq 0 ]; then
                rm -rf -- "$RUN_DIR" || echo "Failed to remove $RUN_DIR." >&2
            else
                echo "Kept $RUN_DIR for manual recovery." >&2
            fi
        fi
    fi
}

# the func to restore custom.conf
function quit_boot() {
    if [ -f "$RUN_DIR/custom.conf.bak" ]; then
        sudo cp "$RUN_DIR/custom.conf.bak" /etc/gdm3/custom.conf || return 1
    fi
    sudo rm -f "$SUDOERS"
    rm -f -- "$AUTOSTART"
    read -p "Do you want to delete the run directory $RUN_DIR? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        rm -rf -- "$RUN_DIR" || return 1
    fi
    exit 0
}

function auto_boot() {
    if [ "$MODE" = "cold" ]; then
        sudo rtcwake -m no -s 30 || return 1
        sudo systemctl poweroff -i
    elif [ "$MODE" = "warm" ]; then
        sudo systemctl reboot -i
    else
        echo "Unknown mode: $MODE" >&2
        exit 1
    fi
}

if [ "$1" = "cold" ] || [ "$1" = "warm" ]; then
    MODE=$1
    shift
else
    echo "Usage: $0 [cold|warm] <number> [backend script]" >&2
    exit 1
fi
if [ -z "$1" ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 [cold|warm] <number> [backend script]" >&2
    exit 1
fi
TIMES=$1
BACKEND=$2

if ! [[ $TIMES =~ ^[0-9]+$ ]]; then
    echo "Cycle count must be a non-negative integer." >&2
    exit 1
fi

# check if the argument is greater than 0
# if not, exit
if [ "$TIMES" -eq 0 ]; then
    echo "Finish testing..."
    if [ -f "$RUN_DIR/failrate.txt" ]; then
        failrate=$(cat "$RUN_DIR/failrate.txt")
        total=$(cat "$RUN_DIR/autoboot_times.txt")
        echo "Fail rate: $failrate / $total"
    fi
    quit_boot
fi

if [ ! -f "$AUTOSTART" ]; then
    SUDOERS_CREATED=0
    trap rollback_setup EXIT
    mkdir -p "$RUN_DIR"
    if ! cp -- "$0" "$RUN_DIR/autoboot.sh" ; then
        echo "Failed to copy autoboot.sh to run directory: $RUN_DIR" >&2
        exit 1
    fi
    BACKEND_ARG=""
    if [ -n "$BACKEND" ]; then
        if ! cp -- "$BACKEND" "$RUN_DIR/backend.sh"; then
            echo "Failed to copy backend script: $BACKEND" >&2
            exit 1
        fi
        if [ ! -x "$RUN_DIR/backend.sh" ]; then
            chmod +x "$RUN_DIR/backend.sh" || exit 1
        fi
        BACKEND_ARG=" backend.sh"
    fi
    mkdir -p -- "$HOME/.config/autostart"
    cat > "$AUTOSTART" <<EOF || exit 1
[Desktop Entry]
Type=Application
Exec=/usr/bin/$TERMINAL --maximize -- /bin/bash -c "cd $RUN_DIR ; ./autoboot.sh $MODE $TIMES$BACKEND_ARG ; cd ; exec bash"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=autoboot
Comment=Automatic $MODE boot
EOF
    echo "$MODE... $TIMES"
    echo "$TIMES" > "$RUN_DIR/autoboot_times.txt" || exit 1
    if [ ! -e "$SUDOERS" ]; then
        SUDOERS_CREATED=1
        printf '%%sudo ALL=(ALL:ALL) NOPASSWD: ALL\n' | sudo install -m 0440 /dev/stdin "$SUDOERS" || exit 1
    fi
    if ! sudo -k -n true; then
        echo "Passwordless sudo is required for automatic power cycling." >&2
        exit 1
    fi
    trap - EXIT
    enable_autologin || exit 1
    sleep 1
    auto_boot
    exit $?
fi

sed -i "s/autoboot.sh $MODE $TIMES/autoboot.sh $MODE $(( TIMES - 1 ))/g" "$AUTOSTART" || exit 1
echo "$MODE... $TIMES"
# get the backend return value
# if the return value is not 0, record failrate
if [ -n "$BACKEND" ]; then
    echo "Call backend script: $RUN_DIR/backend.sh"
    "$RUN_DIR/backend.sh"
    if [ $? -ne 0 ]; then
        failrate=""
        if [ -f "$RUN_DIR/failrate.txt" ]; then
            failrate=$(cat "$RUN_DIR/failrate.txt")
        fi
        if [ -z "$failrate" ]; then
            failrate=1
        else
            failrate=$((failrate + 1))
        fi
        echo "$failrate" > "$RUN_DIR/failrate.txt"
        echo "Backend script failed"
    fi
fi

sleep 3
auto_boot
