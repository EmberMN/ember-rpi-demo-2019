#!/bin/bash
# This script should be run as root to prepare a Raspberry Pi (4 B)
# Before running it, the RPi configuration tool should be used to set locale (timezone, language, keyboard, etc.),
# hostname, and the following options:
#   Boot Options ->
#      B1 Desktop / CLI = Console
#      B3 Splash Screen = No
echo "--- Main setup script started ---" #
# It is critical that this file be saved with "Unix" (LF) line-endings to avoid problems executing it on RPi
# The following lines attempt to check this condition and abort if the wrong EOL format is detected
# Note that spaces and (empty) comments are included to avoid problems from \r being appended to the end of these lines
apt update #
apt install --yes dos2unix #
SETUP_SCRIPT=$0 #
dos2unix < "$SETUP_SCRIPT" | cmp -s - "$SETUP_SCRIPT"  #
FILE_HAS_WRONG_EOL=$? #
RED="\033[0;31m"; #
YELLOW="\033[1;33m"; #
NOCOLOR="\033[0m"; #
if [ $FILE_HAS_WRONG_EOL != 0 ]; then #
    echo "*******************************************************************************************************************************" #
    echo -e "${RED}*** ERROR ***${YELLOW} wrong end-of-line format detected ${NOCOLOR}" #
    echo "Please correct $0 EOL (convert to Unix/LF style) and re-run." #
    echo "*******************************************************************************************************************************" #
    exit #
fi #


./1-install-packages.sh || {
  echo "Failed to install packages"
  exit 1
}

./2-set-up-node.sh || {
  echo "Failed to set up node.js"
  exit 2
}

./3-login-and-remote-access.sh || {
  echo "Failed to setup login & remote access"
  exit 3
 }

./4-network.sh || {
  echo "Failed to configure network settings"
  exit 4
}

./5-firewall-rules.sh || {
  echo "Failed to configure firewall rules"
  exit 5
}

./6-nginx.sh || {
  echo "Failed to configure nginx (web server)"
  exit 6
}

./7-run-with-getty.sh || {
  echo "Failed to configure our programs to run via getty"
  exit 7
}

echo "Updating locate database (this may take a little while)"
sudo updatedb

echo "--- Main setup script finished ---" #
