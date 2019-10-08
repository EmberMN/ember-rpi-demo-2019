#!/bin/bash

echo "--- nginx setup script started ---"

MY_DOMAIN_NAME=jacobq.com

# Create self-signed cert to use for web server
#sudo openssl req -x509 -nodes -days 3650 -subj "/C=US/ST=Minnesota/L=Minneapolis/CN=${MY_DOMAIN_NAME}/subjectAltName=IP:172.18.18.1" -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
# Actually, we'll use a "real" cert instead -- would be nice if we could use Let's Encrypt, but in that case,
# I believe the unit needs to have a public IP, which often isn't practical for embedded devices.

## Setup nginx web server
# Note: you'll have to manually copy the crt (bundle it together with the CA) and key files (too sensitive to put mine in this script)
# ```
# unzip domain_certs.zip
# cat foo.crt foo.ca-bundle > /etc/ssl/certs/foo.crt
# cp foo.key /etc/ssl/private/
# ```

# Associate our wifi IP with our domain name so that browsers using our DNS/AP can easily reach us
grep -v $MY_DOMAIN_NAME /etc/hosts > /etc/hosts # In case this was already run, filter out previously added entry
echo "172.18.18.1     $MY_DOMAIN_NAME www.$MY_DOMAIN_NAME" >> /etc/hosts

# See https://www.techrepublic.com/article/how-to-enable-ssl-on-nginx/
cat <<- EOF >> /etc/nginx/snippets/${MY_DOMAIN_NAME}.conf
ssl_certificate /etc/ssl/certs/${MY_DOMAIN_NAME}.crt;
ssl_certificate_key /etc/ssl/private/${MY_DOMAIN_NAME}.key;
EOF

cat <<- EOF >> /etc/nginx/snippets/ssl-params.conf
ssl_protocols TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/ssl/certs/dhparam.pem;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1;
ssl_session_timeout  10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
#ssl_stapling on;
#ssl_stapling_verify on;
resolver 127.0.0.1 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
EOF

# This can take a LONG time (>1h depending on how unlucky you are),
# so instead of generating a "real one" (cryptographically strong)
# we'll just reuse one generated when developing this script.
# Obviously, one should not do this if security is a concern.
##sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
#sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
cat <<- EOF > /etc/ssl/certs/dhparam.pem
-----BEGIN DH PARAMETERS-----
MIICCAKCAgEAlny1JaXk+TiHhGpCU/4RdY9fYdhKLbttTGnJxVYhQ8YxZKKbnW2T
WYBdZtAMzOXOeA8RcC4/f1kWUAaNvxXtY8CGPBZvsI+PPzwuB2G1F/GzgFv1b6/4
tvYNreXUD/Sp3bMvotd/SG78l8wYHpPbRlsg06LyuOzBXUNNkIxiF3Jc7f6IKSi9
ilUccYE8z1ig67z49/HrKQAq0dayOjpTcOq2uIpodJH8tPjx4fKwD2L8KWllpRTg
anZA+RTQqhKtcc8WwXFh86hIvqLWk1LCUjH6Iyc50p8lRFJr8rsmt21q68f8USVc
q1EbOwU6Osa+dE5HyaPtPLfhwyWzfJzIT9ddGMN94KhtmFmLVKGyjEVefN3e+pyr
rKKoneytnf6k4Z6yetsH5XJdnpUAEDBbcdywwo1XUkODk5U2euE/Tq86zkKyLNv3
CdWGT5OwFvNF2kb1zwODd9A64b6sZQ1KLLBYRbe4J6gaD8nCKJBvCMLRuNzI+tjP
dAjV6t+g4lYNDN+xz3cbAHyoRsksAcxWHfXEE1G3ZDMhSyh4Iwd868YVW2KxYght
T80Z3axrkXFr9Pp9i5oRUS2q4PIHSelBThq/X9wV1EcyzRBcRt74QNZJVLLJvUH9
ALHIwf2pzUh5+jbsyggF6U4jp2l8pwHyq2pBTKb96u/8lrouHWsqgyMCAQI=
-----END DH PARAMETERS-----
EOF


cat <<- EOF > /etc/nginx/sites-available/${MY_DOMAIN_NAME}
server {
    # SSL configuration
    listen 443 ssl;
    listen [::]:443 ssl;
    include snippets/${MY_DOMAIN_NAME}.conf;
    include snippets/ssl-params.conf;

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    server_name ${MY_DOMAIN_NAME} www.${MY_DOMAIN_NAME};

    client_max_body_size 500M;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        #try_files \$uri \$uri/ =404;
        # Naw, we want our Ember app to be able to handle virtual URLs, so go to index.html instead
        try_files \$uri \$uri/ /index.html;
    }

    # Map to updater
    location /updater {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Map to back-end
    location /ws {
        proxy_pass http://127.0.0.1:8010;

        proxy_http_version 1.1;
        proxy_buffering off;
        #proxy_redirect off;
        #proxy_ssl_session_reuse on;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    listen [::]:80;

    server_name default_http;

    return 302 https://${MY_DOMAIN_NAME}\$request_uri;
}

EOF

rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/${MY_DOMAIN_NAME} /etc/nginx/sites-enabled/${MY_DOMAIN_NAME}
sudo systemctl restart nginx

echo "--- nginx setup script finished ---"
