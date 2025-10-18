#!/bin/bash

# Definir archivos de cron y sus permisos esperados
declare -A cron_paths=(
    ["/etc/crontab"]="600:root:root"
    ["/etc/cron.hourly"]="700:root:root"
    ["/etc/cron.daily"]="700:root:root"
    ["/etc/cron.weekly"]="700:root:root"
    ["/etc/cron.monthly"]="700:root:root"
    ["/etc/cron.d"]="700:root:root"
)

echo -e "${BLUE}[*] Permisos de los archivos del servicio Cron${RESET}"
if ! dpkg -s cron &>/dev/null; then
    echo -e "${PINK}[!] Cron no está instalado en el sistema.${RESET}"
    echo -e "\e[33m[!]Instalar y habilitar Cron si es necesario.${RESET}"
else
    echo -e "${GREEN}[+] Cron instalado"
    counter=$((counter + 1))

    # Verificar el estado del servicio cron
    cron_enabled=$(systemctl is-enabled cron)
    cron_activated=$(systemctl is-active cron)

    [[ $cron_enabled == "enabled" ]] && {
        echo -e "\e[32m[+] Cron: $cron_enabled${RESET}"
        counter=$((counter + 1))
    } || echo -e "${PINK}[!] Cron: $cron_enabled${RESET}"
    
    [[ $cron_activated == "active" ]] && {
        echo -e "\e[32m[+] Cron: $cron_activated${RESET}\n"
        counter=$((counter + 1))
    } || echo -e "${PINK}[!] Cron: $cron_activated${RESET}\n"

    # Iterar sobre cada archivo y verificar permisos
    for file in "${!cron_paths[@]}"; do
        expected_permissions="${cron_paths[$file]}"
        actual_permissions=$(stat -c "%a:%U:%G" "$file" 2>/dev/null)

        echo "Permisos de $file:"
        if [[ "$actual_permissions" == "$expected_permissions" ]]; then
            echo -e "\e[32m[+] $actual_permissions${RESET}\n"
            counter=$((counter + 1))
        else
            echo -e "${PINK}[-] $actual_permissions \e[33m-> $expected_permissions${RESET}\n"
        fi
    done

    echo -e "\e[33m[!] Habilitar Cron si es necesario.${RESET}"

fi
