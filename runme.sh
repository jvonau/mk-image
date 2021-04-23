#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt update
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

# another workaround2
apt -y remove needrestart
apt -y purge needrestart
echo "needsrestart"
# issue

cd iiab
# workaround
#add-apt-repository -y  ppa:ansible/ansible
#rm /etc/apt/sources.list.d/ansible-ubuntu-ansible-*.list
#sed '/apt-key adv/d' -i /opt/iiab/iiab/scripts/ansible
#/opt/iiab/iiab/scripts/ansible
#echo "git reset"
#git reset --hard
# end
git pull http://github.com/jvonau/iiab gpg-key

/opt/iiab/iiab-factory/iiab-upgrade

# put back
apt -y install needrestart
# cleanup
rm /var/cache/apt/archives/*.deb
# artifacts
mv /etc/iiab/local_vars.yml /etc/iiab/local_vars.yml.base
apt list | grep installed > /etc/iiab/debs.txt
