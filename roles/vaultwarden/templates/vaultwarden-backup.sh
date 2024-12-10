#!/bin/bash

# set backup directory base dir to one used by ansible cronjob
BACKUP_BASE_DIR="{{ vaultwarden_backup_path }}"

DAY_OF_WEEK=$(date +"%w")
TODAY_FOLDER="${BACKUP_BASE_DIR}/${DAY_OF_WEEK}"


rsync -ah "{{ vaultwarden_base_path }}"/data "${TODAY_FOLDER}/" 