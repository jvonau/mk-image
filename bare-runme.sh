#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
bash

# another workaround2
apt -y remove needrestart
apt -y purge needrestart
echo "needsrestart"

#sudo sed -i 's/groovy/hirsute/g' /etc/apt/sources.list
sudo sed -i 's/groovy/impish/g' /etc/apt/sources.list

apt update
#apt -y upgrade
apt -y dist-upgrade

rm /var/run/reboot-required*

bash

cat > /etc/update-manager/release-upgrades << EOF
# Default behavior for the release upgrader.

[DEFAULT]
# Default prompting and upgrade behavior, valid options:
#
#  never  - Never check for, or allow upgrading to, a new release.
#  normal - Check to see if a new release is available.  If more than one new
#           release is found, the release upgrader will attempt to upgrade to
#           the supported release that immediately succeeds the
#           currently-running release.
#  lts    - Check to see if a new LTS release is available.  The upgrader
#           will attempt to upgrade to the first LTS release available after
#           the currently-running one.  Note that if this option is used and
#           the currently-running release is not itself an LTS release the
#           upgrader will assume prompt was meant to be normal.
Prompt=normal

EOF
apt -y update
apt -y autoremove
apt -y install fake-hwclock rng-tools haveged
systemctl disable rng-tools.service
cat > /etc/systemd/system/rng-tools.service << EOF
[Unit]
Description=Add entropy to /dev/random 's pool a hardware RNG

[Service]
Type=simple
ExecStart=/usr/sbin/rngd -r /dev/hwrng -f

[Install]
WantedBy=systemd-random-seed.service
EOF

systemctl enable rng-tools.service

bash
#do-release-upgrade

#apt -y install needrestart
