# debugging
 * at-probe : Sent the 'AT<CR><LF>' to modem device, it simulates ModemManager(1.16.6) to probe modem devices, it could cause ACPI storm on 8086:7560.
 * ./suspend.sh 30 camera-lost/checkvideo.sh
 * `./autoboot.sh <cold|warm> <count> [backend]` repeats power cycles, checking the optional backend after each boot. Cold schedules an RTC wake before `systemctl poweroff -i`; warm uses `systemctl reboot -i` without an RTC wake. Run state and backend output are kept in `~/autoboot_run`.
