#!/bin/bash
#
# MvGemert: v0.1. Script to setup pv, vg, lv and mounts on seconddisk 
echo "";echo "#####"
echo "# creating volume groups and logical volumes on seconddisk"
echo "#####";echo ""

mySecondaryDiskPartition='/dev/sdb1'
myVG='vg0'
myLV='tmp'
myLVsize='+3G'
myLVfullname="/dev/${myVG}/${myLV}"

echo "creating physical volume"
pvcreate ${mySecondaryDiskPartition}

echo "creating volume group on secondary disk partition"
vgcreate -f ${myVG} ${mySecondaryDiskPartition}

echo "creating logical volume(s) on secondary disk partition"
lvcreate -L ${myLVsize} -n ${myLV} ${myVG}

echo "Format second disk..."
mkfs.ext4 -F "${myLVfullname}"

echo "Setting fstab mounts"
echo "${myLVfullname}     /${myLV}    ext4     nodev,nosuid,exec     0 0 " >> /etc/fstab

# remount according to changes in fstab
mount -a

# known issue with mount /tmp and agent forwarding.
# to solve the problem set rights to 1777
chmod 1777 /tmp