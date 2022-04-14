#!/bin/bash
# Copyright (C) 2021 <Jerry Vonau>
SIZE=$1
SOURCE=$2
IMAGE=$3
MP=/tmp/mkarm-mp
cache_name=""
rm -rf "${MP}"
mkdir "${MP}"
echo "$1 $2 $3"
echo "Preparing $1 GB image named $3 from $2"
#COMMON
mk_image(){
    dd if=/dev/zero of="${IMAGE}" bs=1 count=0 seek="${SIZE}G" status=progress
    losetup -f "${IMAGE}"
    sleep 2
    LOOP=$(losetup | grep "${IMAGE}" | awk -F " " '{ print $1 }')
    echo "loop is $LOOP"
    sleep 2
}

case "${SOURCE}" in
    *.xz)
    mk_image
    xzcat -c "$SOURCE" | dd bs=4M of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
    cache_name=$(basename "${SOURCE}" | sed s/.xz//)
        ;;

    *.zip)
    mk_image
    unzip -p "${SOURCE}" | dd bs=4M of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
    cache_name=$(basename "${SOURCE}" | sed s/.zip//)
        ;;

    *.gz)
    mk_image
    gunzip -c if="${SOURCE}" | dd bs=4M of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
    cache_name=$(basename "${SOURCE}" | sed s/.gz//)
        ;;

    *.img)
    mk_image
    dd bs=4M if="${SOURCE}" of="${LOOP}" status=progress
    sync
    losetup -d "${LOOP}"
    cache_name=$(basename "${SOURCE}" | sed s/.img//)
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
e2fsck -f "${LOOP}p2"
sync
resize2fs "${LOOP}p2"
sync
losetup -d "${LOOP}"
sleep 2

losetup -P -f "${IMAGE}"
LOOP=$(losetup | grep "${IMAGE}" | awk -F " " '{ print $1 }')
echo "working loop is $LOOP"
e2fsck -f "${LOOP}p2"
sync

mount "${LOOP}p2" "${MP}"
if [ -d "${MP}"/boot/firmware ]; then
    mount "${LOOP}p1" "${MP}"/boot/firmware
else
    mount "${LOOP}p1" "${MP}"/boot
fi
mount --bind /sys "${MP}"/sys
mount -t proc proc "${MP}"/proc
mount --bind /dev "${MP}"/dev
mount --bind /dev/pts "${MP}"/dev/pts
mv "${MP}"/etc/resolv.conf "${MP}"/etc/resolv.conf.hold
touch "${MP}"/etc/resolv.conf
mount --bind /etc/resolv.conf "${MP}"/etc/resolv.conf
if [ $(uname -m) = "x86_64" ];then
    cp /usr/bin/qemu-arm-static /mnt/img/usr/bin/
fi

#/usr/share/doc/apt/examples/configure-index varies by distro
# ubuntu apt::keep-downloaded-packages "<BOOL>";
# debian Binary::apt::APT::Keep-Downloaded-Packages "<BOOL>";
# handle this by OS in runme.sh
if [ -d apt_cache ]; then
    use_cache=1
    mkdir -p apt_cache/"${cache_name}"
    mount --bind apt_cache/"${cache_name}" "${MP}"/var/cache/apt/archives
#    cat << EOF > "${MP}"/etc/apt/apt.conf.d/99-keep
#Binary::apt::APT::Keep-Downloaded-Packages 1;
#EOF
fi

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
rm "${MP}"/runme.sh

# undo bind mounted files
if [ -f "${MP}"/tmp/en.zip ]; then
    umount "${MP}"/tmp/en.zip
fi

umount "${MP}"/etc/resolv.conf
rm "${MP}"/etc/resolv.conf
mv "${MP}"/etc/resolv.conf.hold "${MP}"/etc/resolv.conf

#if eval "$(mount | grep "${cache_name}")"; then
if [ "${use_cache}" = "1" ]; then
    echo "cache name ${cache_name}"
    rm "${MP}"/etc/apt/apt.conf.d/01-keep
    umount "${MP}"/var/cache/apt/archives
fi
if [ -f "${MP}"/usr/bin/qemu-arm-static ]; then
    rm "${MP}"/usr/bin/qemu-arm-static
fi

# clean trash from iiab-refresh-wiki-docs
rm -rf "${MP}"/tmp/*
# end cleanup

sync

if [ -d "${MP}"/boot/firmware ]; then
    umount "${MP}"/boot/firmware
else
    umount "${MP}"/boot
fi
umount "${MP}"/dev/pts
umount "${MP}"/dev
umount "${MP}"/sys
umount "${MP}"/proc
umount "${MP}"
losetup -d "${LOOP}"
echo "$IMAGE created"
