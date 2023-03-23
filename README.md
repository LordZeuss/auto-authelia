# Auto-Authelia
A script that will configure authelia automatically. See future plans of adding features below.

## General Info
I created a script that will install Nginx Proxy Manager via docker-compose, as well as Authelia and will give you prompts to quickly get Authelia up and running as quickly as possible.

## Future Plans:

* Adding reverse proxy installation and assisted or fully automated configuration for multiple reverse proxy solutions. Caddy. NGINX, Traefik, etc.
* Adding the ability to setup the email portion in authelia config
* Embedded video on how the to run the scripts, and using them with NPM. For demo purposes as well as a short how-to.
---

## Table of Contents
* [General Info](#general-info)
* [Basic Commands](#basic-commands)
* [Pre-Requirements](#pre-requirements)
* [Installation](#installation)
* [Configuring Protected Services](configuring-protected-services)
* [Reverse Proxy Setup](reverse-proxy-setup)
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

Currently, you will need to make the script executable.

```
chmod +x setup.sh
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

Authelia has documentation on implimenting it for different proxies, but I will provide instructions on Nginx Proxy Manager (NPM) as that is what I personally use, and I have the most experience with that.

---

## Reverse Proxy Setup

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
