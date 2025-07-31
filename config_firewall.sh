installed_firewalls=0

echo -e "${BLUE}[*] Configuracion de firewall${RESET}"
#firewalls=('ufw' 'nftables' 'iptables' 'iptables-persistent')
firewalls=('ufw' 'nftables')
for frw in "${firewalls[@]}"; do
        if dpkg-query -s $frw &>/dev/null; then
                echo -e "${GREEN}[+] $frw instalado${RESET}"
                ((installed_firewalls++))
        else
                echo -e "${RED}[-] $frw no instalado${RESET}"
        #        if [[ $frw == "iptables-persistent" ]]; then
        #                echo -e "${GREEN}[+] $frw instalado${RESET}"
        #        else
        #                echo -e "\e[31m[-] $frw no instalado${RESET}"
        #        fi
        fi
done

# Arrays para almacenar resultados
active_firewall=()
firewalls=("ufw" "nftables" "iptables")

# Determinar qué firewall está activo
for firewall in "${firewalls[@]}"; do
    case $firewall in
        nftables)
            cmd="nft"
            ;;
        *)
            cmd=$firewall
            ;;
    esac
    if command -v "$cmd" &> /dev/null && systemctl is-enabled --quiet "$firewall" && systemctl is-active --quiet "$firewall"; then
        active_firewall+=("$firewall")
    fi
done

# Mostrar resultados de la auditoría
# Mostrar resultados de la auditoría
if [ ${#active_firewall[@]} -eq 1 ]; then
    firewall="${active_firewall[0]}"
    echo -e "\n${GREEN}[+] Un firewall en uso: '$firewall'"

    echo -e "\n${BLUE}[*] Estado del servicio $firewall${RESET}"
    fw_enabled=$(systemctl is-enabled "$firewall")
    fw_active=$(systemctl is-active "$firewall")

    [[ $fw_enabled == "enabled" ]] && echo -e "${GREEN}[+] $fw_enabled${RESET}" || echo -e "\e[38;5;210m[!] $fw_enabled${RESET}"
    [[ $fw_active == "active" ]] && echo -e "${GREEN}[+] $fw_active${RESET}" || echo -e "\e[38;5;210m[!] $fw_active${RESET}"

    echo -e "\n${BLUE}[*] Reglas activas:${RESET}"

    case "$firewall" in
        ufw)
            ufw_status=$(ufw status verbose)
            if echo "$ufw_status" | grep -q "Status: inactive"; then
                echo -e "\e[38;5;210m[!] UFW está inactivo${RESET}"
                echo -e "\e[33m[!] Para activarlo ejecute: sudo ufw enable${RESET}"
            else
                echo "$ufw_status"
            fi

            # Auditoría específica para UFW
            echo -e "\n${BLUE}[*] Comprobación de tráfico loopback en UFW${RESET}"
            if [[ $ufw_status =~ Anywhere.*DENY.IN.*127\.0\.0\.0/8 || $ufw_status =~ Anywhere.\(v6\).*DENY.IN.*::1 ]]; then
                echo -e "${GREEN}[+] Loopback configurado correctamente${RESET}"
            else
                echo -e "\e[38;5;210m[!] Loopback traffic no está configurado correctamente${RESET}"
                echo -e "\e[33m[!] Para corregir:"
                echo -e "# ufw allow in on lo"
                echo -e "# ufw allow out on lo"
                echo -e "# ufw deny in from 127.0.0.0/8"
                echo -e "# ufw deny in from ::1"
            fi

            echo -e "\n${BLUE}[*] Revisión de puertos abiertos sin reglas UFW${RESET}"
            a_ufwout=()
            while read -r l_ufwport; do
              [ -n "$l_ufwport" ] && a_ufwout+=("$l_ufwport")
            done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)

            a_openports=()
            while read -r l_openport; do
              [ -n "$l_openport" ] && a_openports+=("$l_openport")
            done < <(ss -tuln | awk '!/127.0.0.1|%lo|::1/ {split($5, a, ":"); print a[2]}' | sort -u)

            a_diff=($(comm -23 <(printf '%s\n' "${a_openports[@]}" | sort) <(printf '%s\n' "${a_ufwout[@]}" | sort)))

            if [[ -n "${a_diff[*]}" ]]; then
              echo -e "\e[31m[-] Puertos abiertos sin reglas en UFW:"
              printf '  - %s\n' "${a_diff[@]}"
              echo -e "\e[33m[!] Para corregir:"
              echo -e "# ufw allow <puerto>/<protocolo>   # Ej: ufw allow 5432/tcp"
            else
              echo -e "${GREEN}[+] Todos los puertos abiertos tienen reglas en UFW${RESET}"
            fi

            echo -e "\n${BLUE}[*] Política predeterminada de UFW${RESET}"
            deny_permissions=$(ufw status verbose | grep "Default:" | sed 's/[[:space:]]*$//')
            if [[ $deny_permissions == "Default: deny (incoming), deny (outgoing), deny (routed)" ]]; then
                echo -e "${GREEN}[+] $deny_permissions${RESET}"
            else
                echo -e "\e[38;5;210m[-] Política predeterminada insegura:\n$deny_permissions${RESET}"
                echo -e "\e[33m[!] Para corregir:"
                echo -e "# ufw default deny incoming"
                echo -e "# ufw default deny outgoing"
                echo -e "# ufw default deny routed"
            fi
            ;;
        nftables)
            nft list ruleset
            echo -e "\n\e[33m[!] NOTA: No se realiza auditoría automática de puertos abiertos con reglas nftables aún.${RESET}"
            ;;
        iptables)
            iptables -L -v -n
            echo -e "\e[33m[*] NOTA: No se realiza auditoría automática de puertos abiertos con reglas iptables aún.${RESET}"
            ;;
    esac

elif [ ${#active_firewall[@]} -eq 0 ]; then
    echo -e "\n${RED}[-] Ningún firewall en uso."
    echo -e "\e[38;5;210m[!] Activar un firewall mejora la seguridad del sistema.${RESET}"
else
    echo -e "\n${RED}[-] Múltiples firewalls en uso: ${active_firewall[*]}\n"
    echo -e "\e[33m[!] Tiene que estar funcionando UN solo firewall.${RESET}"
    echo -e "\e[33m[!] En caso de tener varios firewalls instalados, escoja solo UNO${RESET}"
fi

if [[ $installed_firewalls -gt 1 ]]; then
    echo -e "\n\e[33m[!] En caso de tener varios firewalls instalados, escoja solo UNO${RESET}"
fi
