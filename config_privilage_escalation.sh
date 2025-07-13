echo -e "\e[1;34m[*] Sudo instalado${RESET}"
if dpkg-query -s sudo &>/dev/null; then
    echo -e "${GREEN}[+] Sudo instalado\n"
else
    echo -e "\e[38;5;210m[-] Sudo no instalado"
fi


echo -e "\e[1;34m[*] Los comandos sudo utilizan pty${RESET}"
output1=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,\h*)?use_pty\b' /etc/sudoers*)
output2=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,\h*)?!use_pty\b' /etc/sudoers*)
exit_code2=$?
if [[ $output1 == *"use_pty"* && $exit_code2 -ne 0 ]]; then
    echo -e "${GREEN}[+] $output1"
else
    echo -e "\e[38;5;210m[-] $output1 $output2"
fi

echo -e "\n"

echo -e "\e[1;34m[[*] El archivo de registro sudo${RESET}"
output=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers*)
if [[ $output == *"logfile"* ]]; then
        echo -e "${GREEN}[+] $output"
else
        echo -e "\e[38;5;210m[-] El archivo log de sudo no existe"
        echo -e "${YELLOW}[!] Para corregir:"
        echo -e "Editar el archivo sudoers -> sudo visudo"
        echo -e 'Añadir esta linea:\nDefaults\tlogfile="/var/log/sudo.log"'
fi

echo -e "\n"

echo -e "\e[1;34m[*] Garantizar que los usuarios deban proporcionar una contraseña para la elevación de privilegios${RESET}"
output=$(sudo grep -r "^[^#].*NOPASSWD" /etc/sudoers*)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
        echo -e "\e[38;5;210m[-] No todos los usuarios deben proporcionar clave\n -> $output"
else
        echo -e "${GREEN}[+] Todos los usuarios deben proporcionar clave"
fi

echo -e "\n"

echo -e "\e[1;34m[*] La reautenticación para la escalada de privilegios no está desactivada globalmente${RESET}"
output=$(sudo grep -r "^[^#].*\!authenticate" /etc/sudoers*)
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
        echo -e "${GREEN}[+] La reautenticacion de privilegios no esta desactivada globalmente"
else
        echo -e "\e[38;5;210m[-] La reautenticacion de privilegios esta desactivada globalmente\n$output"
fi

echo -e "\n"

echo -e "\e[1;34m[*] Tiempo de espera de autenticación sudo configurado correctamente${RESET}"
output=$(grep -roP "timestamp_timeout=\K[0-9]*" /etc/sudoers*)
if [[ -n $output ]]; then
        echo -e "${GREEN}[+] TimeStamp configurado:\n$output\nEl valor no tiene que ser tan alto"
else
        output=$(sudo -V | grep -i "Authentication timestamp timeout:")
        if [[ -n $output ]]; then
                echo -e "\e[38;5;210m[!] No TimeSttamp configurado. Por defecto es 15 minutos"
                echo -e "${YELLOW}[!] Para corregir:"
                echo -e "Editar el archivo sudoers -> sudo visudo"
                echo -e 'Añadir estas lineas:\nDefaults\tenv_reset, timestamp_timeout=15'
                echo -e 'Defaults\ttimestamp_timeout=15'
                echo -e 'Defaults\tenv_reset'
        else
                echo -e "${GREEN}[+] TimeSttamp configurado:\n$output\n. Por defecto es 15 minutos"
        fi
fi

echo -e "\n"

echo -e "\e[1;34m[*] Asegurarse de que el acceso al comando su está restringido${RESET}"
# Verificar si pam_wheel.so está configurado
config=$(grep -E '^\s*auth\s+required\s+pam_wheel\.so' /etc/pam.d/su)

# Verificar el grupo configurado (por defecto, wheel)
group=$(echo "$config" | grep -oP 'group=\K\w+')

if [[ -z "$config" ]]; then
    echo -e "${RED}[-] La configuración de su no está restringida (pam_wheel.so no configurado)${RESET}"
elif [[ -z "$group" ]]; then
    echo -e "\e[38;5;210m[-] pam_wheel.so configurado, pero no se especificó ningún grupo${RESET}"
else
    # Verificar si el grupo está vacío
    users=$(grep "^$group:" /etc/group | cut -d: -f4)
    if [[ -z "$users" ]]; then
        echo -e "${GREEN}[+] Configuración correcta: su está restringido al grupo '$group' y el grupo está vacío${RESET}"
    else
        echo -e "\e[38;5;210m[-] El grupo '$group' tiene usuarios: $users${RESET}"
    fi
fi

