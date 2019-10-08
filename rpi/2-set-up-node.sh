#!/bin/bash

echo "--- Node.js setup script started ---"

# Install Node Version Manager (nvm) via GitHub
export NVM_DIR=/usr/local/opt/nvm
mkdir -p $NVM_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash

# Set up nvm in current session (to avoid needing to log out/in again)
. $NVM_DIR/nvm.sh

# Install the latest LTS version
nvm install --lts
#DEFAULT_NODE_VERSION=12.11.1
#nvm install $DEFAULT_NODE_VERSION
#nvm alias default $DEFAULT_NODE_VERSION

# Allow root to run npm, et. al.
# See https://stackoverflow.com/questions/51811564/sh-1-node-permission-denied#answer-53270214
npm config set user 0
npm config set unsafe-perm true

# Lazy-load nvm to speed-up login
mv --backup=numbered ~/.bashrc ~/.bashrc.original
cat <<- EOF > ~/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.
alias dir='ls -alhF --color'


# Copied from SO post:
# https://stackoverflow.com/questions/11650840/remove-redundant-paths-from-path-variable#answer-47159781
pathremove() {
    local IFS=':'
    local NEWPATH
    local DIR
    local PATHVARIABLE=\${2:-PATH}
    for DIR in \${!PATHVARIABLE} ; do
        if [ "\$DIR" != "\$1" ] ; then
            NEWPATH=\${NEWPATH:+\$NEWPATH:}\$DIR
        fi
    done
    export \$PATHVARIABLE="\$NEWPATH"
}


export NVM_DIR=$NVM_DIR
NODE_INSTALLATIONS_ROOT_DIR="\$NVM_DIR/versions/node/"
LAST_TOUCHED_NODE_BIN_DIR=\$(ls -1dt \$NODE_INSTALLATIONS_ROOT_DIR/*/bin|head -n 1)
load_nvm() {
    [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

# This gets node & friends into the path but doesn't initialize nvm until needed
lasy_load_nvm() {
    export NVM_BIN=\$LAST_TOUCHED_NODE_BIN_DIR
    export PATH="\$NVM_BIN:\$PATH"
    alias nvm="echo 'Please wait while nvm loads' && unalias nvm && pathremove \$NVM_BIN && unset NVM_BIN && load_nvm && nvm \$@"
}
lasy_load_nvm
EOF


# Install @serialport/list (just because Jacob likes being able to work with serial ports easily)
npm install -g @serialport/list

echo "--- Node.js setup script finished ---"
