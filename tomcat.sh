#!/bin/bash

# Tomcat setup is START
echo "****************************************"
echo -e "\e[5mTomcat setup is START.!\e[0m"
echo "****************************************"


# Run as root
sudo -i

# Install Java
echo "Installing Java ..."
dnf -y install expect java-11-openjdk java-11-openjdk-devel 

# Download and extract Tomcat package
echo "Downloading and extracting Tomcat package..."
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
tar xzvf apache-tomcat-9.0.75.tar.gz

# Add tomcat user
echo "Adding tomcat user..."
useradd --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat

# Copy data to tomcat home directory
echo "Copying data to Tomcat home directory..."
# mkdir -p /usr/local/tomcat
cp -r apache-tomcat-9.0.75/*  /usr/local/tomcat/

# Make tomcat user owner of tomcat home directory
echo "Making tomcat user owner of Tomcat home directory..."
chown -R tomcat.tomcat /usr/local/tomcat

# Create tomcat systemd service file
echo "Creating tomcat systemd service file..."
cat <<EOL > /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
User=tomcat
WorkingDirectory=/usr/local/tomcat
Environment=JRE_HOME=/usr/lib/jvm/jre
Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_HOME=/usr/local/tomcat
Environment=CATALINE_BASE=/usr/local/tomcat
ExecStart=/usr/local/tomcat/bin/catalina.sh run
ExecStop=/usr/local/tomcat/bin/shutdown.sh
SyslogIdentifier=tomcat-%i

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd files and start & enable tomcat service
echo "Reloading systemd files and starting & enabling tomcat service..."
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

# Deploy artifact
echo "Deploy artifact and replace old ROOT.war by new one"
systemctl stop tomcat
rm -rf /usr/local/tomcat/webapps/ROOT*

# Deploy artifact
echo "Deploying artifact..."

su - vagrant

expect <<EOF
spawn scp -o StrictHostKeyChecking=no vagrant@192.168.56.13:/home/vagrant/vprofile-project/target/vprofile-v2.war /home/vagrant/vprofile-v2.war
expect "vagrant@192.168.56.13's password:"
send "vagrant\r"
expect eof
EOF

sudo -i
cp /home/vagrant/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
systemctl start tomcat
chown -R tomcat.tomcat /usr/local/tomcat/webapps
systemctl restart tomcat

echo "****************************************"
echo -e "\e[5mComplete deploy Tomcat.!\e[0m"
echo "****************************************"

# Enabling the firewall and allowing port 8080 to access Tomcat
# echo "Enabling the firewall and allowing port 8080 to access Tomcat..."
# systemctl start firewalld
# systemctl enable firewalld
# firewall-cmd --zone=public --add-port=8080/tcp --permanent
# firewall-cmd --reload

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

sed -i 's/^Hostname=.*/Hostname=app01/' /etc/zabbix/zabbix_agent2.conf

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2
systemctl status zabbix-agent2

echo ""
echo "****************************************"
echo -e "\e[5mZabix Agent setup is Complete..\e[0m"
echo "****************************************"


