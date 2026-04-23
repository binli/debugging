#!/bin/bash
# sudo apt install debhelper-compat flex bison libssl-dev libelf-dev kernel-wedge pkg-config liblz4-tool tmux libncurses5-dev libcap-dev gawk gcc-13 dkms pahole cpio libdwarf-dev libdw-dev rustc rust-src bindgen rustfmt rust-clippy bc

time env CONCURRENCY_LEVEL=16 sh -c 'fakeroot debian/rules clean && debian/rules build-oem do_dkms_nvidia=false do_zfs=false do_tools=0 no_dumpfile=1 do_dkms_vbox=false do_v4l2loopback=false && fakeroot debian/rules binary-oem binary-headers do_dkms_nvidia=false do_zfs=false do_tools=0 no_dumpfile=1 do_dkms_vbox=false do_v4l2loopback=false' 2>&1 | tee build.log
