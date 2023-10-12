#!/bin/bash
INTERFACE=$(ip a | grep ens | head -1 | awk '{print $2}' | cut -d: -f1)
sed -i "s|ens.*|${INTERFACE}:|g" /etc/netplan/01-config.yaml
netplan apply
