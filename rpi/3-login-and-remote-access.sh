#!/bin/bash

echo "--- Login / remote access setup script started ---"

# Change password for pi and root to "..."
# Note that auto-login may need to be re-enabled/configured in `raspi-config` after this change
#cp --backup=numbered /etc/shadow /etc/shadow.original
#grep --invert-match root /etc/shadow.original|grep --invert-match pi > /etc/shadow
#echo 'root:$6$yaOkIn8U$tpFOJfWHDyByYP2fsK9WcTatdIYmimrXfpWiXog1UJy1DWQTQyeQzabzghowXOHWtiW3GxvGgNIVEFQyR3EWZ1:17646:0:99999:7:::' >> /etc/shadow
#echo 'pi:$6$aI.hF3F5$Z7b./vhJ0skB0aqnSlz/YIoOhBdkM3n.qEZ4YOgDFAr/MqtlUGlkvH4NLVOg2o5uHsI3ctFLE3EAPOiSjLFhj/:17646:0:99999:7:::' >> /etc/shadow


# Permit root login via SSH / WinSCP (using password)
#sed -i '/#PermitRootLogin prohibit-password/aPermitRootLogin yes' /etc/ssh/sshd_config


# Enable SSH server by creating specially-named, empty file '/boot/ssh'
touch /boot/ssh
# Alternatively, one should be able to do something like the below steps instead:
#update-rc.d ssh enable
#invoke-rc.d ssh start


# Authorize Jacob's laptop's public key for SSH login (both pi & root users)
SSH_KEY_LAPTOP="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYJKMc+87NvR3iXU0scrzXW22OHkVQ0RUdFIU/N+IXCPPzf/s/5i3JINI9qxbXNnJ25wlIRbOiWdWi5yJIgeFP4kIwMYix5oB63Wtq01rK3SqEb9AmnqyKAb/MfSvbdd+X1dT5LJueI34hUBGDWA8LVTPV9woSzks/XikjYKL2uVG+/BeplrwkHbWtTAq4RyusA/SPTP4vHESEFRYfwgYfU2vIK1JL5j92Gi5jk84TnT1x38yfxK5Rh3k9bZauZy9pRVSUbCUVrGb5LlCNkq0fHZ06aHrWi4Cy9WwYCiqDUtjcJqdaFFw57g2lpzns40ut/RqKOm20Z+toyEkFe9mf jacob@W520-WIN10"

mkdir -p /home/pi/.ssh
echo $SSH_KEY_LAPTOP >> /home/pi/.ssh/authorized_keys
chown -Rc pi.pi /home/pi/.ssh

sudo mkdir -p /root/.ssh
sudo echo $SSH_KEY_LAPTOP >> /root/.ssh/authorized_keys

echo "--- Login / remote access setup script finished ---"
