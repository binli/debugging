# SPDX-License-Identifier: GPL-2.0
#
# Makefile for linux/drivers/platform/x86
# x86 Platform-Specific Drivers
#
KVER?= $(shell uname -r)

obj-$(CONFIG_THINKPAD_ACPI)	+= thinkpad_acpi.o

# added for Sutton DKMS
all:
	make -C /lib/modules/$(KVER)/build M=$(shell pwd) modules
clean:
	make -C /lib/modules/$(KVER)/build M=$(shell pwd) clean
