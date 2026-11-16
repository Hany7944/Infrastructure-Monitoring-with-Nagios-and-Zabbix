#!/bin/bash


echo "****************************************"
echo -e "\e[5mMariaDB setup is START...\e[0m"
echo "****************************************"
echo ""
echo ""
# Switch to root user
sudo -i

# Update package list and install EPEL release
echo "Installing EPEL release..."
yum install epel-release -y

# Install MariaDB and Git
echo "Installing MariaDB and Git..."
yum install git expect mariadb-server -y

# Start and enable MariaDB service
echo "Starting and enabling MariaDB service..."
systemctl start mariadb
systemctl enable mariadb

# Run mysql_secure_installation script automatically
echo "Securing MariaDB..."

expect <<EOF
spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication \[Y/n\]"
send "Y\r"
expect "Change the root password? \[Y/n\]"
send "Y\r"
expect "New password:"
send "admin123\r"
expect "Re-enter new password:"
send "admin123\r"
expect "Remove anonymous users? \[Y/n\]"
send "Y\r"
expect "Disallow root login remotely? \[Y/n\]"
send "Y\r"
expect "Remove test database and access to it? \[Y/n\]"
send "Y\r"
expect "Reload privilege tables now? \[Y/n\]"
send "Y\r"
expect eof
EOF

# Configure MariaDB: Create database and user
echo "Configuring MariaDB database and user..."
mysql -u root -padmin123 <<MYSQL_SCRIPT
CREATE DATABASE accounts;
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Download source code and initialize database
echo "Cloning source code and initializing database..."
git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
mysql -u root -padmin123 accounts < src/main/resources/db_backup.sql

# Restart MariaDB service
echo "Restarting MariaDB service..."
systemctl restart mariadb

# Start and configure the firewall to allow access to MariaDB on port 3306
# echo "Configuring firewall..."
# systemctl start firewalld
# systemctl enable firewalld
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --reload
echo ""
echo ""
echo "****************************************"
echo -e "\e[5mMariaDB setup is complete.\e[0m"
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

sed -i 's/^Hostname=.*/Hostname=db01/' /etc/zabbix/zabbix_agent2.conf

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2
systemctl status zabbix-agent2

echo ""
echo "****************************************"
echo -e "\e[5mZabix Agent setup is Complete..\e[0m"
echo "****************************************"
echo ""