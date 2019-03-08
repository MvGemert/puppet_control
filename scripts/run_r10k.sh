#!/bin/bash
if /opt/puppetlabs/puppet/bin/r10k puppetfile check;then
	/opt/puppetlabs/puppet/bin/r10k puppetfile install --force
else
	echo "Please check Puppetfile, contains error!"
fi
