#!/bin/bash
set -x
cd /tmp/
tar xvf ~/binli-linux.tar.gz
sudo cp boot/$kernel_name /boot/
sudo cp -r lib/modules/* /lib/modules/
