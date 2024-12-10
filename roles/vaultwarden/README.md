# Vaultwarden role
This role creates the following:
1. vaultwarden user and group on the host OS
2. vaultwarden directories to store data
3. a vaultwarden container mounting data from the host

## prerequisites
This role expects to find a vaultwarden_domain variable corresponding to the domain vaulwarden will be served from
