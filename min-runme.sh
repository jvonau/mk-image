#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y git wget curl

mkdir /opt/iiab
cd /opt/iiab
# adjust as needed
git clone http://github.com/jvonau/iiab-factory
git clone http://github.com/iiab/iiab-admin-console
git clone http://github.com/iiab/iiab

mkdir /etc/iiab
# adjust as needed
#cd /etc/iiab
#wget https://raw.githubusercontent.com/jvonau/iiab/build/vars/local_vars_min_secure.yml -O local_vars.yml
cp /opt/iiab/iiab/vars/local_vars_min.yml /etc/iiab/local_vars.yml

# Install iiab or cp from iiab-factory
curl https://raw.githubusercontent.com/iiab/iiab-factory/master/iiab > /usr/sbin/iiab
chmod 0744 /usr/bin/iiab

# adjust as needed /usr/bin/iiab
/opt/iiab/iiab-factory/iiab-upgrade

# cleanup
#rm /var/cache/apt/archives/*.deb
# artifacts could reset stage counter at this point
mv /etc/iiab/local_vars.yml /etc/iiab/local_vars.yml.builder
cp /runme.sh /etc/iiab/builder.sh
apt list | grep installed > /etc/iiab/debs.txt
