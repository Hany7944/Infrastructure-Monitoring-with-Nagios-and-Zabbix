#!/bin/bash


echo "****************************************"
echo -e "\e[5mNagios Core setup is START.!\e[0m"
echo "****************************************"

# Switch to root user
sudo -i

# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. Steps to do this are as follows.
echo "Check SElinux status ..."
"to get the status of the SElinux"
getenforce 
# sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Perform these steps to install the pre-requisite packages.
echo "Perform these steps to install the pre-requisite packages ..."
dnf install -y gcc glibc glibc-common perl httpd php wget gd gd-devel s-nail postfix 
dnf install -y openssl-devel expect
dnf update -y

# Downloading the Source
echo "Downloading the Source ..."

wget --output-document="nagioscore.tar.gz" \
"$(wget -q -O - https://api.github.com/repos/NagiosEnterprises/nagioscore/releases/latest \
| grep '"browser_download_url":' \
| grep -o 'https://[^"]*')"

tar xzf nagioscore.tar.gz


# Compile /Execute 
echo "Execute the nagios core config file ..."
cd nagios-*
./configure
make all

# This creates the nagios user and group. The apache user is also added to the nagios group.
echo "Create User nagios, And Group nagios ..."
make install-groups-users
usermod -a -G nagios apache

# This step installs the binary files, CGIs, and HTML files.
echo "Install Binaries, CGI and HTML files...."
make install

# This installs the service or daemon files and also configures them to start on boot. The Apache httpd service is also configured at this point.
echo "Install Apache httpd service.... "
make install-daemoninit
systemctl enable httpd.service

# Install Command Mode This installs and configures the external command file.
echo "Installs and configures the external command file ....."
make install-commandmode

# This installs the *SAMPLE* configuration files. These are required as Nagios needs some configuration files to allow it to start.
echo "Install Configuration Files ....."
make install-config

# This installs the Apache web server configuration files. Also configure Apache settings if required.
echo "Install Apache Config Files"
make install-webconf

# You need to allow port 80 inbound traffic on the local firewall so you can reach the Nagios Core web interface.
#echo "Configure Firewall ....."

#firewall-cmd --zone=public --add-port=80/tcp
#firewall-cmd --zone=public --add-port=80/tcp --permanent

# Create nagiosadmin User Account (nagiosadmin/P@ssw0rd)

# You'll need to create an Apache user account to be able to log into Nagios.
# The following command will create a user account called nagiosadmin and you will be prompted to provide a password for the account.

echo "Create nagiosadmin User Account ......."
# htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
expect <<EOF
spawn htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
expect "New password:"
send "P@ssw0rd\r"
expect "Re-type new password:"
send "P@ssw0rd\r"
expect eof
EOF

echo "****************************************************************************************************************************************************************"
echo -e "\e[5mWhen adding additional users in the future, you need to remove -c from the above command otherwise it will replace the existing nagiosadmin user.!\e[0m"
echo "****************************************************************************************************************************************************************"

# Start Apache Web Server
echo "Start Apache Web Server ......."
systemctl start httpd.service
systemctl status httpd.service

# Start Service / Daemon
echo "Start Service......."
systemctl start nagios.service

# If the nagios.service 
# qh: Failed to init socket '/usr/local/nagios/var/rw/nagios.qh'.
# bind() failed: No such file or directory
# do this below checks:

# ls -ld /usr/local/nagios/var
# ls -ld /usr/local/nagios/var/rw
# mkdir -p /usr/local/nagios/var/rw
# chown -R nagios:nagios /usr/local/nagios/var
# chmod 775 /usr/local/nagios/var
# chmod 775 /usr/local/nagios/var/rw

# Or check 
# tail -50 /usr/local/nagios/var/nagios.log

# Restart the nagios services 
# systemctl stop nagios.service
# systemctl start nagios.service
# systemctl status nagios.service


echo "Nagios is now running, to confirm this you need to log into the Nagios Web Interface"
echo ""
echo "http://<Nagios_IP_Server>/nagios"
echo ""
echo "You will be prompted for a username and password. The username is nagiosadmin and the password is what you provided earlier."
echo ""
echo "****************************************"
echo -e "\e[5mNagios Core setup is Complete..\e[0m"
echo "****************************************"
echo ""
echo "****************************************"
echo -e "\e[5;31mBUT WAIT ..\e[0m"
echo "****************************************"
echo ""
echo "****************************************"
echo -e "Currently you have only installed the Nagios Core engine. You'll notice some errors under the hosts and services."
echo -e "These errors will be resolved once you install the Nagios Plugins."
echo "****************************************"
echo ""
echo "****************************************"
echo -e "\e[5mNagios Plugins setup is START..\e[0m"
echo "****************************************"

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

