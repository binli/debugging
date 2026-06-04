#!/usr/bin/env bash
#sudo apt install libncurses5-dev flex bison libelf-dev libssl-dev pahole
set -x
kernel_name="vmlinuz-binli"
hostpc="Lun2-AMD-SIT25.local"
ncpus=$(grep ^siblings /proc/cpuinfo | uniq |  awk '{print $3}')
# ncpus=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
# ncpus=8
echo "Using ($ncpus) cpus"
make O=../obj-linux/ -j$ncpus clean > /dev/null

if [ ! -e debian/canonical-certs.pem ]; then
  cp /work/init/canonical*.pem debian/
fi

rm ../obj-linux/arch/x86_64/boot/bzImage
rm -rf ~/mods/lib/modules/ ~/mods/boot/$kernel_name ~/mods/binli-linux.tar.gz

make O=../obj-linux/ -j$ncpus menuconfig
time make O=../obj-linux/ -j$ncpus
make O=../obj-linux/ -j$ncpus modules_install INSTALL_MOD_PATH=~/mods/ INSTALL_MOD_STRIP=1  > /dev/null

#moddir=`ls ~/mods/lib/modules/ | head`
#sudo rm -rf /boot/vmlinuz-6.0.0-binli /lib/modules/$moddir
mkdir -p ~/mods/boot
if [ -e ../obj-linux/arch/x86_64/boot/bzImage ]; then 
  cp ../obj-linux/arch/x86_64/boot/bzImage ~/mods/boot/$kernel_name
  tar -czvf ~/mods/binli-linux.tar.gz -C ~/mods/ boot/ lib/
  scp ~/mods/binli-linux.tar.gz u@$hostpc:~/
fi
