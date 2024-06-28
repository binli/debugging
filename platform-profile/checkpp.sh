#!/bin/bash
# checkpp.sh backend

# if the return value is not 0, exit for debugging
# if the return value is 0, reboot the system
#
profile=$(cat /sys/firmware/acpi/platform_profile)

if [ -e ~/platform_profile ]; then
	previous_profile=$(cat ~/platform_profile)
else
	cp /sys/firmware/acpi/platform_profile ~/
	previous_profile="$profile"
fi

# the balanced is default mode
if [ "$profile" != "$previous_profile" ]; then
    echo "profile is changed from $previous_profile to $profile!!"
    exit 1
else
    echo "platform_profile is $profile!!"
fi
