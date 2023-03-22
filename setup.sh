#!/bin/bash
clear

echo -e "\e[1;31m
___  ____ _  _ ____    _ _  _ ____ ___ ____ _    _    ____ ____ 
  /  |___ |  | [__     | |\ | [__   |  |__| |    |    |___ |__/ 
 /__ |___ |__| ___]    | | \| ___]  |  |  | |___ |___ |___ |  \ 
                                                                
\e[0m"

#v1.0

#Functions List
update () { yes | sudo apt-get update; }
upgrade () { yes | sudo apt-get upgrade; }

# Update the system
echo -e "\e[1;33mWould you like to update the system (Recommended)? (y/n/e)\e[0m"
echo " "
echo "\e[1;33my=yes | n=no | e=exit-installer.\e[0m"
echo " "

read -n1 yesorno

if [ "$yesorno" = y ]; then
	update
	upgrade
	echo " "
	echo "\e[1;32mUpdate Successful.\e[0m"
	echo " "
elif [ "$yesorno" = n ]; then
	echo " "
	echo "\e[1;33mSkipping...\e[0m"
	echo " "
else
	echo " "
	echo "\e[1;31mNot a valid answer. Exiting...\e[0m"
	exit 1
fi

clear



######################################################################
#
# Start of configuration
#
######################################################################



# Make directories/files for authelia
echo -e "\e[1;33mCreating files and directories for authelia...\e[0m"
echo " "
mkdir -p /home/$USER/auto-authelia/authelia
mkdir -p /home/$USER/auto-authelia/authelia/config
touch /home/$USER/auto-authelia/authelia/docker-compose.yml
touch /home/$USER/auto-authelia/authelia/config/configuration.yml
touch /home/$USER/auto-authelia/authelia/config/users_database.yml


# Verifying that files/directories were created
files=( "/home/$USER/auto-authelia/authelia" "/home/$USER/auto-authelia/authelia/config" "/home/$USER/auto-authelia/authelia/docker-compose.yml" "/home/$USER/auto-authelia/authelia/config/configuration.yml" "/home/$USER/auto-authelia/authelia/config/users_database.yml")

# Loop through the array and check each file or directory
for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        echo -e "\e[1;32mThe file or directory '$file' was created successfully...\e[0m"
    else
        echo -e "\e[1;31mThe file or directory '$file' was not created.\e[0m"
        echo -e "\e[1;31mPlease verify that the script can write to the /home/$USER/auto-authelia/authelia directory.\e[0m"
    fi
done

echo " "
echo " "
echo " "
echo " "
echo -e "\e[1;33mCreating the docker-compose file...\e[0m"
# Create compose file
echo "version: '3.3'
services:
  authelia:
    image: authelia/authelia
    volumes:
      - ./config:/config
    ports:
      - 9091:9091
    restart: unless-stopped
    healthcheck:
      disable: true
    environment:
      - TZ=America/Chicago
    depends_on:
      - redis
  redis:
    image: redis:alpine
    volumes:
      - ./redis:/data
    expose:
      - 6379
    restart: unless-stopped
    environment:
      - TZ=America/Chicago
" >> /home/$USER/auto-authelia/authelia/docker-compose.yml
echo " "
echo -e "\e[1;33mDone.\e[0m"
echo " "

######################################################################

# Creating the configuration file
read -p $'\e[1;36mEnter the Redirect URL [INCLUDE https:// HERE][EX: https://auth.example.com]\e[0m: ' redirecturl
read -p $'\e[1;36mEnter the Root Domain to protect [EX: example.com]\e[0m: ' rootdomain
read -p $'\e[1;36mEnter the Auth root domain [EX: auth.example.com]\e[0m: ' rootauth
read -p $'\e[1;36mDo you prefer Light or Dark mode/theme? [TYPE light OR dark]\e[0m: ' theme



echo "###############################################################
#                   Authelia configuration                    #
###############################################################
server:
  host: 0.0.0.0
  port: 9091
jwt_secret: SECRETREPLACE #Generate a random string
log:
  level: debug
default_redirection_url: $redirecturl #Ex:https://auth.example.com
totp:
  issuer: $rootdomain #EX: example.com
  period: 30
  skew: 1
#duo_api:     ## You can use this api if you want push notifications of auth attempts
#  hostname: api-123456789.example.com
#  integration_key: ABCDEF
#  secret_key: yet-another-long-string-of-characters-and-numbers-and-symbols
authentication_backend:
  password_reset.disable: false
  file:
    path: /config/users_database.yml
    password:
      algorithm: argon2id
      iterations: 1
      salt_length: 16
      parallelism: 8
      memory: 64
      
access_control:
  default_policy: deny
  rules:
    # Rules applied to everyone
    - domain:
        -  AUTHDOMAIN-CHANGEME #Ex: "auth.example.com"
      policy: bypass
    - domain:
        - '"service.example.com"' #Ex: "search.example.com" - Single factor stuff. Only need a Password to authenticate.
        - '"service2.example.com"'
      policy: one_factor
    - domain:
        - '"service3.example.com"' #Ex: "tv.example.com" - Two factor auth. Need a password as well as a OTP to authenticate.
        - '"service4.example.com"'
      policy: two_factor
     
      #      networks:
      #      - 192.168.1.0/24
session:
  name: authelia_session
  # This secret can also be set using the env variables AUTHELIA_SESSION_SECRET_FILE
  secret: SECRETREPLACE2 #Generate long string numb/letters
  expiration: 3600 # 1 hour
  inactivity: 7200 # 2 hours
  domain: $rootdomain # Should match whatever your root protected domain is EX: example.com
    # This secret can also be set using the env variables AUTHELIA_SESSION_REDIS_PASSWORD_FILE
#    password: authelia
regulation:
  max_retries: RETRIES
  find_time: FINDTIME
  ban_time: BANTIME
  
theme: $theme #light or dark
storage:
  encryption_key: SECRETREPLACE3 #Generate long string numb/letters
  local:
    path: /config/db.sqlite3
notifier:
 filesystem:
  filename: /config/notification.txt
  #smtp:
  #  username: <Email Username>
  #  password: <Email Password>
  #  host: <Host: mail.example.com>
  #  port: 110
  #  sender: <youremail.example.com>
  #  subject: "[Authelia] {title}"
    #disable_require_tls: false
    #disable_html_emails: false
    #tls:
    #  server_name: <smtp.example.com>
    #  skip_verify: false
    #  minimum_version: TLS1.2
  ">> /home/$USER/auto-authelia/authelia/config/configuration.yml
  
  
# Formatting the configuration file
sed -i "s/AUTHDOMAIN-CHANGEME/\"$rootauth\"/g" /home/$USER/auto-authelia/authelia/config/configuration.yml
secret=$(LC_CTYPE=C tr -dc 'a-zA-Z' < /dev/urandom | head -c 40)
sed -i "s/SECRETREPLACE/$secret/" /home/$USER/auto-authelia/authelia/config/configuration.yml
sed -i "s/SECRETREPLACE2/$secret/" /home/$USER/auto-authelia/authelia/config/configuration.yml
sed -i "s/SECRETREPLACE3/$secret/" /home/$USER/auto-authelia/authelia/config/configuration.yml
sed -i "s/'/\"/g" /home/$USER/auto-authelia/authelia/config/configuration.yml

echo " "
echo " "
echo -e "\e[1;32mAuthelia configuration file updated.\e[0m"
echo " "
echo " "


######################################################################

# Setting default policy/regulations
echo -e "\e[1;33mHere are the default regulations:\e[0m"
echo -e "\e[1;33m
max_retries: 5
find_time: 2m
ban_time: 10m\e[0m"
echo " "
echo -e '\e[1;36mWould you like to edit those fields? [Y/N]\e[0m: '
read -n1 yesorno
if [ "$yesorno" = y ]; then
  echo " "
  read -p $'\e[1;36mEnter the MAXIMUM amount of retries\e[0m: ' retries
  echo " "
  read -p $'\e[1;36mEnter the Find Time (How many attempts per _)\e[0m: ' findtime
  echo " "
  read -p $'\e[1;36mEnter the Ban Time\e[0m: ' bantime
  echo " "
  echo -e "\e[1;33mUpdating...\e[0m"
  sed -i "s/RETRIES/$retries/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  sed -i "s/FINDTIME/$findtime/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  sed -i "s/BANTIME/$bantime/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  echo " "
  echo -e "\e[1;33mUpdated.\e[0m"
elif [ "$regualtions" = n ]; then
  echo " "
  echo -e "\e[1;33mUsing defaults. Updating...\e[0m"
  sed -i "s/RETRIES/5m/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  sed -i "s/FINDTIME/2m/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  sed -i "s/BANTIME/10m/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  echo " "
  echo -e "\e[1;33mUpdated.\e[0m"
else
  echo " "
  echo -e "\e[1;31mUnknown Input.\e[0m"
  echo -e "\e[1;31mUsing defaults. Updating...\e[0m"
  sed -i "s/RETRIES/5m/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  sed -i "s/FINDTIME/2m/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  sed -i "s/BANTIME/10m/" /home/$USER/auto-authelia/authelia/config/configuration.yml
  echo " "
  echo -e "\e[1;33mUpdated.\e[0m"
fi


######################################################################

# Configuring the users_database.yml file
read -p $'\e[1;36mEnter a username for the admin account\e[0m: ' user
read -p $'\e[1;36mEnter the display name for the admin account\e[0m: ' userdisplay
read -p $'\e[1;36mEnter the email address for the admin account\e[0m: ' useremail

echo " "
echo " "
echo -e "\e[1;36mWould you like to configure and hash the admin password automatically or configure it manually yourself? (a|auto | m|manually)\e[0m"

read -n1 yesorno

if [ "$yesorno" = a ]; then
  echo " "
  read -s -p $'\e[1;36mEnter the password for the admin user\e[0m: ' adminpass
  echo " "
  echo " "
  echo -e "\e[1;33mRunning Authelia docker container to hash password. Please wait...\e[0m"
# Run the docker command and save the output to a variable
  output=$(docker run authelia/authelia:latest authelia crypto hash generate argon2 --password '$adminpass')
# Extract the hash from the output and save it to a variable
  HASHPASS=${output#Digest: }
  sed -i "s/HASHPASS/$secret/" /home/$USER/auto-authelia/authelia/config/users_database.yml
  echo " "
  echo -e "\e[1;32mPassword Updated.\e[0m"
elif [ "$yesorno" = n ]; then
  echo " "
  echo -e "\e[1;33mYou can generate a password at https://argon2.online/ OR run the command: docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'TYPEPASSWORDHERE'\e[0m"
  echo " "
  echo -e "\e[1;33mNavigate to /home/$USER/auto-authelia/authelia/config and edit the configuration.yml file. Replace the HASHPASS string with the hashed password\e[0m"
else
  echo " "
  echo -e "\e[1;33mSkipping...\e[0m"
fi

######################################################################
# Configuring the users_database.yml file

echo " "
echo " "
echo " "
echo -e "\e[1;33mUpdating Users Database file...\e[0m"
echo " "
echo -e "\e[1;33mDone.\e[0m"

echo "users:
  $user: #username for user 1. change to whatever you'd like
    displayname: "$userdisplay" #whatever you want the display name to be
    password: "HASHPASS" #generated at https://argon2.online/
    email: $useremail #whatever your email address is
    groups:
      - admins
  #user2: #Use the above details as a template. Uncomment to use. Add as many users as necessary.
    #displayname: "User2"
    #password: "hashedpasswordhere" #generated at https://argon2.online/ OR docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'TYPEPASSWORDHERE'
    #email: user2@email.com
" >> /home/$USER/auto-authelia/authelia/config/users_database.yml

echo " "
echo " "
echo -e "\e[1;32mAuthelia Configuration Script Complete!\e[0m"
