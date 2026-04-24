#!/usr/bin/env bash
# Add kernel debug parameters to GRUB configuration
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"ignore_loglevel initcall_debug no_console_suspend log_buf_len=256M rootwait\"/g" /etc/default/grub
# Update GRUB configuration
sudo update-grub
