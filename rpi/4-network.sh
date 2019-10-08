#!/bin/bash

echo "--- Network setup script started ---"

# ------------ Network setup ------------
# eth0 = built-in Ethernet interface can use a static IP address or DHCP (maybe both?)
# wlan0 = built-in wireless (used to simplify troubleshooting / updating)
#        Will use static IP 172.18.18.1/24


cp --backup=numbered /etc/dhcpcd.conf /etc/dhcpcd.conf.original
cat <<- EOF > /etc/dhcpcd.conf
# DHCP is used on the eth0 interface in order to facilitate Internet connection and
# easier access for troubleshooting / support.
#
# Inform the DHCP server of our hostname for DDNS.
hostname

# Use the hardware address of the interface for the Client ID.
clientid

# Persist interface configuration when dhcpcd exits.
persistent

# Rapid commit support.
# Safe to enable by default because it requires the equivalent option set on the server to actually work.
option rapid_commit

# A list of options to request from the DHCP server.
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
# Most distributions have NTP support.
option ntp_servers
# Respect the network MTU. This is applied to DHCP routes.
option interface_mtu

# A ServerID is required by RFC2131.
require dhcp_server_identifier

# Generate Stable Private IPv6 Addresses instead of hardware
slaac private


# Note: dnsmasq should actually be handling all DNS requests, so the only nameserver in
#       /etc/resolv.conf should be localhost / 127.0.0.1. However, if dnsmasq does not start
#       in the correct sequence (i.e. after the interfaces are up) it will fail

# Built-in wired Ethernet
# See https://wiki.archlinux.org/index.php/Dhcpcd#DHCP_static_route(s)
# define static profile
#profile static_eth0
#    static ip_address=172.16.16.1/24
#    static routers=172.16.16.1
#    static domain_name_servers=172.16.16.1 8.8.8.8

# fallback to static profile on eth0
#interface eth0
#    fallback static_eth0


# WiFi
interface wlan0
    static ip_address=172.18.18.1/24
    nohook resolve_conf, wpa_supplicant   # don't touch resolve.conf or start wpa_supplicant

denyinterfaces wlan0                      # don't send DHCP requests

EOF

# Restart DHCP client service per instructions at https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md
sudo service dhcpcd restart

# TODO: Peek back at git history here to see old rc.local script to assign static IPs


# Setup DHCP server for WiFi access point
mv --backup=numbered /etc/dnsmasq.conf /etc/dnsmasq.conf.original 2> /dev/null
cat <<- EOF > /etc/dnsmasq.conf
interface=wlan0             # Use interface wlan0
dhcp-range=172.18.18.100,172.18.18.199,12h # Assign IP addresses from .100 to .199 with a 12 hour lease time
listen-address=172.18.18.1  # Explicitly specify the address to listen on
bind-interfaces             # Bind to the interface to make sure we aren't sending things elsewhere
#domain-needed               # Don't forward short names
#bogus-priv                  # Never forward addresses in the non-routed address spaces.


# (Note: not sure why the following lines are here, except that they were in the default config)
# Delay sending DHCPOFFER and proxydhcp replies for at least the specified number of seconds.
dhcp-mac=set:client_is_a_pi,B8:27:EB:*:*:*
dhcp-reply-delay=tag:client_is_a_pi,2

EOF

sudo chown dnsmasq /var/lib/misc/dnsmasq.leases 2> /dev/null
sudo systemctl reload dnsmasq

# dnsmasq will fail to start until wlan0 / hostapd / dhcpcd are up
# so we make sure that it restarts in that case using `Restart=always` and `RestartSec=20`
cp --backup=numbered /lib/systemd/system/dnsmasq.service /lib/systemd/system/dnsmasq.service.original
cat /lib/systemd/system/dnsmasq.service \
  |grep -v "Restart=" \
  |grep -v "RestartSec=" \
  |sed  '/\[Service\]/aRestart=always\nRestartSec=20' \
  > dnsmasq.service.tmp
mv dnsmasq.service.tmp /lib/systemd/system/dnsmasq.service

# Setup WiFi access point

# hostapd.conf shouldn't exist yet (though the /etc/hostapd dir should), but if it does we'll move it before writing this new one
mv --backup=numbered /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.original 2> /dev/null
# we're going to write to a "template" file that we'll use as input to a program that outputs the actual hostapd.conf,
# replacing `__RPI_WIFI_SSID__` with the actual SSID to use (e.g. "Kanomax-STPC-<last 3 octets of eth0 MAC address>")
cat <<- EOF > /etc/hostapd/hostapd.conf.template
# This is the name of the WiFi interface we configured above
interface=wlan0

# (per RPi4 access-point instructions)
driver=nl80211

# This is the name of the network
ssid=__RPI_WIFI_SSID__

# Use 802.11g (2.4GHz) -- alternatively, we could try ad (60GHz)
hw_mode=g

# Use channel 8 (arbitrarily)
channel=8

# Enable 802.11n (despite not being mentioned in setup instructions)
ieee80211n=1

# Disable Wifi MultiMedia
wmm_enabled=0

# Enable 40MHz channels with 20ns guard interval (???)
#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Accept all MAC addresses
macaddr_acl=0

# Use WPA authentication
auth_algs=1

# Require clients to know the network name
ignore_broadcast_ssid=0

# Use WPA2
wpa=2

# Use a pre-shared key
wpa_key_mgmt=WPA-PSK

# The network passphrase
wpa_passphrase=ultimatemeasurements

# Default to (weak) TKIP for WPA1
wpa_pairwise=TKIP CCMP

# Use AES, instead of TKIP for RSN/WPA2
rsn_pairwise=CCMP



# hostapd event logger configuration
#
# Two output method: syslog and stdout (only usable if not forking to background).
#
# Module bitfield (ORed bitfield of modules that will be logged; -1 = all modules):
# bit 0 (1) = IEEE 802.11
# bit 1 (2) = IEEE 802.1X
# bit 2 (4) = RADIUS
# bit 3 (8) = WPA
# bit 4 (16) = driver interface
# bit 5 (32) = IAPP
# bit 6 (64) = MLME
#
# Levels (minimum value for logged events):
#  0 = verbose debugging
#  1 = debugging
#  2 = informational messages
#  3 = notification
#  4 = warning
#
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2

EOF

# Create /etc/cron.d "minutely" & add it to crontab
mkdir -p /etc/cron.minutely
mv --backup=numbered /etc/crontab /etc/crontab.original
grep -v minutely /etc/crontab.original > /etc/crontab
echo "* * * * * root    cd / && run-parts --report /etc/cron.minutely" >> /etc/crontab
# Add a script to apply changes to SSID based on existance & contents of /etc/hostapd/custom_ssid
cat <<- EOF > /etc/cron.minutely/apply_custom_ssid
#!/bin/bash
HOSTAPD_CONF_TEMPLATE=/etc/hostapd/hostapd.conf.template
HOSTAPD_CONF_FILE=/etc/hostapd/hostapd.conf
SSID_FILE=/etc/hostapd/custom_ssid
SSID_PLACEHOLDER=__RPI_WIFI_SSID__

# Utility functions to facilitate doing literal find/replace with sed
# See https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed
quoteRe() {
    sed -e 's/[^^]/[&]/g; s/\^/\\^/g; \$!a\'\$'\n''\\n' <<<"\$1" | tr -d '\n';
}
quoteSubst() {
    IFS= read -d '' -r < <(sed -e ':a' -e '\$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"\$1")
    printf %s "\${REPLY%\$'\n'}"
}

update_hostapd_config() {
    SSID=\$(cat \$SSID_FILE)
    echo "[\$(date)] Read new SSID to be applied: \$SSID"
    sed -e "s/\$(quoteRe "\$SSID_PLACEHOLDER")/\$(quoteSubst "\$SSID")/" \$HOSTAPD_CONF_TEMPLATE > \$HOSTAPD_CONF_FILE
    rm \$SSID_FILE
}

restart_hostapd() {
    systemctl restart hostapd
    RESTART_HOSTAPD_RETVAL=\$?
}

if [ -f \$SSID_FILE ]; then
    update_hostapd_config
    restart_hostapd
    if [ $RESTART_HOSTAPD_RETVAL ]; then
        echo "Detected failure code in exit status when trying to restart hostapd; going to revert to default SSID=\$DEFAULT_SSID"
        echo \$DEFAULT_SSID > \$SSID_FILE
        update_hostapd_config
        restart_hostapd
        if [ $RESTART_HOSTAPD_RETVAL ]; then
            echo "Even after restoring the default SSID there appears to have been a problem restarting hostapd. Giving up :("
            exit 1
        fi
    fi
fi
EOF
chmod +x /etc/cron.minutely/apply_custom_ssid

# Create another script that applies a unique default SSID when hostapd.conf doesn't exist
cat <<- EOF > /etc/cron.minutely/set_default_ssid
#!/bin/bash
HOSTAPD_CONF_FILE=/etc/hostapd/hostapd.conf
SSID_FILE=/etc/hostapd/custom_ssid

if [[ ! -f \$SSID_FILE && ! -f \$HOSTAPD_CONF_FILE ]]; then
    LAST3MAC=$(ip addr show eth0|grep link/ether|awk '{print $2}'|awk '{split($0,mac,":"); print mac[4] mac[5] mac[6]}')
    DEFAULT_SSID="Kanomax-STPC-\$LAST3MAC"
    echo \$DEFAULT_SSID > \$SSID_FILE
    /etc/cron.minutely/apply_custom_ssid
fi
EOF
chmod +x /etc/cron.minutely/set_default_ssid


# Set hostapd configuration file
# TODO: The `DAEMON_CONF` thing is deprecated / will be going away soon, but it's still what the RPi docs suggest using
sed -i '/#DAEMON_CONF=""/s/.*/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
# If the above doesn't work, we could just do something like this:
#    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd

# Looks like in Raspbian 2019-04 & 2019-07 the hostapd service is "masked" by default
# So you need to "unmask" it before it will start -- See /usr/share/doc/hostapd/README.Debian
# https://raspberrypi.stackexchange.com/questions/95916/why-is-hostapd-masked-after-installation
# https://github.com/raspberrypi/documentation/pull/1097/files#diff-bab12433eaae7aea98b21a2978c8ba52R223
sudo systemctl unmask hostapd.service
sudo systemctl enable hostapd.service
sudo systemctl start hostapd.service


# Force use of IPv4 instead of IPv6 if your ISP / network administrator has broken it
#cat <<- EOF >> /etc/gai.conf
## Work-around for IPv6 problems -- see https://unix.stackexchange.com/questions/9940/convince-apt-get-not-to-use-ipv6-method#comment12930_9940
#precedence ::ffff:0:0/96  100
#EOF

# Enable routing & masquerade (so Wi-Fi clients can share the wired connection)
# /etc/sysctl.conf contains two lines like this:
#  # Uncomment the next line to enable packet forwarding for IPv4
#  #net.ipv4.ip_forward=1
# and we want to uncomment the second one:
sed -i '/net\.ipv4\.ip_forward=1/s/^#//' /etc/sysctl.conf
# Enable forwarding now (to avoid needing to reboot to take advantage of this / test this)
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "--- Network setup script finished ---"
