#!/bin/bash
# Start script for setup and start of minecraft server.
# Should be called with root user rights, after server initialization.
echo start.sh script is starting.

# Get path to mount point.
mnt_pt=$(dirname `which $0`)

# Install LSB core for init script.
# yum install -y redhat-lsb-core

# Install docker tools.
echo Installing docker.io
yum install -y docker

# Add ec2-user to docker group to use docker without sudo.
echo Adding user ec2-user to group docker
sudo usermod -a -G docker ec2-user
service docker start

# Install docker-compose.
echo Installing docker-compose.
sudo curl -sSo /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m`
sudo chmod +x /usr/local/bin/docker-compose

# Install Minecraft service init script.
#echo 'Installing Minecraft server script in init.d.'
#ln -s "${mnt_pt}/service-script/config" /etc/default/minecraft
#ln -s "${mnt_pt}/service-script/minecraft" /etc/init.d/minecraft
#chkconfig --add minecraft

#echo 'Starting Minecraft service.'
#service minecraft start

# Install python modules for setup_dns_route53.py.
sudo python -m pip install boto3 toml


# Load config values.
echo Loading ${mnt_pt}/config.sh 
set -a
. ${mnt_pt}/config.sh
set +a

echo Adding "${mnt_pt}/bin" to PATH
echo PATH=\$PATH:${mnt_pt}/bin >> /home/ec2-user/.bash_profile
echo export PATH >> /home/ec2-user/.bash_profile

echo start.sh script done.
