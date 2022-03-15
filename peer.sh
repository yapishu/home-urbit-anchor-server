#!/bin/bash
set -euo pipefail
DATE=`date +%D | sed -e "s/\//./g"`
INTERFACE=`wg show interfaces`
WGPATH="/etc/wireguard"
CONFPATH="/mnt/conf"

mkdir -p /mnt/conf
mkdir -p ${WGPATH}/peers
PEER=$1
PUBKEY=$2
umask 077
echo ${PUBKEY} >> ${WGPATH}/peers/${PEER}-${DATE}.pub
echo "Public key recorded for ${PEER}."
echo "Generating interface configuration..."


###
### TODO: a better way to track IP addresses
### right now this just looks at the last IP in the conf and +1 while <256
###
# Find the IP of the last client
LASTIP=`tail -n 1 ${INTERFACE}.conf | awk '{print $3}' | awk -F. '{print $4}' \
        | awk -F'/' '{print $1}'`
if [ "$LASTIP" -ge "256" ]; then
        echo You have run out of /24 addresses. Exiting.
        exit 1
fi
# Incremented /32
IPVAR=$((LASTIP+1))
# New IP strings for configs
NEWIP_SERVER=`tail -n 1 ${INTERFACE}.conf | awk '{print $3}' \
        | awk -F. -v OFS=. -v r=${IPVAR}/32 '{$4=r}1'`
NEWIP_PEER=`tail -n 1 ${INTERFACE}.conf | awk '{print $3}' \
        | awk -F. -v OFS=. -v r=${IPVAR}/24 '{$4=r}1'`

# Print new peer entry to interface config
printf "\n\n# ${PEER}\n[Peer]\nPublicKey = ${PUBKEY}\nAllowedIPs = \
${NEWIP_SERVER}" >> ${INTERFACE}.conf

# Generate .conf for client
# Copy to volume afterwards
PEERCONF="${PEER}.${DATE}.conf"
echo Generating client configuration...
cp template conf/${PEERCONF}
echo Replacing name with ${PEER}
sed -i "s|name|$PEER|g" conf/${PEERCONF}
echo Replacing privkey with $PRIVKEY
sed -i "s|privkey|$PRIVKEY|g" conf/${PEERCONF}
echo Replacing IP with $NEWIP_PEER
sed -i "s|clientip|$NEWIP_PEER|g" conf/${PEERCONF}
echo ${PEER} complete
echo =======
######
####
##
cp conf/${PEERCONF} ${CONFPATH}/
echo
echo Reloading interface...
wg-quick down ${INTERFACE}
wg-quick up ${INTERFACE}
