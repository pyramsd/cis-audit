echo -e "\e[1;34m[*] Sudo instalado\e[0m"
if dpkg-query -s sudo &>/dev/null; then
    echo -e "\e[32m[+] Sudo instalado"
else
    echo -e "\e[38;5;210m[-] Sudo no instalado"
fi

echo -e "\n"

echo -e "\e[1;34m[*] Los comandos sudo utilizan pty\e[0m"
output1=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,\h*)?use_pty\b' /etc/sudoers*)
output2=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,\h*)?!use_pty\b' /etc/sudoers*)
exit_code2=$?
if [[ $output1 == *"use_pty"* && $exit_code2 -ne 0 ]]; then
    echo -e "\e[32m[+] $output1"
else
    echo -e "\e[38;5;210m[-] $output1 $output2"
fi

echo -e "\n"

echo -e "\e[1;34m[[*] El archivo de registro sudo existe\e[0m"
output=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers*)
if [[ $output == *"logfile"* ]]; then
        echo -e "\e[32m[+] $output"
else
        echo -e "\e[38;5;210m[-] El archivo log de sudo no existe"
        echo -e "\e[33m[!] Para corregir:"
        echo -e "Editar el archivo sudoers -> sudo visudo"
        echo -e 'Añadir esta linea:\nDefaults\tlogfile="/var/log/sudo.log"'
fi

echo -e "\n"

echo -e "\e[1;34m[*] Garantizar que los usuarios deban proporcionar una contraseña para la elevación de privilegios\e[0m"
output=$(sudo grep -r "^[^#].*NOPASSWD" /etc/sudoers*)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
        echo -e "\e[38;5;210m[-] No todos los usuarios deben proporcionar clave\n -> $output"
else
        echo -e "\e[32m[+] Todos los usuarios deben proporcionar clave"
fi

echo -e "\n"

echo -e "\e[1;34m[*] La reautenticación para la escalada de privilegios no está desactivada globalmente\e[0m"
output=$(sudo grep -r "^[^#].*\!authenticate" /etc/sudoers*)
exit_code=$?
if [[ $exit_code -eq 1 ]]; then
        echo -e "\e[32m[+] La reautenticacion de privilegios no esta desactivada globalmente"
else
        echo -e "\e[38;5;210m[-] La reautenticacion de privilegios esta desactivada globalmente\n$output"
fi

echo -e "\n"

echo -e "\e[1;34m[*] Tiempo de espera de autenticación sudo configurado correctamente\e[0m"
output=$(grep -roP "timestamp_timeout=\K[0-9]*" /etc/sudoers*)
if [[ -n $output ]]; then
        echo -e "\e[32m[+] TimeStamp configurado:\n$output\nEl valor no tiene que ser tan alto"
else
        output=$(sudo -V | grep -i "Authentication timestamp timeout:")
        if [[ -n $output ]]; then
                echo -e "\e[38;5;210m[!] No TimeSttamp configurado. Por defecto es 15 minutos"
                echo -e "\e[33m[!] Para corregir:"
                echo -e "Editar el archivo sudoers -> sudo visudo"
                echo -e 'Añadir estas lineas:\nDefaults\tenv_reset, timestamp_timeout=15'
                echo -e 'Defaults\ttimestamp_timeout=15'
                echo -e 'Defaults\tenv_reset'
        else
                echo -e "\e[32m[+] TimeSttamp configurado:\n$output\n. Por defecto es 15 minutos"
        fi
fi

echo -e "\n"

echo -e "\e[1;34m[*] Asegurarse de que el acceso al comando su está restringido\e[0m"
# Verificar si pam_wheel.so está configurado
config=$(grep -E '^\s*auth\s+required\s+pam_wheel\.so' /etc/pam.d/su)

# Verificar el grupo configurado (por defecto, wheel)
group=$(echo "$config" | grep -oP 'group=\K\w+')

if [[ -z "$config" ]]; then
    echo -e "\e[38;5;210m[-] La configuración de su no está restringida (pam_wheel.so no configurado)\e[0m"
elif [[ -z "$group" ]]; then
    echo -e "\e[38;5;210m[-] pam_wheel.so configurado, pero no se especificó ningún grupo\e[0m"
else
    # Verificar si el grupo está vacío
    users=$(grep "^$group:" /etc/group | cut -d: -f4)
    if [[ -z "$users" ]]; then
        echo -e "\e[32m[+] Configuración correcta: su está restringido al grupo '$group' y el grupo está vacío\e[0m"
    else
        echo -e "\e[38;5;210m[-] El grupo '$group' tiene usuarios: $users\e[0m"
    fi
fi

