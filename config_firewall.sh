# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "\e[1;34m[*] Configuracion de firewall\e[0m"
firewalls=('ufw' 'nftables' 'iptables' 'iptables-persistent')
echo -e "Requerimientos:"
for frw in "${firewalls[@]}"; do
        if dpkg-query -s $frw &>/dev/null; then
                echo -e "\e[32m[+] $frw instalado\e[0m"
        else
                if [[ $frw == "iptables-persistent" ]]; then
                        echo -e "\e[32m[+] $frw no instalado\e[0m\n"
                else
                        echo -e "\e[31m[-] $frw no instalado\e[0m\n"
                fi
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
if [ ${#active_firewall[@]} -eq 1 ]; then
    echo -e "${GREEN}\n** PASS **${RESET}"
    echo -e "${GREEN}[+] Un firewall en uso: '${active_firewall[0]}'"
elif [ ${#active_firewall[@]} -eq 0 ]; then
    echo -e "${RED}\n** FAIL **${RESET}"
    echo -e "${RED}[-] Ningunfirewall en uso o habilitado."
else
    echo -e "${RED}** FAIL **${RESET}"
    echo -e "${RED}[-] Multiples firewalls en uso: ${active_firewall[*]}\n"
    echo -e "\e[33m Tiene que estar funcionando UN solo firewall."
fi

echo -e "\n"

echo -e "\e[1;34m[*] Asegúrese de que el servicio del firewall está activado\e[0m"
ufw_enabled=$(systemctl is-enabled ufw.service)
ufw_activated=$(systemctl is-active ufw.service)
ufw_status=$(ufw status verbose)
if [[ $ufw_enabled == "enabled" ]]; then
        echo -e "\e[32m[+] $ufw_enabled\e[0m"
else
        echo -e "\e[38;5;210m[!] $ufw_enabled\e[0m"
fi

if [[ $ufw_activated == "active" ]]; then
        echo -e "\e[32m[+] $ufw_activated\e[0m"
else
        echo -e "\e[38;5;210m[!] $ufw_activated\e[0m"
fi

echo -e "\n"

echo -e "\e[1;34m[*] Asegúrese de que ufw loopback traffic está configurado\e[0m"
if [[ $ufw_status =~ Anywhere.*DENY.IN.*127\.0\.0\.0/8 || $ufw_status =~ Anywhere.\(v6\).*DENY.IN.*::1 ]]; then
    echo -e "\e[32m[+] $ufw_status\e[0m"
else
    echo -e "\e[38;5;210m[!] $ufw_status\n[!] Loopback traffic no esta configurado.\e[0m"
    echo -e "\e[33m[!] Para Corregir:"
    echo -e "# ufw allow in on lo" 
    echo -e "# ufw allow out on lo"
    echo -e "# ufw deny in from 127.0.0.0/8"
    echo -e "# ufw deny in from ::1"
fi

echo -e "\n"

echo -e "\e[1;34m[*] Reglas de cortafuegos para todos los puertos abiertos\e[0m"
# Obtener puertos en las reglas de UFW
a_ufwout=()
while read -r l_ufwport; do
  [ -n "$l_ufwport" ] && a_ufwout+=("$l_ufwport")
done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)

# Obtener puertos abiertos en el sistema (excepto loopback)
a_openports=()
while read -r l_openport; do
  [ -n "$l_openport" ] && a_openports+=("$l_openport")
done < <(ss -tuln | awk '!/127.0.0.1|%lo|::1/ {split($5, a, ":"); print a[2]}' | sort -u)

# Comparar las listas para encontrar puertos abiertos sin reglas
a_diff=($(comm -23 <(printf '%s\n' "${a_openports[@]}" | sort) <(printf '%s\n' "${a_ufwout[@]}" | sort)))

# Resultado
if [[ -n "${a_diff[*]}" ]]; then
  echo -e "\e[31m[-] Audit Result:\n ** FAIL **"
  echo "- The following port(s) don't have a rule in UFW:"
  printf '  - %s\n' "${a_diff[@]}"
  echo -e "\e[33m[!] Para corregir:"
  echo -e "# ufw allow <programa> o # ufw allow <puerto>/<protocolo>"
  echo -e "Ejemplo:\n# ufw allow postgresql\n# ufw allow 5432/tcp"
else
  echo -e "\e[32m[+] Audit Passed"
  echo -e "\e[32m[+] All open ports have a rule in UFW\e[0m"
fi

echo -e "\n"

echo -e "\e[1;34m[*] Asegúrese de que la política de cortafuegos de denegación predeterminada ufw\e[0m"
deny_permissions=$(ufw status verbose | grep "Default:" | sed 's/[[:space:]]*$//')
if [[ $deny_permissions == "Default: deny (incoming), deny (outgoing), deny (routed)" ]]; then
        echo -e "\e[32m[+]Tiene reglas denegadas por defecto\n$deny_permissions\e[0m\n"
else
        echo -e "\e[38;5;210m[-] No tiene reglas denegadas por defecto\n$deny_permissions\e[0m"
        echo -e "\e[33m[!] Para corregir:"
        echo -e "# ufw default deny incoming"
        echo -e "# ufw default deny outgoing"
        echo -e "# ufw default deny routed\n"
fi
echo -e "\e[33m[!] En caso de tener varios firewalls instalados o habilitados, escoja solo UNO\e[0m"
