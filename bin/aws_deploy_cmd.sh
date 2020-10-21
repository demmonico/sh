#!/usr/bin/env bash

#-----------------------------------------------------------#
# Install docker onto AWS EC2 instances
#
# @author: demmonico <demmonico@gmail.com> <https://github.com/demmonico>
# @date: 07.11.2016
# @package: https://github.com/demmonico/sh
# @package-moved-from: https://github.com/demmonico/bash
#
# @use: ./aws_deploy_cmd.sh
# with root permissions and Ubuntu 16.04
#-----------------------------------------------------------#



echo "Deploying AWS Docker Set ... ";


######################################
# INSTALL
######################################

apt-get update && 

# mc
apt-get install -y mc && 

# git
apt-get install -y git && 

# docker
apt-get install -y apt-transport-https ca-certificates && apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && 
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list && apt-get update && 
apt-get install -y docker-engine && service docker start && 

# docker compose
curl -L "https://github.com/docker/compose/releases/download/1.8.1/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && 



######################################
# CONFIGURE
######################################

# create docker projects folder
mkdir /docker && cd /docker;



echo "Done";
