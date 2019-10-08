#!/bin/bash

echo "--- Firewall setup script started ---"


# TODO: use nftables instead
# https://wiki.nftables.org/wiki-nftables/index.php/Moving_from_iptables_to_nftables

# Set default policies to accept
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P INPUT ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t nat -P POSTROUTING ACCEPT

# Delete all iptables (firewall) rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Allow incoming ssh, DNS, HTTP, and HTTPS connections as well as related/established traffic
# (default policy of ACCEPT would allow this, but we shouldn't rely on that)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 502 -j ACCEPT # Allow Modbus TCP
iptables -A INPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT # Allow DHCP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow all localhost traffic
iptables -A INPUT -i lo -j ACCEPT

# Internet connection sharing (Wi-Fi -> wired connection)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Set input policy to DROP (be just a tiny bit more secure by default)
iptables -P INPUT DROP

# Save rules
mv --backup=numbered /etc/iptables/rules.v4 /etc/iptables/rules.v4.original 2> /dev/null
iptables-save > /etc/iptables/rules.v4


echo "--- Firewall setup script ended ---"
