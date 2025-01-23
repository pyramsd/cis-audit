echo -e "\n\e[34m[*] Asegúrese de que se utiliza una única utilidad de configuración de cortafuegos\e[0m"
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
echo -e "${BLUE}Audit Results:${RESET}"
if [ ${#active_firewall[@]} -eq 1 ]; then
    echo -e "${GREEN} ** PASS **${RESET}"
    echo -e "${GREEN} - A single firewall is in use. Follow the recommendation in '${active_firewall[0]}' subsection ONLY."
elif [ ${#active_firewall[@]} -eq 0 ]; then
    echo -e "${RED} ** FAIL **${RESET}"
    echo -e "${RED} - No firewall in use or unable to determine firewall status."
else
    echo -e "${RED} ** FAIL **${RESET}"
    echo -e "${RED} - Multiple firewalls are in use: ${active_firewall[*]}"
fi

echo -e "\n"

echo -e "\e[34m[*] Asegurarse que iptables-persistent no este instalado con ufw\e[0m"
if dpkg-query -s ufw &>/dev/null; then
        echo -e "\e[32m[+] ufw is installed\e[0m"
else
        echo -e "\e[31m[-] ufw is not installed\e[0m"
fi

if dpkg-query -s iptables-persistent &>/dev/null; then
        echo -e "\e[31m[-] iptables-persistent is installed.\e[0m"
else
        echo -e "\e[32m[+] iptables-persistent is not installed\e[0m"
fi

echo -e "\n"

echo -e "\e[34m[*] Asegúrese de que el servicio ufw está activado"
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

echo -e "\e[34m[*] Asegúrese de que ufw loopback traffic está configurado"
if [[ $ufw_status =~ Anywhere.*DENY.IN.*127\.0\.0\.0/8 || $ufw_status =~ Anywhere.\(v6\).*DENY.IN.*::1 ]]; then
    echo -e "\e[32m[+] $ufw_status\e[0m"
else
    echo -e "\e[38;5;210m[!] $ufw_status\n[!] Loopback traffic no esta configurado.\e[0m"
fi

echo -e "\n"

echo -e "\e[34m[*] Asegúrese de que existen reglas de cortafuegos ufw para todos los puertos abiertos\e[0m"
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
  echo "- End List\e[0m"
else
  echo -e "\e[32m[+] Audit Passed"
  echo -e "\e[32m[+] All open ports have a rule in UFW\e[0m"
fi

echo -e "\n"

echo -e "\e[34m[*] Asegúrese de que la política de cortafuegos de denegación predeterminada ufw\e[0m"
deny_permissions=$(ufw status verbose | grep Default:)
if [[ $deny_permissions =~ Default:.deny.\(incoming\),.deny.\(outgoing\),.disabled.\(routed\) ]]; then
        echo -e "\e[32m[+]Tiene reglas denegadas por defecto\n$deny_permissions\e[0m"
else
        echo -e "\e[31m[-] No tiene reglas denegadas por defecto\n$deny_permissions\e[0m"
fi
