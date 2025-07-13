#!/usr/bin/bash

source "$(dirname "$0")/constantes/Colores.sh"

# Services - Configure Server and Clients Services
source config_server_clients_services.sh

echo -e "\n"

# Job Schedulers - Configure Cron
source config_cron_permissions.sh

echo -e "\n"

# Host Based Firewall - Configure firewall
source config_firewall.sh

echo -e "\n"

# Access Control - Configure SSH Server
source config_ssh_server.sh

echo -e "\n"

# Access Control - Configure privilige escalation
source config_privilage_escalation.sh

echo -e "\n"

# Configure root and system accounts and environmen
source config_root_system_envs_accounts.sh

echo -e "\n"

# System Maintenance - Local User and Group Settings
source config_usersgroups_local.sh

echo -e "\n"

# System Maintenance - System file permission
source config_system_file_permissions.sh
