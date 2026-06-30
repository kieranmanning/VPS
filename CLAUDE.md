# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Ansible playbooks/roles that provision and deploy services onto two hosts: a public VPS and a
Raspberry Pi reachable over Tailscale (used as a secondary host / backup target). There is no
application code here — everything is infrastructure-as-code (YAML tasks, Jinja2 templates for
nginx configs and shell scripts).

## Required local files (gitignored, not in repo)

These files must exist locally before running any playbook, and must never be committed:
- `hosts` — Ansible inventory; defines `[vps]` and `[pi]` groups under a `vaultwarden:children` group.
- `group_vars/all.yml` — Ansible Vault–encrypted file holding secrets (Vaultwarden/Yubico keys,
  domains, AWS/Cognito/Django/Postgres/coturn secrets, `TAILSCALE_AUTHKEY`, `ADMIN_EMAIL`, etc.)
  referenced via `{{ VAR_NAME }}` throughout the roles and playbooks.
- `id_rsa` — SSH private key used to connect to both hosts.
- `vault_password_file` — password for decrypting `group_vars/all.yml`.

See `README.md` for the exact vault key list and inventory format expected.

## Commands

Install role/collection dependencies (Galaxy roles listed in `requirements.yml`):
```
ansible-galaxy install -r requirements.yml
```

Bootstrap a fresh host (creates the `ansible` sudo user used by every other playbook):
```
ansible-playbook -i hosts bootstrap.yml --private-key id_rsa --vault-password-file vault_password_file
```

Dry-run the main deploy playbook (Vaultwarden + Tailscale + nginx + security hardening):
```
ansible-playbook -i hosts deploy.yml --private-key id_rsa --vault-password-file vault_password_file --check
```
Drop `--check` to actually apply. Limit to one host with `--limit vps` or `--limit pi`.

Deploy the TransparenC app stack (separate playbook, VPS only):
```
ansible-playbook -i hosts deploy_tranparenc.yml --private-key id_rsa --vault-password-file vault_password_file
```

Syntax-check a playbook without an inventory/vault available:
```
ansible-playbook deploy.yml --syntax-check
```

There is a Molecule-style test fixture for the TransparenC role at
`roles/TransparenC/tests/test.yml` (runs the role against `localhost`), but no test runner is wired
up — invoke it manually with `ansible-playbook` if needed.

## Architecture

**Two playbooks, two host groups, shared roles:**
- `bootstrap.yml` — runs as `root`, creates the `ansible` user (via `bootstrap-ansible` role) that
  every subsequent playbook connects as. Run once per new host.
- `deploy.yml` — has two plays, one per host group:
  - `pi`: docker, tailscale, `pi-tailscale-certs` (mints TLS certs via `tailscale cert`), nginx,
    `vaultwarden`, security hardening, `misc-tooling`. This is the Vaultwarden *secondary/backup*
    instance (`vaultwarden_backup: false`).
  - `vps`: docker, tailscale, nginx, `vaultwarden`, certbot (Let's Encrypt), security hardening.
    This is the Vaultwarden *primary* instance (`vaultwarden_backup: true`) and also serves the
    static `kmanning.ie` site via an `nginx_vhosts` entry.
- `deploy_tranparenc.yml` — separate playbook, VPS only, deploys the TransparenC docker stack
  (Postgres, coturn, Django backend, frontend) behind its own nginx vhost.

**Roles** (`roles/`):
- `bootstrap-ansible` — creates the `ansible` system user, authorizes `id_rsa.pub`, grants
  passwordless sudo.
- `vaultwarden` — creates the vaultwarden user/dirs, runs the Vaultwarden container, drops the
  nginx vhost. `tasks/main.yml` conditionally includes `tasks/backups.yml` when
  `vaultwarden_backup: true`, which installs postfix/mail and a cron-driven backup script
  (`templates/vaultwarden-backup.j2`) that rsyncs data locally and to
  `vaultwarden_remote_backup_host` over SSH as the `ansible` user, then restarts the remote
  container. Requires SSH key trust between the VPS and Pi under the `ansible` user (see README).
- `pi-tailscale-certs` — wraps `tailscale cert` to issue certs for the Pi's Vaultwarden vhost
  (used instead of certbot since the Pi isn't publicly reachable for HTTP-01 challenges).
- `fileserver` — basic-auth nginx file server role (htpasswd via `community.general.htpasswd`);
  not currently wired into either playbook.
- `misc-tooling` — installs baseline packages (git, vim) on the Pi.
- `TransparenC` — deploys the TransparenC/Intercom app: postgres, coturn (TURN/STUN for
  WebRTC), a Django backend container (`docker.kmanning.ie:5000/intercom-api`), and a frontend
  container (`docker.kmanning.ie:5000/intercom-frontend`), all on a shared `transparenc` docker
  network, plus an nginx vhost that proxies `/` and `/ws/` to the frontend container. Images are
  pulled from a private registry (`docker_login` task) — requires `DOCKER_REGISTRY_USER` /
  `DOCKER_REGISTRY_PASSWORD` vault vars.

**Conventions used across roles:**
- Each custom role follows the standard `defaults/`, `tasks/`, `templates/`, `meta/` (Galaxy role
  dependencies), `handlers/` layout.
- System users/dirs are created idempotently before any container or config is dropped.
- nginx vhosts are rendered from Jinja2 templates into `/etc/nginx/conf.d/*.conf` and trigger a
  `reload nginx` (or `restart nginx`) handler — never a full nginx role rewrite.
- Docker is used directly via `community.docker` modules (`docker_container`, `docker_network`,
  `docker_volume`) rather than docker-compose.
- Secrets are never hardcoded — always passed down from `group_vars/all.yml` (vault) through
  playbook `vars:` into role variables.
