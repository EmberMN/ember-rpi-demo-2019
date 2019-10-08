#!/bin/bash

echo "--- getty setup script started ---"

# Note: systemd seems to care a lot about names, paths, links, etc.
# Run script on alternate tty and switch to that tty on boot via rc.local (assumes no X session running)
cat <<- EOF > /lib/systemd/system/getty@tty2.service
# Custom service to launch our program
[Unit]
Description=Ember RPi demo back-end (WebSocket server)
After=systemd-user-sessions.service plymouth-quit-wait.service
After=rc-local.service

# If additional gettys are spawned during boot then we should make
# sure that this is synchronized before getty.target, even though
# getty.target didn't actually pull it in.
Before=getty.target
IgnoreOnIsolate=yes

# On systems without virtual consoles, don't start any getty. Note
# that serial gettys are covered by serial-getty@.service, not this
# unit.
ConditionPathExists=/dev/tty0

[Service]
# the VT is cleared by TTYVTDisallocate
ExecStart=-/sbin/agetty --autologin root --login-program /usr/local/back-end/run.sh --login-options ""  --noclear %I $TERM
Type=idle
Restart=always
RestartSec=1
UtmpIdentifier=%I
TTYPath=/dev/%I
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
KillMode=process
IgnoreSIGPIPE=no
SendSIGHUP=yes

# Unset locale for the console getty since the console has problems
# displaying some internationalized messages.
Environment=LANG= LANGUAGE= LC_CTYPE= LC_NUMERIC= LC_TIME= LC_COLLATE= LC_MONETARY= LC_MESSAGES= LC_PAPER= LC_NAME= LC_ADDRESS= LC_TELEPHONE= LC_MEASUREMENT= LC_IDENTIFICATION=

[Install]
WantedBy=getty.target
DefaultInstance=tty2

EOF

ln -s /lib/systemd/system/getty@tty2.service /etc/systemd/system/getty.target.wants/getty@tty2.service



cp --backup=numbered /etc/rc.local /etc/rc.local.original 2> /dev/null
cat <<- EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution bits.

# Switch to virtual terminal 2 (where our script should be running on start-up)
chvt 2
EOF
chmod +x /etc/rc.local



echo "--- getty setup script finished ---"
