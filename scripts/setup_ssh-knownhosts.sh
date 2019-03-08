#!/bin/bash
#
# MvGemert: v0.1. Initial setup script for adding known_hosts
# set git repos hostkey in known_hosts
#
echo 'Get the git repository server hostkey and put it in known_hosts'

set_hostkey(){
        if [ ! -d "$myPath" ]
        then
                mkdir $myPath;
        fi
	if [ ! -f "$myFile" ]
	then
		touch $myPath;
	fi
	ssh-keyscan -H repo.virtualsciences.nl >> $myFile;
}

# setup for vagrant user
myPath="/home/vagrant/.ssh"
myFile="${myPath}/known_hosts"
set_hostkey
chown -R vagrant.vagrant $myPath

# and setup for root user
myPath="/root/.ssh"
myFile="${myPath}/known_hosts"
set_hostkey

#echo  "enable ssh forwarding agent for user"
#cat <<EOT >> ${myPath}/config
#Host		*
#  ForwardAgent	yes
#EOT
#cat > ${myPath}/config <<- EOM
#Host		*
#  ForwardAgent	yes
#EOM