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
sleep 2
LOOP=`losetup | grep $IMAGE | awk -F " " '{ print $1 }'`
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
mount "$LOOP"p1 /mnt/img/boot/firmware
mount --bind /dev /mnt/img/dev
mount --bind /sys /mnt/img/sys
mount --bind /proc /mnt/img/proc

# target of bind mounted files must exist
if [ -f sources/en.zip ]; then
    touch /mnt/img/tmp/en.zip
    mount --bind sources/en.zip /mnt/img/tmp/en.zip
fi
cp -f runme.sh  /mnt/img/runme.sh
chmod 0755 /mnt/img/runme.sh
echo "ENTERING CHROOT"
#echo "exit to leave"
#chroot /mnt/img
chroot /mnt/img /runme.sh
echo "out of chroot"
sync
umount /mnt/img/boot/firmware
# undo bind mounted files
if [ -f /mnt/img/tmp/en.zip ]; then
    umount /mnt/img/tmp/en.zip
fi
# clean trash from iiab-refresh-wiki-docs
rm -rf /mnt/img/tmp/*
# end cleanup
umount /mnt/img/proc
umount /mnt/img/sys
umount /mnt/img/dev
umount /mnt/img
losetup -d "$LOOP"
echo "$IMAGE created"
