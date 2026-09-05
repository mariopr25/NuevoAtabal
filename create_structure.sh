#!/bin/bash

# Crear directorios principales
mkdir -p inventory/production inventory/staging group_vars host_vars playbooks roles

# Archivos raíz
touch .gitignore ansible.cfg requirements.yml Vagrantfile generate_vault_pass.sh encrypt_secrets.sh .pre-commit-config.yaml dns_records.txt.j2 README.md

# Inventarios
touch inventory/production/hosts.yml inventory/staging/hosts.yml

# group_vars y host_vars
touch group_vars/all.yml host_vars/vps.yml

# Playbook
touch playbooks/site.yml

# ---------------------------
# Roles y sus archivos
# ---------------------------

# common
mkdir -p roles/common/{tasks,handlers,defaults,files,vars}
touch roles/common/tasks/main.yml roles/common/handlers/main.yml roles/common/defaults/main.yml roles/common/files/20auto-upgrades roles/common/vars/main.yml

# ssh-hardening
mkdir -p roles/ssh-hardening/{tasks,handlers,defaults}
touch roles/ssh-hardening/tasks/main.yml roles/ssh-hardening/handlers/main.yml roles/ssh-hardening/defaults/main.yml

# letsencrypt
mkdir -p roles/letsencrypt/{tasks,handlers,defaults}
touch roles/letsencrypt/tasks/main.yml roles/letsencrypt/handlers/main.yml roles/letsencrypt/defaults/main.yml

# mariadb
mkdir -p roles/mariadb/{tasks,handlers,templates,defaults}
touch roles/mariadb/tasks/main.yml roles/mariadb/handlers/main.yml roles/mariadb/templates/99-moodle.cnf.j2 roles/mariadb/defaults/main.yml

# redis
mkdir -p roles/redis/{tasks,handlers,templates,defaults}
touch roles/redis/tasks/main.yml roles/redis/handlers/main.yml roles/redis/templates/redis.conf.j2 roles/redis/defaults/main.yml

# nginx-php
mkdir -p roles/nginx-php/{tasks,handlers,templates,defaults}
touch roles/nginx-php/tasks/main.yml roles/nginx-php/handlers/main.yml roles/nginx-php/defaults/main.yml
touch roles/nginx-php/templates/nginx.conf.j2 roles/nginx-php/templates/moodle.conf.j2 roles/nginx-php/templates/php.ini.j2 roles/nginx-php/templates/moodle_pool.conf.j2

# moodle
mkdir -p roles/moodle/{tasks,handlers,templates,defaults}
touch roles/moodle/tasks/main.yml roles/moodle/handlers/main.yml roles/moodle/templates/config.php.j2 roles/moodle/defaults/main.yml

# mail
mkdir -p roles/mail/{tasks,handlers,templates,defaults}
touch roles/mail/tasks/main.yml roles/mail/handlers/main.yml roles/mail/defaults/main.yml
touch roles/mail/templates/main.cf.j2 roles/mail/templates/master.cf.j2 roles/mail/templates/dovecot.conf.j2 roles/mail/templates/10-mail.conf.j2 roles/mail/templates/10-ssl.conf.j2 roles/mail/templates/10-auth.conf.j2 roles/mail/templates/15-lda.conf.j2 roles/mail/templates/passwd.j2 roles/mail/templates/spamassassin.cf.j2 roles/mail/templates/opendkim.conf.j2 roles/mail/templates/report-spam.sieve.j2

# monitoring-base
mkdir -p roles/monitoring-base/{tasks,handlers,templates,defaults}
touch roles/monitoring-base/tasks/main.yml roles/monitoring-base/handlers/main.yml roles/monitoring-base/defaults/main.yml
touch roles/monitoring-base/templates/fail2ban.local.j2 roles/monitoring-base/templates/rkhunter.conf.j2 roles/monitoring-base/templates/monitrc.j2

# monitoring-prometheus
mkdir -p roles/monitoring-prometheus/{tasks,handlers,templates,defaults}
touch roles/monitoring-prometheus/tasks/main.yml roles/monitoring-prometheus/handlers/main.yml roles/monitoring-prometheus/defaults/main.yml
touch roles/monitoring-prometheus/templates/prometheus.yml.j2 roles/monitoring-prometheus/templates/mysqld_exporter.cnf.j2 roles/monitoring-prometheus/templates/prometheus.service.j2 roles/monitoring-prometheus/templates/exporter.service.j2

# monitoring-grafana
mkdir -p roles/monitoring-grafana/{tasks,handlers,templates,defaults}
touch roles/monitoring-grafana/tasks/main.yml roles/monitoring-grafana/handlers/main.yml roles/monitoring-grafana/templates/grafana.ini.j2 roles/monitoring-grafana/defaults/main.yml

echo "✅ Estructura de directorios y archivos vacíos creada correctamente."