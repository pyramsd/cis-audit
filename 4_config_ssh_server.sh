echo -e "${BLUE}[*] Revisión de permisos de archivos SSH${RESET}"

# Buscar archivos relevantes en /etc/ssh/
ssh_files=()
while IFS= read -r -d $'\0' file; do
    ssh_files+=("$file")
done < <(find /etc/ssh -maxdepth 1 -type f \( -name "sshd_config" -o -name "*_key" -o -name "*_key.pub" \) -print0 2>/dev/null)

# Función para determinar el permiso esperado
get_expected_perm() {
    local file="$1"
    case "$file" in
        *sshd_config) echo "600" ;;  # Archivo de configuración
        *.key) echo "600" ;;          # Claves privadas
        *.pub) echo "600" ;;          # Claves públicas
        *) echo "600" ;;
    esac
}

# Función para verificar archivo
check_file() {
    local file="$1"
    [ ! -e "$file" ] && return

    read -r perm owner group < <(stat -Lc '%a %U %G' "$file")
    expected_perm=$(get_expected_perm "$file")

    echo "Permisos de $file:"

    if [[ "$perm" != "$expected_perm" || "$owner" != "root" || "$group" != "root" ]]; then
        echo -e "${RED}[-] ${perm}:${owner}:${group} ${ORANGE}-> ${expected_perm}:root:root${RESET}"
    else
        echo -e "${GREEN}[+] ${perm}:${owner}:${group}${RESET}"
        counter=$((counter + 1))
    fi
    echo
}

# Iterar sobre los archivos encontrados
for file in "${ssh_files[@]}"; do
    check_file "$file"
done


echo -e "${BLUE}[*] Permisos de acceso SSH${RESET}"
output=$(sshd -T | grep -Pi -- '^\h*(allow|deny)(users|groups)\h+\H+')
exit_code=$?

if [ $exit_code -ne 0 ]; then
        echo -e "${PINK}[!] Sin configuracion de acceso${RESET}"
        echo -e "\e[33m[!] Para corregir:\nEn /etc/ssh/sshd_config"
        echo -e "Agregar:\nAllowUsers <usuario/s>\nAllowGroups <grupo/s>"
        echo -e "DenyUsers <usuario/s>\nDenyGroups <grupo/s>${RESET}"
else
        echo -e "${GREEN}[+] Configuracion de acceso\n$output${RESET}"
        counter=$((counter + 1))
fi

echo -e "\n"

echo -e "${BLUE}[*] Cifrados SSH configurados${RESET}"
output=$(sshd -T 2>&1 | grep -Pi -- '^ciphers\h+\"?([^#\n\r]+,)?((3des|blowfish|cast128|aes(128|192|256))-cbc|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se|chacha20-poly1305@openssh\.com)\b')
exit_code=$?
if [ $exit_code -ne 0 ]; then
        echo -e "${PINK}[!] Cifrados no configurados${RESET}"
else
        echo -e "${GREEN}[+] Cifrados configurados:\n$output\e0m"
        counter=$((counter + 1))
fi

echo -e "\n"

echo -e "${BLUE}[*] Configuraciones de /etc/sshd_config${RESET}"
configs=('disableforwarding' 'gssapiauthentication' 'hostbasedauthentication' 'ignorerhosts' 'loglevel' 'logingracetime' 'maxauthtries' 'permitemptypasswords' 'permituserenvironment' 'maxstartups' 'PermitRootLogin' 'clientaliveinterval' 'clientalivecountmax')
for config in "${configs[@]}"; do
        output=$(sshd -T | grep -i ^$config)

        if [[ -n "$output" ]]; then
                value=$(echo "$output" | awk '{print $2}')

                if [[ "$value" == "yes" ]]; then
                        echo -e "${GREEN}[+] $output"
                        counter=$((counter + 1))
                elif [[ "$value" == "no" ]]; then
                        if [[ "$config" == "gssapiauthentication" || "$config" == "hostbasedauthentication" || "$config" == "permitemptypasswords" || "$config" == "permituserenvironment" ]]; then
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                        else
                                echo -e "${PINK}[-] $output"
                        fi
                elif [[ "$config" == "loglevel" ]]; then
                        if [[ "$value" == "INFO" || "$value" == "VERBOSE" ]]; then
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                        else
                                echo -e "\e[37;5;210mm[-] $output"
                        fi
                elif [[ "$config" == "logingracetime" ]]; then
                        if [[ "$value" != "60" ]]; then
                                echo -e "${PINK}[-] $output -> Valor recomendado: 60"
                        else
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                        fi
                elif [[ "$config" == "maxauthtries" ]]; then
                        if [[ "$value" != "4" ]]; then
                                echo -e "${PINK}[-] $output -> Valor recomendado: 4"
                        else
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                        fi
                elif [[ "$config" == "maxstartups" ]]; then
                        if [[ "$value" != "10:30:60" ]]; then
                                echo -e "${PINK}[-] $output -> Valor recomendado: 10:30:60"
                        else
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                        fi
                elif [[ "$config" == "PermitRootLogin" ]]; then
                        if [[ "$value" == "no" || "$value" == "without-password" ]]; then
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                                if [[ "$value" == "without-password" ]]; then
                                        echo -e "\e[33m    [!] without-password: Permite el acceso root, pero solo si usa una clave SSH"
                                fi
                        else
                                echo -e "${PINK}m[-] $output"
                        fi
                elif [[ "$config" == "clientalivecountmax" || "$config" == "clientaliveinterval" ]]; then
                        if [[ "$value" =~ ^[0-9]+$ ]]; then
                                echo -e "${GREEN}[+] $output"
                                counter=$((counter + 1))
                        else
                                echo -e "${PINK}[-] $output -> El valor tiene que ser un numerico"
                        fi
                else
                        echo -e "${PINK}[!] Valor desconocido"
                fi
        else
                echo -e "${PINK}[-] No se encuentra esa configuracion"
        fi
done
echo -e "\e[33m[!] Para añadir o modificar configuraciones: /etc/ssh/sshd_config"

echo -e "\n"

echo -e "${BLUE}[*] KexAlgorithms correctamente configurado${RESET}"
#output=$(sshd -T | grep -Pi -- 'kexalgorithms\h+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b')
output2=$(sshd -T | grep -i 'kexalgorithms')
output=$(sshd -T | grep -Pi -- 'kexalgorithms\h+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b')
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "${GREEN}[+] KexAlgorithms sin cifrados debiles:\n-> $output2${RESET}"
        counter=$((counter + 1))
else
        if [[ $output == *"kexalgorithms no"* ]]; then
                echo -e "${PINK}[!] KexAlgorithms no está habilitado:\n-> $output${RESET}"
        else
                echo -e "${GREEN}[+] KexAlgorithms habilitado:\n-> $output2${RESET}"
                counter=$((counter + 1))
        fi
fi

echo -e "\n"

echo -e "${BLUE}[*] sshd MACs estan configurados${RESET}"
output2=$(sshd -T | grep -i 'macs')
output=$(sshd -T | grep -Pi -- 'macs\h+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b')
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "${GREEN}[+] Macs sin cifrados debiles:\n-> $output2${RESET}"
        counter=$((counter + 1))
else
        if [[ $output == *"macs no"* ]]; then
                echo -e "${PINK}[-] Macs no está habilitado:\n-> $output${RESET}"
        else
                echo -e "${PINK}[-] Macs con cifrado debil:\n-> $output${RESET}"
                echo -e "\e[33m[!] Cifrados seguros:\n* HMAC-SHA1\n* HMAC-SHA2-256\n* HMAC-SHA2-384\n* HMAC-SHA2-512"
        fi
fi

echo -e "\n"

echo -e "${BLUE}[*] sshd UsePAM activado${RESET}"
output=$(sshd -T | grep -i usepam)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "${PINK}[!] UsePam no habilitado:\n-> $output${RESET}"
else
        if [[ $output == *"usepam no"* ]]; then
                echo -e "${PINK}[!] UsePam desactivado:\n-> $output${RESET}"
    else
                echo -e "${GREEN}[+] UsePam activado:\n-> $output${RESET}"
                counter=$((counter + 1))
        fi
fi
