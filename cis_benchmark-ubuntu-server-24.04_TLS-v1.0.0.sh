#!/usr/bin/env bash

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Update server
#apt update
#apt dist-upgrade -y

# Services - Configure Server and Clients Services
source config_server_clients_services.sh

echo -e "\n"

# Job Schedulers - Configure Cron
source config_cron_permissions.sh

echo -e "\n"

# Host Based Firewall - Configure UFW
source config_firewall.sh

echo -e "\n"

# Access Control - Configure SSH Server
source config_ssh_server.sh

echo -e "\n"

# Local User and Group Settings
source config_usersgroups_local.sh

echo -e "\n"

# Access Control - Configure privilige escalation
source config_privilage_escalation.sh
