#!/bin/bash
# Enable the debug mode for fprintd
# At the second time, it will disable the debug mode.
# Usage:
# ./debug.sh
if [ -e /etc/systemd/system/fprintd.service.d/override.conf ]; then
    echo "*** Disable debug mode. ***"
    sudo rm /etc/systemd/system/fprintd.service.d/override.conf
    sudo systemctl daemon-reload
    sudo systemctl restart fprintd.service
    exit 0
fi

sudo mkdir -p /etc/systemd/system/fprintd.service.d/
sudo cp override.conf /etc/systemd/system/fprintd.service.d/
sudo chown root:root /etc/systemd/system/fprintd.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart fprintd.service
echo -e "*** Debug mode enabled. *** Please reproduce the issue and press Ctrl+C to stop, then upload the fprintd-debug.log to bug.\n"
journalctl -u fprintd.service -f | tee fprintd-debug.log
