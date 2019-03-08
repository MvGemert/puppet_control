#!/bin/bash

#  execute commands to enable Xforwarding for MQ Explorer.
#
# Note: enable ONLY on local (laptop) virtual machines to check configuration!

# AS ROOT, verify installed gtk2 package
echo "execute as ROOT user: yum install gtk2 gtk2.i686 libXtst libXtst.i686 libXp libXp.i686 libX11 libX11.i686"
#if [ `rpm -qa | grep -i compat-libstdc |wc -l` -ne 1 ];then echo "please install compat-libstdc++ AS ROOT USER: yum install compat-libstdc++";fi 

#
# PROCEED AS MQM USER
#


# set environment, if not set allready
. /opt/mqm/bin/setmqenv -s

# LOCATE THE NETWORK IP OF YOUR HOST, F.E. WHEN USING ORACLE VIRTUALBOX:
# Ethernet adapter VirtualBox Host-Only Network:
#
#   Connection-specific DNS Suffix  . :
#   Description . . . . . . . . . . . : VirtualBox Host-Only Ethernet Adapter
#   IPv4 address......................: <IP ADRESS>

# Also run XLaunch, specify a port and use that port in export:

export DISPLAY="192.168.56.1:0.0"

# then run MQ Explorer:
strmqcfg
