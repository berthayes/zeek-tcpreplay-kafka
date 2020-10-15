#!/bin/sh

# give all of the other hosts a chance to get up and running
sleep 90

ip link add dummy0 type dummy
ifconfig dummy0 mtu 3000
ifconfig dummy0 up
/usr/local/zeek/bin/zeek -i dummy0 local "Site::local_nets += {192.168.1.0/24 }" &

#---------------------  o.sh - this works!
myip=$(ifconfig eth0 | grep inet | awk {'print $2'})
myether=$(ifconfig eth0 | grep ether | awk {'print $2'})
mysubnet=$(ifconfig eth0 | grep inet | awk {'print $2'} | awk -F. {'print $1"."$2".0.0"'})
#connectip=$(arp -a | grep connect | awk {'print $2'} | sed -e 's/.*(\(.*\))/\1/')
connectip=$(python -c "import socket;addr1 = socket.gethostbyname('connect');s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect((addr1,8083));print(addr1)")
connectmac=$(arp -a | grep connect | awk {'print $4'})
input="/pcaps/syslog.pcap"
output="/pcaps/edited_syslog.pcap"
/usr/bin/tcprewrite  \
 --dstipmap 192.168.1.107:$connectip \
 --srcipmap 192.168.1.0/24:$mysubnet/16 \
 --infile=$input \
 --outfile=$output \
 --enet-dmac=$connectmac \
 --fixcsum
#-----------------------------------------

/usr/bin/tcpreplay -i dummy0 --loop=1000000 /pcaps/zeek_streamer.pcap &
/usr/bin/tcpreplay -i eth0 --loop=1000000 $output &
tail -f /dev/null
exec "$@"
