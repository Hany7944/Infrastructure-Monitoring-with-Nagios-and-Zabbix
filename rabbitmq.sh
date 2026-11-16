#!/bin/bash


echo "****************************************"
echo -e "\e[5mRabbitMQ setup is START.!\e[0m"
echo "****************************************"

sudo -i 

# Install wget and RabbitMQ
echo "Installing wget and RabbitMQ..."
yum install wget -y
# cd /tmp/
dnf -y install centos-release-rabbitmq-38
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server

# Start and enable RabbitMQ service
echo "Starting and enabling RabbitMQ service..."
systemctl enable --now rabbitmq-server

# Setup access to user 'test' and make it admin
echo "Configuring RabbitMQ user 'test'..."
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator

# Restart RabbitMQ service to apply changes
echo "Restarting RabbitMQ service..."
systemctl restart rabbitmq-server

# Start and configure the firewall to allow access to RabbitMQ on port 5672
# echo "Configuring firewall for RabbitMQ..."
# firewall-cmd --add-port=5672/tcp
# firewall-cmd --runtime-to-permanent

# Start RabbitMQ service
# echo "Starting RabbitMQ service..."
# systemctl start rabbitmq-server
# systemctl enable rabbitmq-server
# systemctl status rabbitmq-server


echo "****************************************"
echo -e "\e[5mRabbitMQ setup is complete.!\e[0m"
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

sed -i 's/^Hostname=.*/Hostname=rmq01/' /etc/zabbix/zabbix_agent2.conf

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2
systemctl status zabbix-agent2

echo ""
echo "****************************************"
echo -e "\e[5mZabix Agent setup is Complete..\e[0m"
echo "****************************************"