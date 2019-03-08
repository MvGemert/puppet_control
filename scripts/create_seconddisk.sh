#!/bin/bash
#
# MvGemert: v0.1. Script to setup fstab according target server profile mounts
echo "";echo "#####"
echo "# creating a second disk to mount to..."
echo "#####";echo ""
echo "Running fdisk on secondary disk"
mySecondaryDisk='/dev/sdb'
echo "Formatting disk ${mySecondaryDisk}"
sudo fdisk ${mySecondaryDisk} <<EOF
o
n
p
1

+10G
p
w
EOF
echo "Listing the disks and partitions:"
#/bin/lsblk
