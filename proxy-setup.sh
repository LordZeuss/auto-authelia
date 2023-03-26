#!/bin/bash
clear

echo -e "\e[1;31m
___  ____ _  _ ____    _ _  _ ____ ___ ____ _    _    ____ ____ 
  /  |___ |  | [__     | |\ | [__   |  |__| |    |    |___ |__/ 
 /__ |___ |__| ___]    | | \| ___]  |  |  | |___ |___ |___ |  \ 
                                                                
\e[0m"



echo " "
echo -e "\e[1;33mSelect an option to install & configure: \e[0m"
echo "1. Nginx Proxy Manager"
echo "2. Caddy"
echo "3. Exit"
echo " "

read -p "Enter your selection: " chooseproxy

case $chooseproxy in
  1)
    # Create NPM directory & docker-compose file
    mkdir -p /home/$USER/auto-authelia/nginx-proxy-manager
    touch /home/$USER/auto-authelia/nginx-proxy-manager/docker-compose.yml

    # Appending docker-compose code into the file
    echo "version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt" >> /home/$USER/auto-authelia/nginx-proxy-manager/docker-compose.yml
      
    echo " "
    echo " "
    echo -e "\e[1;33mMake sure you port forward ports 80 and 443 from your router to the device hosting Nginx Proxy Manager\e[0m"
  
    echo " "
    echo " "

    # Start NPM [Y/N]
    read -p "Would you like to start Nginx Proxy Manager via docker-compose? [Y/N] " npmstart

if [ "$npmstart"  = y ]; then
  echo " "
  echo -e "\e[1;33mStarting Nginx Proxy Manager. When launched it will be found at http://YOURIP:81\e[0m"
  echo " "
  echo " "
  cd /home/$USER/auto-authelia/nginx-proxy-manager
  docker-compose up -d
  echo " "
  echo -e "\e[1:32mDone.\e[0m"
elif [ "$npmstart" = n ]; then
  echo " " 
  echo -e "\e[1;31mNot starting Nginx Proxy Manager.\e[0m"
  echo " "
else
  echo -e "\e[1;31mInvalid command. Not starting Nginx Proxy Manager by default\e[0m."
fi
    ;;
  2)
    #Caddy install
    echo " "    
    echo " "
    echo -e "\e[1;33mInstalling Caddy. Please wait...\e[0m"
    echo " "
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    
    sudo apt update
    sudo apt install caddy
    echo " "
    echo -e "\e[1;32mDone.\e[0m"
    echo " "
    echo " "
    echo -e "\e[1;33mCreating Caddyfile for Caddy...\e[0m"

    echo " "
    echo " "
    touch /home/$USER/auto-authelia/Caddyfile

    read -p "Enter the auth root domain [EX: auth.example.com] (SAME AS AUTHELIA SETUP ROOT DOMAIN): " rootauthdomain

    echo "$rootauthdomain {
        reverse_proxy localhost:9091
}

service.example.com {
        forward_auth localhost:9091 {
                uri /api/verify?rd=https://$rootauthdomain/
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy localhost:SERVICEPORTHERE {
        }
}" >> /home/$USER/auto-authelia/Caddyfile

echo " "
echo -e "\e[1;32mDone.\e[0m"
echo " "
echo -e "\e[1;33mYou will need to edit the Caddyfile for your services. There is a service.example.com there to provide a example.\e[0m"
echo -e "\e[1;33mVisit the auto-authelia github page for more instructions.\e[0m"
    ;;
  3)
    echo " "
    echo -e "\e[1;31mExiting...\e[0m"
    exit 0
    ;;
  4)
    echo -e "\e[1;31mInvalid choice. Please select a valid option.\e[0m"
    ;;
esac
