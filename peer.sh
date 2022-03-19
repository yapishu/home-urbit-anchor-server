#!/bin/bash
###############################################################################
#                 Anchor server peer generator                                #
#                                                                             #
#  When triggered, this script takes ${1} as a peer ID and ${2} as a WG       #
#  pubkey. It generates a user config, drops it into a volume at /mnt/conf,   #
#  and adds the user to the interface's config file & restarts it.            #
#  Assumes that WG is already stood up and configured in a particular way.    #
#                                                                             #
#         ~sitful-hatred                                                      #
#                                                                             #
###############################################################################

set -euo pipefail
DATE=`date +%D | sed -e "s/\//./g"`
INTERFACE=`wg show interfaces`
WGPATH="/etc/wireguard"

mkdir -p /mnt/conf
mkdir -p ${WGPATH}/peers
INPUT=$1
PEER=`echo $INPUT|jq -r .name`
PUBKEY=`echo $INPUT|jq -r .pubkey`
cd ${WGPATH}
umask 077
echo "Generating interface configuration..."

###
### TODO: a better way to track IP addresses
### right now this just looks at the last  used IP and +1
### maybe a sqlite db?
# Find the IP of the last client
NEWIP_PEER=`cat /mnt/conf/avail-ip`
###
###

# Print new peer entry to interface config
printf "\n\n# ${PEER}\n[Peer]\nPublicKey = ${PUBKEY}\nAllowedIPs = \
0.0.0.0/0\nPersistentKeepalive = 10\n" >> ${INTERFACE}.conf

# Generate .conf for client, place in volume
PEERCONF="/mnt/conf/${PEER}.${DATE}.conf"
echo "Generating client configuration..."
cp template ${PEERCONF}
echo "Replacing name with ${PEER}"
sed -i "s|name|${PEER}|g" ${PEERCONF}
echo "Replacing IP with ${NEWIP_PEER}"
sed -i "s|clientip|${NEWIP_PEER}|g" ${PEERCONF}
echo "Replacing pubkey with ${PUBKEY}"
sed -i "s|pubkey|${PUBKEY}|g" ${PEERCONF}
echo "${PEER} complete"
echo "======="
nextip ${NEWIP_PEER} > /mnt/conf/avail-ip
######
####
##

echo "Reloading interface..."
wg-quick down ${INTERFACE}
wg-quick up ${INTERFACE}
