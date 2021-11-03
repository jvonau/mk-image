#!/bin/bash
# Copyright (C) 2021 <Jerry Vonau>
SIZE=$1
SOURCE=$2
IMAGE=$3
echo "$1 $2 $3"
echo "Preparing $1 GB image named $3 from $2"
dd if=/dev/zero of=$IMAGE bs=1 count=0 seek=$1G
losetup -f $IMAGE
sleep 2
LOOP=`losetup | grep $IMAGE | awk -F " " '{ print $1 }'`
echo "loop is $LOOP"
sleep 2

if [ $SOURCE == *.xz ]; then
    xzcat -c "$SOURCE" | dd bs=4M of="$LOOP" status=progress
    sync

    fdisk $LOOP <<EOF
d

n
p


n

w
EOF
    sync
    losetup -d $LOOP
    sleep 2
    losetup -P -f $IMAGE
    LOOP=`losetup | grep $IMAGE | awk -F " " '{ print $1 }'`
else
    dd if=$SOURCE of=$LOOP
    losetup -d $LOOP
    sleep 2
    losetup -P -f $IMAGE
    LOOP=`losetup | grep $IMAGE | awk -F " " '{ print $1 }'`
    growpart $LOOPp2
fi
sleep 2
echo "loop is $LOOP"
e2fsck -f "$LOOP"p2
resize2fs "$LOOP"p2
losetup -d "$LOOP"
sleep 2

losetup -P -f $IMAGE
sleep 2
LOOP=`losetup | grep $IMAGE | awk -F " " '{ print $1 }'`
e2fsck -f "$LOOP"p2
echo "loop is $LOOP"

mkdir -p /mnt/img
mount "$LOOP"p2 /mnt/img
if [ -d /mnt/img/boot/firmware ]; then
    mount "$LOOP"p1 /mnt/img/boot/firmware
else
    mount "$LOOP"p1 /mnt/img/boot
fi
mount --bind /dev /mnt/img/dev
mount --bind /sys /mnt/img/sys
mount --bind /proc /mnt/img/proc
mv /mnt/img/etc/resolv.conf /mnt/img/etc/resolv.conf.hold
touch /mnt/img/etc/resolv.conf
mount --bind /etc/resolv.conf /mnt/img/etc/resolv.conf

# target of bind mounted files must exist
if [ -f sources/en.zip ]; then
    touch /mnt/img/tmp/en.zip
    mount --bind sources/en.zip /mnt/img/tmp/en.zip
fi
if [ -f sources/local_vars.yml ]; then
    mkdir -p /mnt/img/etc/iiab/install-flags
    cp sources/local_vars.yml /mnt/img/etc/iiab/
fi
cp -f runme.sh  /mnt/img/runme.sh
chmod 0755 /mnt/img/runme.sh
echo "ENTERING CHROOT"
#echo "exit to leave"
#chroot /mnt/img
chroot /mnt/img /runme.sh
echo "out of chroot"
sync
rm /mnt/img/runme.sh

umount /mnt/img/boot/firmware || true
umount /mnt/img/boot  || true
# undo bind mounted files
if [ -f /mnt/img/tmp/en.zip ]; then
    umount /mnt/img/tmp/en.zip
fi
umount /mnt/img/etc/resolv.conf
rm /mnt/img/etc/resolv.conf
mv /mnt/img/etc/resolv.conf.hold /mnt/img/etc/resolv.conf

# clean trash from iiab-refresh-wiki-docs
rm -rf /mnt/img/tmp/*
# end cleanup
umount /mnt/img/proc
umount /mnt/img/sys
umount /mnt/img/dev
umount /mnt/img
losetup -d "$LOOP"
echo "$IMAGE created"
