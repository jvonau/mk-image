#!/bin/bash
# Copyright (C) 2021 <Jerry Vonau>
IMAGE=$1
echo "$1"

local_losetup(){
losetup -P -f $IMAGE
sleep 2
LOOP=`losetup | grep $IMAGE | awk -F " " '{ print $1 }'`
echo "loop is $LOOP"
sleep 2

mkdir -p /mnt/img
mount "$LOOP"p2 /mnt/img
mount "$LOOP"p1 /mnt/img/boot/firmware
mount --bind /dev /mnt/img/dev
mount --bind /sys /mnt/img/sys
mount --bind /proc /mnt/img/proc
}

local_losetup
echo "ENTERING CHROOT"
chroot /mnt/img

sync
umount /mnt/img/boot/firmware
umount /mnt/img/proc
umount /mnt/img/sys
umount /mnt/img/dev/pts >> /dev/null
umount /mnt/img/dev
umount /mnt/img
losetup -d "$LOOP"
echo "$IMAGE unmounted"
