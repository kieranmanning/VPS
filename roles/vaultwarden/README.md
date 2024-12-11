# Vaultwarden role
This role creates the following:
1. vaultwarden user and group on the host OS
2. vaultwarden directories to store data
3. a vaultwarden container mounting data from the host

## configuration
This role expects three configuration parameters:
1. fileserver_htpasswd_user: user for basic auth to be stored in htpasswd file
2. filserver_htpasswd_password: password for basic auth to be stored in htpasswd file 
3. fileserver_domain: DNS domain from which the file server will serve content
