# at-probe

 * at-command.c : Sent the 'AT<CR><LF>' to modem device, it simulates ModemManager(1.16.6) to probe modem devices, it could cause ACPI storm on 8086:7560.

```bash
   /* Requires libglib2.0-dev, make, gcc. */
   make
   sudo ./at -d /dev/wwan0mbim0
```

# ACPI storm

In 30 seconds, the interrupts increased about 4w, from 117095 to 154127

```bash
/sys/firmware/acpi/interrupts/gpe32: 117095 EN STS enable
```

And this issue is fixed by below workaround, ane now it's fixed by firmware of XMM7560.

```bash
echo "disable" > /sys/firmware/acpi/interrupts/gpe32
```
