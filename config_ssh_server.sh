# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "\e[34m[*] Permisos de /etc/ssh/sshd_config configurados adecuadamente\e[0m"
# Definición de variables
a_output=()
a_output2=()
perm_mask='0177'
maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"

# Función para verificar archivos de configuración SSH
f_sshd_files_chk() {
    while IFS=: read -r l_mode l_user l_group; do
        a_out2=()

        # Verificar permisos
        [ $(( $l_mode & $perm_mask )) -gt 0 ] && a_out2+=(" Is mode: \"$l_mode\"" " Should be mode: \"$maxperm\" or more restrictive")

        # Verificar propietario
        [ "$l_user" != "root" ] && a_out2+=(" Is owned by \"$l_user\" should be owned by \"root\"")

        # Verificar grupo propietario
        [ "$l_group" != "root" ] && a_out2+=(" Is group owned by \"$l_user\" should be group owned by \"root\"")

        # Si hay errores, agregar a a_output2, de lo contrario, agregar a a_output
        if [ "${#a_out2[@]}" -gt "0" ]; then
            a_output2+=(" - File: \"$l_file\":" "${a_out2[@]}")
        else
            a_output+=(" - File: \"$l_file\":" " Correct: mode ($l_mode), owner ($l_user)" " and group owner ($l_group) configured")
        fi
    done < <(stat -Lc '%#a:%U:%G' "$l_file")
}

# Verificar el archivo principal de configuración SSH
if [ -e "/etc/ssh/sshd_config" ]; then
    l_file="/etc/ssh/sshd_config"
    f_sshd_files_chk
fi

# Verificar archivos de configuración adicionales
while IFS= read -r -d $'\0' l_file; do
    [ -e "$l_file" ] && f_sshd_files_chk
done < <(find /etc/ssh/sshd_config.d -type f -name '*.conf' \( -perm /077 -o ! -user root -o ! -group root \) -print0 2>/dev/null)

# Generar salida dependiendo de si se encontraron errores
if [ "${#a_output2[@]}" -le 0 ]; then
        printf ${GREEN}'%s\n'${RESET} "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
        printf ${RED}'%s\n'${RESET} "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi

echo -e "\n"

echo -e "\e[34m[*] Permisos de los archivos de claves de host privadas SSH configuradas"
# Declaración de variables
a_output=()
a_output2=()
l_ssh_group_name="$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) {print $1}' /etc/group)"

# Función para verificar propiedades de un archivo
f_file_chk() {
    while IFS=: read -r l_file_mode l_file_owner l_file_group; do
        a_out2=()
        [ "$l_file_group" = "$l_ssh_group_name" ] && l_pmask="0137" || l_pmask="0177"
        l_maxperm="$(printf '%o' $((0777 & ~$l_pmask)))"

        # Verificar permisos del archivo
        if [ $((l_file_mode & l_pmask)) -gt 0 ]; then
            a_out2+=(" Mode: \"$l_file_mode\" should be mode: \"$l_maxperm\" or more restrictive")
        fi

        # Verificar propietario del archivo
        if [ "$l_file_owner" != "root" ]; then
            a_out2+=(" Owned by: \"$l_file_owner\" should be owned by \"root\"")
        fi

        # Verificar grupo propietario del archivo
        if [[ ! "$l_file_group" =~ ($l_ssh_group_name|root) ]]; then
            a_out2+=(" Owned by group \"$l_file_group\" should be group owned by: \"$l_ssh_group_name\" or \"root\"")
        fi

        # Agregar resultados al reporte final
        if [ "${#a_out2[@]}" -gt 0 ]; then
            a_output2+=(" - File: \"$l_file\"${a_out2[@]}")
        else
            a_output+=(" - File: \"$l_file\"" \
                " Correct: mode: \"$l_file_mode\", owner: \"$l_file_owner\" and group owner: \"$l_file_group\" configured")
        fi
    done < <(stat -Lc '%#a:%U:%G' "$l_file")
}

# Buscar y analizar archivos
while IFS= read -r -d $'\0' l_file; do
    if ssh-keygen -lf &>/dev/null "$l_file"; then
        if file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?private\h+key\b'; then
            f_file_chk
        fi
    fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

# Generar salida dependiendo de si se encontraron errores
if [ "${#a_output2[@]}" -le 0 ]; then
    printf ${GREEN}'%s\n'${RESET} "- Audit Result:" " ** PASS **" "${a_output[@]}"
else
    printf ${RED}'%s\n'${RESET} "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}"
fi

echo -e "\n"

echo -e "\e[34m[*] Permisos de los archivos de claves de host publicas SSH configuradas\e[0m"
# Declaración de variables
a_output=()
a_output2=()
l_ssh_group_name="$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) {print $1}' /etc/group)"

# Función para verificar propiedades de un archivo
f_file_chk() {
    while IFS=: read -r l_file_mode l_file_owner l_file_group; do
        a_out2=()
        [ "$l_file_group" = "$l_ssh_group_name" ] && l_pmask="0137" || l_pmask="0177"
        l_maxperm="$(printf '%o' $((0777 & ~$l_pmask)))"

        # Verificar permisos del archivo
        if [ $((l_file_mode & l_pmask)) -gt 0 ]; then
            a_out2+=(" Mode: \"$l_file_mode\". Should be mode: \"$l_maxperm\" or more restrictive")
        fi

        # Verificar propietario del archivo
        if [ "$l_file_owner" != "root" ]; then
            a_out2+=(" Owned by: \"$l_file_owner\" Should be owned by \"root\"")
        fi

        # Verificar grupo propietario del archivo
        if [[ ! "$l_file_group" =~ ($l_ssh_group_name|root) ]]; then
            a_out2+=(" Owned by group \"$l_file_group\" Should be group owned by: \"$l_ssh_group_name\" or \"root\"")
        fi

        # Agregar resultados al reporte final
        if [ "${#a_out2[@]}" -gt 0 ]; then
                a_output2+=(" - File: \"$l_file\"")
                for msg in "${a_out2[@]}"; do
                        a_output2+=("$msg")
                done
            #a_output2+=(" - File: \"$l_file\":" "${a_out2[@]}")
        else
            a_output+=(" - File: \"$l_file\"" \
                " Correct: mode: \"$l_file_mode\", owner: \"$l_file_owner\" and group owner: \"$l_file_group\" configured")
        fi
    done < <(stat -Lc '%#a:%U:%G' "$l_file")
}

# Buscar y analizar archivos
while IFS= read -r -d $'\0' l_file; do
    if ssh-keygen -lf &>/dev/null "$l_file"; then
        if file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?public\h+key\b'; then
            f_file_chk
        fi
    fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

# Generar salida dependiendo de si se encontraron errores
if [ "${#a_output2[@]}" -le 0 ]; then
    printf ${GREEN}'%s\n'${RESET} "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf ${RED}'%s\n'${RESET} "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi

echo -e "\n"

echo -e "\e[34m[*] Permisos de acceso SSH\e[0m"
output=$(sshd -T | grep -Pi -- '^\h*(allow|deny)(users|groups)\h+\H+')
exit_code=$?

if [ $exit_code -ne 0 ]; then
        echo -e "\e[38;5;210m[!] Sin configuracion de acceso\e[0m"
else
        echo -e "\e[32m[+] Configuracion de acceso\n$output\e[0m"
fi

echo -e "\n"

echo -e "\e[34m[*] Cifrados SSH configurados\e[0m"
output=$(sshd -T 2>&1 | grep -Pi -- '^ciphers\h+\"?([^#\n\r]+,)?((3des|blowfish|cast128|aes(128|192|256))-cbc|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se|chacha20-poly1305@openssh\.com)\b')
exit_code=$?
if [ $exit_code -ne 0 ]; then
        echo -e "\e[38;5;210m[!] Cifrados no configurados\e[0m"
else
        echo -e "\e[32m[+] Cifrados configurados:\n$output\e0m"
fi

echo -e "\n"

echo -e "\e[34m[*] Asegúrese de que sshd ClientAliveInterval y ClientAliveCountMax están configurados\e[0m"
output=$(sshd -T 2>&1 | grep -Pi -- 'clientaliveinterval|clientalivecountmax')
exit_code=$?
if [ $exit_code -ne 0 ]; then
        echo -e "\e[38;5;210m[!] ClientAliveInterval y ClientAliveCpuntMax no configurados\e[0m"
else
        echo -e "\e[32m[+] ClientAliveInterval y ClientAliveCountMax configurados:\n$output\e[0m"
fi

echo -e "\n"

echo -e "\e[34m[*] sshd DisableForwarding está activado"
output=$(sshd -T | grep -i disableforwarding)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] DisableForwarding no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"disableforwarding no"* ]]; then
                echo -e "\e[38;5;210m[!] DisableForwarding no está habilitado:\n-> $output\e[0m"
        else
                echo -e "\e[32m[+] DisableForwarding habilitado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd GSSAPIAuthentication esta deshabilitado"
output=$(sshd -T | grep -i gssapiauthentication)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[32[+] GSSAPIAuthentication no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"gssapiauthentication no"* ]]; then
                echo -e "\e[32m[+] GSSAPIAuthentication no está habilitado:\n-> $output\e[0m"
        else
                echo -e "\e[38;5;210m[!] GSSAPIAuthentication habilitado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd HostBasedAuthentication esta deshabilitado"
output=$(sshd -T | grep -i hostbasedauthentication)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[32[+] HostBasedAuthentication no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"hostbasedauthentication no"* ]]; then
                echo -e "\e[32m[+] HostBasedAuthentication no está habilitado:\n-> $output\e[0m"
        else
                echo -e "\e[38;5;210m[!] HostBasedAuthentication habilitado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd IgnoreRhosts esta activado"
output=$(sshd -T | grep -i ignorerhosts)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] IgnoreRhosts no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"ignorerhosts no"* ]]; then
                echo -e "\e[38;5;210m[!] DisableForwarding no está habilitado:\n-> $output\e[0m"
        else
                echo -e "\e[32m[+] IgnoreRhosts habilitado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] KexAlgorithms correctamente configurado\e[0m"
#output=$(sshd -T | grep -Pi -- 'kexalgorithms\h+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b')
output2=$(sshd -T | grep -i 'kexalgorithms')
output=$(sshd -T | grep -Pi -- 'kexalgorithms\h+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b')
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[32m[+] KexAlgorithms sin cifrados debiles:\n-> $output2\e[0m"
else
        if [[ $output == *"kexalgorithms no"* ]]; then
                echo -e "\e[38;5;210m[!] KexAlgorithms no está habilitado:\n-> $output\e[0m"
        else
                echo -e "\e[32m[+] KexAlgorithms habilitado:\n-> $output2\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd LoginGraceTime configurado\e[0m"
output=$(sshd -T | grep -i logingracetime)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] LoginGraceTime no habilitado\e[0m"
else
        if [[ $output != "logingracetime 60" ]]; then
                echo -e "\e[33m[!] $output -> El valor recomendado es 60"
        else
                echo -e "\e[32m[+] LoginGraceTime correctamente configurado\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd LogLevel configurado: INFO o VERBOSE\e[0m"
output=$(sshd -T | grep -i loglevel)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] LogLevel no habilitado\e[0m"
else
        if [[ $output == "loglevel VERBOSE" || $output == "loglevel INFO" ]]; then
                echo -e "\e[32m[+] $output"
        else
                echo -e "\e[38;5;210m[!] $output -> El valor de LogLevel deb eser INFO o VERBOSE\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd MACs estan configurados"
output2=$(sshd -T | grep -i 'macs')
output=$(sshd -T | grep -Pi -- 'macs\h+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b')
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[32m[+] Macs sin cifrados debiles:\n-> $output2\e[0m"
else
        if [[ $output == *"macs no"* ]]; then
                echo -e "\e[38;5;210m[!] Macs no está habilitado:\n-> $output\e[0m"
        else
                echo -e "\e[33m[!] Macs con cifrado debil:\n-> $output\e[0m"
                echo -e "\e[38;5;210m[!] Cifrados seguros:\n* HMAC-SHA1\n* HMAC-SHA2-256\n* HMAC-SHA2-384\n* HMAC-SHA2-512"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd MaxAuthTries configurado\e[0m"
output=$(sshd -T | grep -i maxauthtries)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] MaxAuthTries no habilitado\e[0m"
else
        if [[ $output != "maxauthtries 4" ]]; then
                echo -e "\e[33m[!] $output -> El valor recomendado es 4"
        else
                echo -e "\e[32m[+] MaxAuthTries correctamente configurado\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd MaxStartups configurado\e[0m"
output=$(sshd -T | awk '$1 ~ /^\s*maxstartups/{split($2, a, ":");{if(a[1] > 10 || a[2] > 30 || a[3] > 60) print $0}}')
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] MaxStartups no habilitado\e[0m"
else
        if [[ $output != "maxstartups 10:30:60" ]]; then
                echo -e "\e[33m[!] $output -> El valor recomendado es 10:30:60"
        else
                echo -e "\e[32m[+] MaxStartups correctamente configurado\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd PermitEmptyPasswords desactivo"
output=$(sshd -T | grep -i permitemptypasswords)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] PermitEmptyPasswords no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"permitemptypasswords no"* ]]; then
                echo -e "\e[32m[+] PermitEmptyPasswords desactivado:\n-> $output\e[0m"
    else
                echo -e "\e[31m[-] PermitEmptyPasswords activado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd PermitRootLogin desactivo"
output=$(sshd -T | grep -i permitrootlogin)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] PermitRootLogin no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"permitrootlogin no"* || $output == *"permitrootlogin without-password"* ]]; then
                echo -e "\e[32m[+] PermitRootLogin desactivado:\n-> $output\e[0m"
        if [[ $output == "permitrootlogin without-password" ]]; then
            echo -e "\e[38;5;210m[!] Without-Password -> quiere decir que puede utilizar\nmétodos de autenticación que no sean basados en\ncontraseñas, como las claves SSH."
        fi
    else
                echo -e "\e[31m[-] PermitRootLogin activado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m[*] sshd PermitUserEnvironment desactivo"
output=$(sshd -T | grep -i permituserenvironment)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] PermitUserEnvironment no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"permituserenvironment no"* ]]; then
                echo -e "\e[32m[+] PermitUserEnvironment desactivado:\n-> $output\e[0m"
    else
                echo -e "\e[31m[-] PermitUserEnvironment activado:\n-> $output\e[0m"
        fi
fi

echo -e "\n"

echo -e "\e[34m sshd UsePAM activado"
output=$(sshd -T | grep -i usepam)
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
        echo -e "\e[38;5;210m[!] UsePam no habilitado:\n-> $output\e[0m"
else
        if [[ $output == *"usepam no"* ]]; then
                echo -e "\e[38;5;210m[!] UsePam desactivado:\n-> $output\e[0m"
    else
                echo -e "\e[32m[+] UsePam activado:\n-> $output\e[0m"
        fi
fi
