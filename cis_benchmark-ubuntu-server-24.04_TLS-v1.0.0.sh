#!/usr/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Permiso denegado $0" >&2
    exit 1
fi

LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"
ERROR_LOG="$LOG_DIR/errors.log"
: > "$ERROR_LOG"

# Redirigir todos los errores de los scripts fuente a errors.log
exec 2> >(tee -a "$ERROR_LOG" >&2)

print_help() {
    cat <<'EOF'
Usage: ./cis_benchmark-ubuntu-server-24.04_TLS-v1.0.0.sh [OPCIONES]

Opciones:
  -h, --help         Muestra esta ayuda.
  --solutions        Soluciones de configuración.
EOF
}

PARSED=$(getopt -o h --long help -- "$@")
if [ $? -ne 0 ]; then
    exit 2
fi
eval set -- "$PARSED"

while true; do
    case "$1" in
        (-h|--help)
            print_help
            exit 0
            ;;
        (--)
            shift   # quitar el separador "--"
            break   # salir del bucle de opciones
            ;;
        (*)
            # no debería ocurrir
            echo "Opción desconocida: $1" >&2
            exit 3
            ;;
    esac
done

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