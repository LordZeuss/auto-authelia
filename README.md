# Auto-Authelia

![GitHub last commit](https://img.shields.io/github/last-commit/lordzeuss/auto-authelia?style=flat-square)
![GitHub Repo stars](https://img.shields.io/github/stars/lordzeuss/auto-authelia?style=social)

A script that will configure authelia automatically. See future plans of adding features below.

## General Info
I created a script that will install Nginx Proxy Manager via docker-compose, as well as Authelia and will give you prompts to quickly get Authelia up and running as quickly as possible.

## Future Plans:

* Adding reverse proxy installation and assisted or fully automated configuration for multiple reverse proxy solutions. Mainly NGINX and traefik. I need to learn how these work so I can add it to the script.
* Embedded video on how the to run the scripts, and using them with NPM & Caddy. For demo purposes as well as a short how-to.
* Add a section to this README regarding email setup (since I have now added the ability to configure email setup, I want to give an example for guidance).

#### UPDATE 3/26: NPM & Caddy (setup for caddy) script added! 
#### UPDATE 7/16: Added the option to install caddy via docker instead of only on bare metal.
#### UPDATE 8/28: BIG UPDATE! I have added the ability to configure email/smtp for sending password resets!
---

## Table of Contents
* [General Info](#general-info)
* [Basic Commands](#basic-commands)
* [Pre-Requirements](#pre-requirements)
* [Installation](#installation)
* [Configuring Protected Services](#configuring-protected-services)
* [NGINX Proxy Manager Setup](#nginx-proxy-manager-setup)
* [Caddy Setup](#caddy-setup)
* [Starting Authelia](#starting-authelia)
---

## Pre-Requirements

You will need:
  - Docker
  - Docker-Compose
  - Git
  
***NOTE: Check out my raspi-docker repository to auto install docker & docker compose!***

---

 ## Installation
 
 To start the installation process, first clone the repo.
 
 ```
 git clone https://github.com/lordzeuss/auto-authelia
 ```
 
Next, navigate to the new folder.

```
cd auto-authelia
```

Now, run the `setup.sh` to configure authelia, or run `proxy-setup.sh` to choose from a list of proxies to pre-configure.
```
./setup.sh
```
```
./proxy-setup.sh
```

---

## Important Notes

The script will ask initially prompt you to update the system if needed. It will then prompt you to fill in information that is required by authelia.

You will want to make sure that you already have docker & docker-compose installed because at one point in the script where it prompts you to automatically hash the admin password, it will run the authelia docker container to hash the password.

Optionally, you can manually hash the password yourself.


---

## Configuring Protected Services

How do I protect my services behind authelia?

Navigate to the auto-authelia folder, and go into the config folder.

Optionally, run this command:


```
cd /home/$USER/auto-authelia/authelia/config
```

Next, you will need to open the configuration file in a text editor of your choice. Usually vi/vim/nano.

```
nano configuration.yml

OR

nano /home/$USER/auto-authelia/authelia/config/configuration.yml
```

Scroll down in the document. You will notice that there is some example services such as "service.example.com"


#### One factor vs Two factor authentication
One factor authentication means that once you login with a user/pass to authelia, you will have access to your service.

Two factor authentication will prompt you for a one time token, using a common app such as Duo/Google autheticator or similar.

***NOTE: When setting up for two factor auth, and trying to access that service for the first time, Authelia will give you QR code in order to setup your two factor auth app of choice.***

#### Adding services to protect

You will need to replace the placeholders ("service.example.com") with your services. You can always add a new line if needed. I provided a few examples as default, add or remove as many as necessary.

Put your service under one or two factor depending on what you prefer. You can also delete the placeholders if you so wish.

#### Configure your reverse proxy

Setting up the service in Authelia is as simple as adding the service to the configuration.yml file. The more "Challenging" part can be configuring it with your reverse proxy.

Authelia has documentation on implimenting it for different proxies. I have provided NPM instructions and Caddy instructions, and I just switched from NPM to Caddy myself, as I'd rather add a few lines to the Caddyfile rather than use NPM and go through all the steps.

---

## NGINX Proxy Manager Setup

First, install NPM. (I have plans to impliment a way to install/give option to install in the future.)

Next, you will need to add the Proxy Host as normal for a reverse proxy.

#### **Under the Advanaced tab:**

You will need to add the following text, but replace a few parts:

```
location /authelia {
    internal;
    set $upstream_authelia http://IPOFAUTHELIASERVER:9091/api/verify; #ADD YOUR IP AND PORT OF AUTHELIA
    proxy_pass_request_body off;
    proxy_pass $upstream_authelia;    
    proxy_set_header Content-Length "";
 
    # Timeout if the real server is dead
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    client_body_buffer_size 128k;
    proxy_set_header Host $host;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr; 
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-Uri $request_uri;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_redirect  http://  $scheme://;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_cache_bypass $cookie_session;
    proxy_no_cache $cookie_session;
    proxy_buffers 4 32k;
 
    send_timeout 5m;
    proxy_read_timeout 240;
    proxy_send_timeout 240;
    proxy_connect_timeout 240;
}
 
    location / {
        set $upstream_SERVICENAME http://IPOFSERVICE:PORT;  #ADD IP AND PORT OF SERVICE
        proxy_pass $upstream_SERVICENAME;  #change name of the service
 
        auth_request /authelia;
        auth_request_set $target_url $scheme://$http_host$request_uri;
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        error_page 401 =302 https://AUTH.EXAMPLE.COM/?rd=$target_url;
 
        client_body_buffer_size 128k;
 
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
 
        send_timeout 5m;
        proxy_read_timeout 360;
        proxy_send_timeout 360;
        proxy_connect_timeout 360;
 
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_redirect  http://  $scheme://;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_cache_bypass $cookie_session;
        proxy_no_cache $cookie_session;
        proxy_buffers 64 256k;
 
        set_real_ip_from REPLACEIPRANGE/16;
        set_real_ip_from 172.0.0.0/8;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;
    }
```

There is 5 things that you will need to replace. You will need to do this for each service in NPM.

**Replace:**

- IPOFAUTHELIASERVER with the ip of the system running authelia. EX: 192.168.1.10
- SERVICENAME has 2 lines next to each other and needs to be replaced with the name of the service. EX: portainer
- IPSERVICE:PORT needs to be replaced with the IP address and port of the service. EX: Portainer runs on 192.168.1.10:9000
- AUTH.EXAMPLE.COM needs to be replaced with the default redirection url that was setup in the script earlier. It should be https://auth.example.com, but you only need to replace the AUTH.EXAMPLE.COM portion.
- REPLACEIPRANGE will need the range of your network. Is usually something like: 192.168.1.0/16

#### Correct configuration example:

```
location /authelia {
    internal;
    set $upstream_authelia http://192.168.1.10:9091/api/verify; #ADD YOUR IP AND PORT OF AUTHELIA
    proxy_pass_request_body off;
    proxy_pass $upstream_authelia;    
    proxy_set_header Content-Length "";
 
    # Timeout if the real server is dead
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    client_body_buffer_size 128k;
    proxy_set_header Host $host;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr; 
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-Uri $request_uri;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_redirect  http://  $scheme://;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_cache_bypass $cookie_session;
    proxy_no_cache $cookie_session;
    proxy_buffers 4 32k;
 
    send_timeout 5m;
    proxy_read_timeout 240;
    proxy_send_timeout 240;
    proxy_connect_timeout 240;
}
 
    location / {
        set $upstream_portainer http://192.168.1.10:9000;  #ADD IP AND PORT OF SERVICE
        proxy_pass $upstream_portainer;  #change name of the service
 
        auth_request /authelia;
        auth_request_set $target_url $scheme://$http_host$request_uri;
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        error_page 401 =302 https://auth.testwebsite.com/?rd=$target_url;
 
        client_body_buffer_size 128k;
 
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
 
        send_timeout 5m;
        proxy_read_timeout 360;
        proxy_send_timeout 360;
        proxy_connect_timeout 360;
 
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_redirect  http://  $scheme://;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_cache_bypass $cookie_session;
        proxy_no_cache $cookie_session;
        proxy_buffers 64 256k;
 
        set_real_ip_from 192.168.1.0/16;
        set_real_ip_from 172.0.0.0/8;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;
    }
```

# Caddy Setup

Run the proxy-setup.sh script.

```
./proxy-setup.sh
```
Select number 2 for caddy.

Once Caddy is selected, it will automatically install Caddy. 

***NOTE: If you already have Caddy installed and it asks you if you want to overwrite the GPG keychain, you can select yes, or use CTRL+C to skip.***

Once Caddy is installed, you will need to provide the auth root domain, the same as you did with authelia. `EX: auth.yourdomain.com`

The script will create your Caddyfile, inside of the auto-authelia folder.

---
## Caddy Configuration

To add services to be used by caddy, edit the Caddyfile that was just created in the auto-authelia folder.

```
nano Caddyfile
```
The authelia section is already created for you.

You will notice that there is a `service.example.com` section. You will need to replace `service.example.com` with the url you are going to use for the service.

```
EX: portainer.mydomain.com
```
Finally, under the `reverse_proxy` portion, you will need to replace `SERVICEPORTHERE` with the port of the service you are trying to proxy with authelia.

It may look something like this:
```
localhost:9000
```
Or if your service is being ran by another server, and isn't a localhost service, it will look like this:
```
192.168.1.10:9000
```

If you need to add more services, simply copy use the same format as `service.example.com` in another block below. 

Here is an example of two services (using localhost and a IP):
```
auth.example.com {
        reverse_proxy localhost:9091
}

service.example.com {
        forward_auth localhost:9091 {
                uri /api/verify?rd=https://auth.example.com/
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy localhost:8080 {
        }
        
anotherservice.example.com {
        forward_auth localhost:9091 {
                uri /api/verify?rd=https://auth.example.com/
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy 192.168.1.10:9000 {
        }
}
```

---

## Start Caddy

Navigate to the auto-authelia folder if you are not there already.

#### *NOTE: Caddy will only start/stop if you are in the directory where the `Caddyfile` is located. Ours is in the auto-authelia directory.*

To start Caddy:
```
caddy start
```
To stop Caddy:
```
caddy stop
```

#### *NOTE: If you edit the caddy file, just stop and start Caddy again*
---

## Starting Authelia
Navigate to the Authelia folder

```
cd /home/$USER/auto-authelia/authelia
```
Run the docker-compose command to start everything up.

```
docker-compose up -d
```

***NOTE: You will find the 2 factor authentication email inside of a `authelia/config` folder. It will be called `notification.txt`. This is because it is set to save on the system, unless you manually update the email settings in the configuration.yml file to send out an email.***
