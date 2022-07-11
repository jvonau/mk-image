#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# GIU must match sudo user from the host machine
groupadd -g 1001 testgroup


#/usr/share/doc/apt/examples/configure-index varies by distro
# ubuntu apt::keep-downloaded-packages "<BOOL>";
# debian Binary::apt::APT::Keep-Downloaded-Packages "<BOOL>";
cat << EOF > /etc/apt/apt.conf.d/01-keep
Binary::apt::APT::Keep-Downloaded-Packages "true";
apt::keep-downloaded-packages "true";
apt::Clean-Installed "false";
APT::Clean-Installed "false";
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

apt -y install git wget curl

#mkdir -p /opt/iiab
#cd /opt/iiab
#git clone http://github.com/iiab/iiab-admin-console
#git clone http://github.com/iiab/iiab-factory
#git clone http://github.com/iiab/iiab

mkdir -p /etc/iiab
wget https://raw.githubusercontent.com/jvonau/iiab/secure/vars/local_vars_min_secure.yml -O /etc/iiab/local_vars.yml
#wget https://raw.githubusercontent.com/iiab/iiab/master/vars/local_vars_min.yml -O /etc/iiab/local_vars.yml

# Install iiab or cp above
curl https://raw.githubusercontent.com/iiab/iiab-factory/master/iiab > /usr/bin/iiab
#curl https://raw.githubusercontent.com/jvonau/iiab-factory/fix_container2/iiab > /usr/bin/iiab
chmod 0744 /usr/bin/iiab

#cd /opt/iiab/iiab
#git checkout c4948ceab3473f2041c1e3064876cfb4b2fc4f75
#apt list > debs.pre.txt

apt -y upgrade

#debug break
#echo "Type 'exit [Enter]' to continue"
#bash

#/usr/bin/iiab
#/usr/bin/iiab --fast
/usr/bin/iiab --risky
apt -y autoremove

#debug break
#echo "Type 'exit [Enter]' to continue"
#bash

# artifacts
mv /etc/iiab/local_vars.yml /etc/iiab/local_vars.yml.builder
cp /runme.sh /etc/iiab/builder.sh
apt list | grep installed > /etc/iiab/debs.txt
#rm /etc/iiab/install-flags/iiab-complete
#sed -i 's/^STAGE=.*/STAGE=3/' /etc/iiab/iiab.env
rm /etc/profile.d/sshpwd-profile-iiab.sh || true
rm /tmp/en.zip || true
killall dirmngr || true
groupdel testgroup
