# Fileserver role
This role creates the following:
1. file server user and group on the host OS
2. file server directories to store data
3. a basic NGINX fileserver security with basic auth and a htpasswd file

## configuration
This role expects three configuration parameters:
1. vaultwarden_domain: the DNS domain which the vaultwarden instance is served from
2. vaultwarden_backup: whether to run backup scripts
3. vaultwarden_remote_backup_host: a remote network location to backup to
