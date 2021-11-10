#!/bin/bash
# Copyright (C) 2021 <Jerry Vonau>
SIZE=$1
SOURCE=$2
IMAGE=$3
MP=/tmp/mkarm-mp
rm -rf "${MP}"
mkdir "${MP}"
echo "$1 $2 $3"
echo "Preparing $1 GB image named $3 from $2"
#COMMON
dd if=/dev/zero of="${IMAGE}" bs=1 count=0 seek="${SIZE}G"
losetup -f "${IMAGE}"
sleep 2
LOOP=$(losetup | grep "${IMAGE}" | awk -F " " '{ print $1 }')
echo "loop is $LOOP"
sleep 2
#

case "${SOURCE}" in
    *.xz)
    xzcat -c "$SOURCE" | dd bs=4M of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
        ;;

    *.zip)
    unzip -p "${SOURCE}" | dd bs=4M of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
        ;;

    *.gz)
    gunzip -c if="${SOURCE}" | dd bs=4M of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
        ;;

    *.img)
    dd bs=4M if="${SOURCE}" of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
        ;;

    *)
    echo "unknown extention"
    exit 1
        ;;
esac

sleep 2
losetup -P -f "${IMAGE}"
LOOP=$(losetup | grep "${IMAGE}" | awk -F " " '{ print $1 }')
echo "growpart $LOOP"
growpart "${LOOP}" 2
sleep 2
sync
echo "resize $LOOP"
resize2fs "${LOOP}p2"
losetup -d "${LOOP}"

losetup -P -f "${IMAGE}"
LOOP=$(losetup | grep "${IMAGE}" | awk -F " " '{ print $1 }')
echo "loop is $LOOP"
e2fsck -f "${LOOP}p2"
sync

mount "${LOOP}p2" "${MP}"
if [ -d "${MP}"/boot/firmware ]; then
    mount "${LOOP}p1" "${MP}"/boot/firmware
else
    mount "${LOOP}p1" "${MP}"/boot
fi
mount --bind /dev "${MP}"/dev
mount --bind /sys "${MP}"/sys
mount --bind /proc "${MP}"/proc
mv "${MP}"/etc/resolv.conf "${MP}"/etc/resolv.conf.hold
touch "${MP}"/etc/resolv.conf
mount --bind /etc/resolv.conf "${MP}"/etc/resolv.conf

# target of bind mounted files must exist
if [ -f sources/en.zip ]; then
    touch "${MP}"/tmp/en.zip
    mount --bind sources/en.zip "${MP}"/tmp/en.zip
fi
if [ -f sources/local_vars.yml ]; then
    mkdir -p "${MP}"/etc/iiab/install-flags
    cp sources/local_vars.yml "${MP}"/etc/iiab/
fi
cp -f runme.sh  "${MP}"/runme.sh
chmod 0755 "${MP}"/runme.sh
echo "ENTERING CHROOT"
#echo "exit to leave"
#chroot "${MP}"
chroot "${MP}" /runme.sh
echo "out of chroot"
sync
rm "${MP}"/runme.sh

umount "${MP}"/boot/firmware || true
umount "${MP}"/boot  || true
# undo bind mounted files
if [ -f "${MP}"/tmp/en.zip ]; then
    umount "${MP}"/tmp/en.zip
fi
umount "${MP}"/etc/resolv.conf
rm "${MP}"/etc/resolv.conf
mv "${MP}"/etc/resolv.conf.hold "${MP}"/etc/resolv.conf

# clean trash from iiab-refresh-wiki-docs
rm -rf "${MP}"/tmp/*
# end cleanup
umount "${MP}"/proc
umount "${MP}"/sys
umount "${MP}"/dev
umount "${MP}"
losetup -d "${LOOP}"
echo "$IMAGE created"
