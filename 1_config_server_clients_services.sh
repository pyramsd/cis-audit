LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/errors.log"
: > "$LOG_FILE"

# Software que no deben estar instalados a primera instancia
echo -e "${BLUE}[*] Estos softwares no deben de estar instalados a no ser que sean necesarios:${RESET}"
# Lista de paquetes a verificar
packages=("autofs" "avahi-daemon" "bind9" "dnsmasq" "vsftpd" "ftp" "slapd" "dovecot-imapd" "nfs-kernel-server" "ypserv" "cups" "rpcbind" "rsync" "samba" "snmpd" "tftpd-hpa" "squid" "apache2" "nginx" "xinetd" "xserver-common" "isc-dhcp-server" "nis" "rsh-client" "talk" "telnet" "inetutils-telnet" "ldap-utils" "tnftp")

# Iterar sobre la lista de paquetes
for pkg in "${packages[@]}"; do
    if dpkg-query -s "$pkg" &>/dev/null; then
        echo -e "${PINK}[-] $pkg is installed"
        echo "[SOFTWARE] El programa $pkg no deb estar instalado" >> "$LOG_FILE"
    else
        echo -e "${GREEN}[+] $pkg is not installed"
        counter=$((counter + 1))
    fi
done
echo -e "\n${YELLOW}[!] Si el servidor requiere de estos software ignore la advertencia."

echo -e "\n"

echo -e "${BLUE}[*] Asegúrese de que el agente de transferencia de correo está configurado en modo sólo local${RESET}"
# Arrays para almacenar los resultados
a_output=()
a_output2=()
a_port_list=("25" "465" "587") # Lista de puertos a verificar

# Verificar si los puertos están escuchando en una interfaz no loopback
for l_port_number in "${a_port_list[@]}"; do
    if ss -plntu | grep -P -- ":$l_port_number\b" | grep -Pvq -- '\s+(127\.0\.0\.1|\[?::1\]?):'"$l_port_number"'\b'; then
        a_output2+=(" - Port \"$l_port_number\" is listening on a non-loopback network interface")
    else
        a_output+=(" - Port \"$l_port_number\" is not listening on a non-loopback network interface")
    fi
done

# Verificar configuración de interfaces del MTA
l_interfaces=""
if command -v postconf &>/dev/null; then
    l_interfaces="$(postconf -n inet_interfaces)"
elif command -v exim &>/dev/null; then
    l_interfaces="$(exim -bP local_interfaces)"
elif command -v sendmail &>/dev/null; then
    l_interfaces="$(grep -i "DaemonPortOptions=" /etc/mail/sendmail.cf | grep -oP '(?<=Addr=)[^,+]+')"
fi

if [ -n "$l_interfaces" ]; then
    if grep -Pqi '\ball\b' <<< "$l_interfaces"; then
        a_output2+=(" - MTA is bound to all network interfaces")
    elif ! grep -Pqi '(inet_interfaces\s*=\s*)?(0\.0\.0\.0|::1|loopback-only)' <<< "$l_interfaces"; then
        a_output2+=(" - MTA is bound to a network interface \"$l_interfaces\"")
    else
        a_output+=(" - MTA is not bound to a non-loopback network interface \"$l_interfaces\"")
    fi
else
    a_output+=(" - MTA not detected or in use")
fi

# Resultado de la auditoría
if [ "${#a_output2[@]}" -le 0 ]; then
    printf "${GREEN} ** PASS ** ${RESET}\n"
    for line in "${a_output[@]}"; do
        printf "${GREEN}%s\n${RESET}" "$line"
        counter=$((counter + 1))
    done
else
    printf "${RED} ** FAIL ** ${RESET}\n"
    printf " * Reasons for audit failure *\n"
    for line in "${a_output2[@]}"; do
        printf "${RED}%s\n${RESET}" "$line"
    done
    printf "\n"
    if [ "${#a_output[@]}" -gt 0 ]; then
        printf "- Correctly set:\n"
        for line in "${a_output[@]}"; do
            printf "%s\n" "$line"
        done
    fi
fi
