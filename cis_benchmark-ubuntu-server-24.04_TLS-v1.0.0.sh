#!/usr/bin/bash

source "$(dirname "$0")/constantes/Colores.sh"
source "$(dirname "$0")/vars/counter.sh"

# Services - Configure Server and Clients Services
source 1_config_server_clients_services.sh

echo -e "\n"

# Job Schedulers - Configure Cron
source 2_config_cron_permissions.sh

echo -e "\n"

# Host Based Firewall - Configure firewall
source 3_config_firewall.sh

echo -e "\n"

# Access Control - Configure SSH Server
source 4_config_ssh_server.sh

echo -e "\n"

# Access Control - Configure privilige escalation
source 5_config_privilage_escalation.sh

echo -e "\n"

# Configure root and system accounts and environmen
source 6_config_root_system_envs_accounts.sh

echo -e "\n"

# System Maintenance - Local User and Group Settings
source 7_config_usersgroups_local.sh

echo -e "\n"

# System Maintenance - System file permission
source 8_config_system_file_permissions.sh

echo $counter
resultado=$(calcular_porcentaje "$counter")
echo "Porcentaje de seguridad: $resultado"