#!/bin/bash
# Enable the debug mode for fprintd
sudo cp override.conf /etc/systemd/system/fprintd.service.d/
sudo chown root:root /etc/systemd/system/fprintd.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart fprintd.service
journalctl -u fprintd.service | tee fprintd-debug.log
