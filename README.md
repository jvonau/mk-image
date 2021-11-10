# mk-image
Tool to create bootable IIAB images for RPi hardware, originally aimed at arm64 Ubuntu as the host building arm64 images with IIAB pre-configured.
Requires 'coreutils e2fsprogs cloud-guest-utils' apt packages to be installed.
How to use:
mkarm-image \<size of image in GB> \<path to downloaded.img.xz|.zip|.gz|.img> \<path to place the product and name of image>

sudo ./mkarm-image.sh 4 ../ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz /mnt/storage/pipeline-iiab-ubuntu-21.04-server-arm64.img

>Preparing 4 GB image named /mnt/storage/pipeline-iiab-ubuntu-21.04-server-arm64.img from ../ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
0+0 records in
0+0 records out
0 bytes copied, 0.000527105 s, 0.0 kB/s

How to customize:
Contents of the chroot image are availble at /mnt/img, use the runme.sh logic to introduce other files if needed in mkarm-image.sh 
Commands to run within the changeroot are contained within runme.sh Examples are proved, just copy to runme.sh

Should you enable kalite within your supplied local_vars file you should pre-populate sources/ with the en.zip file from ka-lite, this method saves space within the image not to mention bandwith with repeated running for differnt images.
Should you wish to retain the apt cache for future speed-ups and bandwidth savings create a 'apt_cache' directory with the git repo to enable this logic.
These image will boot just like the stock one, resizing to fit and forcing ubuntu to change the default password at first login. Wifi and ethernet should be available upon boot, but will wait to allow ssh connections as new ssh keys are being generated and other firstboot fuctions are being performed.

Time
/mnt/storage/pipeline-iiab-ubuntu-21.04-server-arm64.img created
real	31m15.189s
user	23m26.533s
sys	7m47.668s

Plus the time to extract the image about 3-4 mins, with /mnt/storage in the example being a sdcard in usb3 adaptor, ssd should be even faster.
What you can't pre-seed nextcloud, wordpress, moodle, and mediawiki due to limitations of iiab's strategy.

Tools
mount-image is a tool to mount an image to inspect, modifiy setting, provides internet access to preform apt updates, or to update the image with the latest iiab code, subject to available space in the image.
sudo ./mount-image.sh \<path to image ending in .img>
Type 'exit' when you are done
