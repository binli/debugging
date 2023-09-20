### Enable debug mode for thinkpad_acpi
./debug.sh

### Get the latest thinkpad_acpi
From below link or the one from the your kernel source.

```bash
curl -s https://raw.githubusercontent.com/torvalds/linux/master/drivers/platform/x86/thinkpad_acpi.c > thinkpad_acpi.c
curl -s https://raw.githubusercontent.com/torvalds/linux/master/drivers/platform/x86/dual_accel_detect.h > dual_accel_detect.h
```

### Compile the thinkpad_acpi and load it
```bash
make
sudo rmmod thinkpad_acpi
sudo insmod thinkpad_acpi.ko
sudo dmesg | tail -n 40
```

### clean the thinkpad_acpi
```
make clean
```
