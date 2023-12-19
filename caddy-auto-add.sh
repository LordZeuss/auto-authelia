#!/bin/bash

# Pull data from the config.txt file
source config.txt

read -p "Service: " url
read -p "IP:PORT: " service

echo "$url.$rootdomain {
        forward_auth localhost:9091 {
                uri /api/verify?rd=$authdomain
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy $service {
        }
}
" >> /home/$USER/auto-authelia/Caddyfile