#!/bin/bash

customerShortcode='sg'
pathBase='/vagrant/modules'
pathProfile="${pathBase}/vs_profile"
pathRole="${pathBase}/${customerShortcode}_role"
pathControl="${pathBase}/${customerShortcode}_control"

reloadServer(){
  if [ $(pgrep -f "puppet strings server" | grep -vi grep | wc -l) -gt 0 ]
  then
    echo "first stop the http server..."
    kill `pgrep -f "puppet strings server"` > /dev/null 2>&1
  fi
  echo "start puppet strings run and provisioning http server"
  puppet strings server | grep -iv "warn" &
}


cd "$pathProfile"
echo "generating the documentation for vs_profile and reload the http server..."
reloadServer
