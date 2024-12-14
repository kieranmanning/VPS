#!/bin/bash

# set backup directory base dir to one used by ansible cronjob
BACKUP_BASE_DIR="{{ vaultwarden_backup_path }}"

DAY_OF_WEEK=$(date +"%w")
TODAY_FOLDER="${BACKUP_BASE_DIR}/${DAY_OF_WEEK}"

# First backup to localhost
rsync -avp --omit-dir-times "{{ vaultwarden_base_path }}/data" "${TODAY_FOLDER}/" 

# Then backup to remote backup location for today
rsync -avp --omit-dir-times "{{ vaultwarden_base_path }}/data" "ansible@{{ vaultwarden_remote_backup_host }}:${TODAY_FOLDER}/" 

# Then sync running primary vaultwarden with secondary vaultwarden
ssh ansible@{{ vaultwarden_remote_backup_host }} -t "sudo docker stop vaultwarden"
rsync -avp --omit-dir-times {{ vaultwarden_base_path }}/data "ansible@{{ vaultwarden_remote_backup_host }}:{{ vaultwarden_base_path }}/data"
ssh ansible@{{ vaultwarden_remote_backup_host }} -t "sudo docker start vaultwarden"