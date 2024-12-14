# VPS configuration
This repo contains the playbooks used to configure a VPS and a second host on a tailscale network to act as a backup target.

## Setup
In order to run these playbooks you'll need some prerequisites. First, we need an ansible vault file
to contain our secrets. This can go into group_vars/all.yml with the following keys:

```
VAULTWARDEN_YUBICO_CLIENT_ID: <client ID>
VAULTWARDEN_YUBICO_SECRET_KEY: <secret key>
VAULTWARDEN_PRIMARY_DOMAIN: <domain>
VAULTWARDEN_SECONDARY_DOMAIN: <domain>
VAULTWARDEN_REMOTE_BACKUP_HOST: <host fqdn>
ADMIN_EMAIl: <email>
TAILSCALE_AUTHKEY: <key>
```

Next, we need a host file with the following format:

```
[vaultwarden:children]
vps
pi

[pi]
<tailscale raspberry pi fqdn>

[vps]
<VPS fqdn >
```

You will also need an ssh key for connecting to both hosts mentioned in the hosts file. 

Lastly, for convenience it helps to create a password file for our vault secret file in ```group_vars/all.yml```. Filename ```vault_password_file``` is already included in .gitignore

## Bootstrapping
The playbooks included in this repo assume that there is an ansible sudo use present to run sudo commands. 
This user can be setup by running the ```bootstrap.yml``` playbook first. 

## Additional Steps
Currently, remote backups require a .ssh/config file and an ssh key under the ansible user
to allow the primary host to ssh/rsync to the secondary.


## Running the playbooks
Assuming the above prerequisites have been met, the playbooks can be run in check mode as follows:

``` ansible-playbook -i hosts deploy.yml --private-key id_rsa  --vault-password-file vault_password_file --check```