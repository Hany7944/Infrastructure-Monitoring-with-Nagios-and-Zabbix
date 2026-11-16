#!/bin/bash

# Maven setup is START
echo "****************************************"
echo -e "\e[5mMaven setup is START.!\e[0m"
echo "****************************************"



# Run as root
sudo -i

# Update package list and install EPEL release
echo "Installing EPEL release..."
yum install epel-release -y

# Install Git, Maven, and Wget
echo "Installing Git, Maven, and Wget..."
dnf -y install git maven wget

# Code build & deploy
# Download source code
echo "Downloading source code..."
git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project

# Build code
echo "Building code..."
mvn install


echo "****************************************"
echo -e "\e[5mMaven setup and deployment is complete.!\e[0m"
echo "****************************************"
echo ""
echo "****************************************"
echo -e "\e[5mNagios Plugins setup is START..\e[0m"
echo "****************************************"
echo ""
cd ~
echo "Prerequisites packages install...."
dnf install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
dnf config-manager --set-enabled crb
dnf install -y perl-Net-SNMP

# Downloading the Source
echo "Downloading the Source ..."

wget --output-document="nagios-plugins.tar.gz" \
$(wget -q -O - https://api.github.com/repos/nagios-plugins/nagios-plugins/releases/latest \
| grep '"browser_download_url":' \
| grep -o 'https://[^"]*')

tar zxf nagios-plugins.tar.gz

# Compile + Install 
echo "Install the nagios Plugins config file ..."
cd nagios-plugins-*
./configure
make
make install

echo "Plugin Installation Location: /usr/local/nagios/libexec/"

systemctl start nagios.service
systemctl stop nagios.service
systemctl restart nagios.service
systemctl status nagios.service

echo "Locate and open the CGI configuration file: /usr/local/nagios/etc/cgi.cfg to reduse the time of Re-schedule the next check"

echo ""
echo "****************************************"
echo -e "\e[5mNagios Plugins setup is Complete..\e[0m"
echo "****************************************"

echo "To Add another Hosts/Services to monitor by nagios, update the localhost file in this path: cfg_file=/usr/local/nagios/etc/objects/localhost.cfg"

echo ""
echo "****************************************"
echo -e "\e[5mZabix Agent setup is Start..\e[0m"
echo "****************************************"
echo ""

rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/9/x86_64/zabbix-release-latest.el9.noarch.rpm

dnf clean all

dnf install zabbix-agent2 -y

sed -i 's/^Server=.*/Server=192.168.56.100/' /etc/zabbix/zabbix_agent2.conf

sed -i 's/^ServerActive=.*/ServerActive=192.168.56.100/' /etc/zabbix/zabbix_agent2.conf

sed -i 's/^Hostname=.*/Hostname=mav01/' /etc/zabbix/zabbix_agent2.conf

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2
systemctl status zabbix-agent2

echo ""
echo "****************************************"
echo -e "\e[5mZabix Agent setup is Complete..\e[0m"
echo "****************************************"
echo ""