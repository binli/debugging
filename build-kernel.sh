#!/usr/bin/env bash
#sudo apt install libncurses5-dev flex bison libelf-dev libssl-dev pahole
set -x
# 7.0.0-oem, 7.0.0-generic
if [ -z "$1" ] ; then
  echo "Usage: install first, then build kernel"
  echo "  $0 install <path-to-kernel-source>"
  echo "  $0 <kernel-version> [hostpc]"
  echo "  $0 7.0.0-oem"
  echo "  $0 7.0.0-generic Lun2-AMD-SIT25.local"
  exit 1
elif [ "$1" == "install" ]; then
  if [ -z "$2" ] ; then
    echo "Usage: $0 install <path-to-kernel-source>"
    exit 1
  fi
  cp build-kernel.sh $2/
  if [ ! -e $2/debian/canonical-certs.pem ]; then
    cp debian/*.pem $2/debian/
  fi
  cd $2
fi
OBJDIR="../obj-$1"
MODDIR="../mod-$1"
mkdir -p $OBJDIR
kernel_name="vmlinuz-testing"
hostpc=$2
ncpus=$(grep ^siblings /proc/cpuinfo | uniq |  awk '{print $3}')
# ncpus=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
# ncpus=8
echo "Using ($ncpus) cpus"
make O=$OBJDIR -j$ncpus clean > /dev/null

rm -rf $OBJDIR/arch/x86_64/boot/bzImage
rm -rf $MODDIR/lib/modules/ $MODDIR/boot/$kernel_name $MODDIR/linux-testing.tar.gz

make O=$OBJDIR -j$ncpus menuconfig
time make O=$OBJDIR -j$ncpus
make O=$OBJDIR -j$ncpus modules_install INSTALL_MOD_PATH=$MODDIR INSTALL_MOD_STRIP=1  > /dev/null

#moddir=`ls ~/mods/lib/modules/ | head`
#sudo rm -rf /boot/vmlinuz-6.0.0-binli /lib/modules/$moddir
mkdir -p $MODDIR/boot
if [ -e $OBJDIR/arch/x86_64/boot/bzImage ]; then 
  cp $OBJDIR/arch/x86_64/boot/bzImage $MODDIR/boot/$kernel_name
  tar -czvf $MODDIR/linux-testing.tar.gz -C $MODDIR boot/ lib/
fi
if [ ! -z "$hostpc" ]; then
  scp $MODDIR/linux-testing.tar.gz ubuntu@$hostpc:~/
fi
