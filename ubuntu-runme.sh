#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
bash

#sudo sed -i 's/groovy/hirsute/g' /etc/apt/sources.list
sudo sed -i 's/groovy/impish/g' /etc/apt/sources.list

apt update
apt -y upgrade
#apt -y dist-upgrade
# workaround failure
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

apt install -y git wget curl whiptail software-properties-common
mkdir /etc/iiab
cd /etc/iiab
wget https://raw.githubusercontent.com/jvonau/iiab/build/vars/local_vars_base_secure.yml -O local_vars.yml
#echo "provision_install: True" >> /etc/iiab/local_vars.yml
#echo "provision_active: True" >> /etc/iiab/local_vars.yml
#echo "provision_enable: True" >> /etc/iiab/local_vars.yml

mkdir /opt/iiab
cd /opt/iiab
git clone http://github.com/iiab/iiab-admin-console
git clone http://github.com/jvonau/iiab-factory
git clone http://github.com/iiab/iiab

# Install iiab
curl https://raw.githubusercontent.com/iiab/iiab-factory/master/iiab > /usr/sbin/iiab
chmod 0744 /usr/sbin/iiab

bash

/opt/iiab/iiab-factory/iiab-upgrade

# cleanup
#rm /var/cache/apt/archives/*.deb
# artifacts
mv /etc/iiab/local_vars.yml /etc/iiab/local_vars.yml.builder
cp /runme.sh /etc/iiab/builder.sh
apt list | grep installed > /etc/iiab/debs.txt
sed -i 's/^STAGE=.*/STAGE=3/' /etc/iiab/iiab.env
bash
