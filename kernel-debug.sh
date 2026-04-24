#!/usr/bin/env bash
# Keep the original GRUB_CMDLINE_LINUX_DEFAULT line as a comment
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/#GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/g" /etc/default/grub
# add a new line with "ignore_loglevel initcall_debug no_console_suspend log_buf_len=256M rootwait"
sudo sed -i "/#GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/a GRUB_CMDLINE_LINUX_DEFAULT=\"ignore_loglevel initcall_debug no_console_suspend log_buf_len=256M rootwait\"" /etc/default/grub
sudo sed -i "s/GRUB_TIMEOUT_STYLE=hidden/#GRUB_TIMEOUT_STYLE=hidden/g" /etc/default/grub
sudo sed -i "s/GRUB_TIMEOUT=0/GRUB_TIMEOUT=3/g" /etc/default/grub
sudo sed -i "s/#GRUB_DISABLE_RECOVERY/a GRUB_DISABLE_SUBMENU=y" /etc/default/grub
# Update GRUB configuration
sudo update-grub
