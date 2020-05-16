#!/bin/sh

ip link add dummy0 type dummy
ifconfig dummy0 mtu 3000
ifconfig dummy0 up
/usr/local/zeek/bin/zeek -i dummy0 local "Site::local_nets += {192.168.1.0/24 }" &
/usr/bin/tcpreplay -i dummy0 --loop=100000 /pcaps/zeek_streamer.pcap &
tail -f /dev/null
exec "$@"
