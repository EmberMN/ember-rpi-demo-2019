#!/bin/bash

echo "--- Package management script started ---"

### Preparation
# Make sure packages (like iptables-persistent) don't prompt for user input here
export DEBIAN_FRONTEND=noninteractive

# Add GPG key & apt repository for yarn packager
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Update package information
apt update

### Remove some packages we don't want/need
## (probably not needed if using the "Lite" or "Desktop" Raspian image as a base)

# Remove libreoffice
apt remove --yes *libreoffice*

# Remove Wolfram Mathematica (it's only for non-commercial use anyway)
apt remove --yes --purge wolfram-engine

# Remove unneeded Python IDE (esp. since it was broken at the time of writing)
apt remove --yes python3-thonny python3-thonny-pi sense-emu-tools thonny

# Remove the stock version of NodeJS
apt remove --yes nodejs nodejs-legacy libuv1 nodered



### Upgrade installed packages to latest versions
apt upgrade --yes



### Install more stuff
# Install the "yarn" package management tool (but don't re-install the stock nodejs package)
apt install --no-install-recommends yarn

# Make sure we have an SSH server installed (should already be present though)
apt install --yes openssh-server

# Install some handy (though not necessary) packages
apt install --yes htop vim picocom socat netcat iotop dnsutils net-tools hexedit tcpdump wireshark \
                  lsof ntpdate jq whois vim xscreensaver nmap dhcpdump ncftp links lynx \
                  php-common php-fpm php7.3-cli php7.3-common php7.3-fpm php7.3-json php7.3-opcache php7.3-readline \
                  gddrescue aptitude locate

# Install packages for operating as a Wi-Fi access point
apt install --yes dnsmasq hostapd bridge-utils

# TODO: Use NFtables instead of iptables + iptables-persistent (but they work for now)
# Install packages for managing firewall / port-forwarding rules
apt install --yes iptables-persistent

# Install nginx web server (and all available modules for it, even though we don't need them)
apt install --yes nginx-common nginx-extras libnginx-mod-*



### Clean-up
# Remove automatically installed but no longer needed packages
apt autoremove --yes


echo "--- Package management script finished ---"
