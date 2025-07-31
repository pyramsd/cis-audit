echo -e "\e[1;34m[*] Permisos de los archivos del sistema"
echo -e "(permission bits in octal/user ID of owner/group name of owner)${RESET}"
system_files=(
    "/etc/passwd:0644:0/root:0/root"
    "/etc/passwd-:0644:0/root:0/root"
    "/etc/group:0644:0/root:0/root"
    "/etc/group-:0644:0/root:0/root"
    "/etc/shadow:0640:0/root:42/shadow"
    "/etc/shadow-:0640:0/root:42/shadow"
    "/etc/gshadow:0640:0/root:42/shadow"
    "/etc/gshadow-:0640:0/root:42/shadow"
    "/etc/shells:0644:0/root:0/root"
    "/etc/security/opasswd:0600:0/root:0/root"
)

for entry in "${system_files[@]}"; do
        file=$(echo "$entry" | cut -d: -f1)
        expected_perms=$(echo "$entry" | cut -d: -f2-)

        if [ -e "$file" ]; then
                # Obtener los permisos reales del archivo
                actual_perms=$(stat -Lc "%#a:%u/%U:%g/%G" "$file")

                if [ "$actual_perms" == "$expected_perms" ]; then
                        echo "Archivo $file:"
                        echo -e "${GREEN}-> $actual_perms\n${RESET}"
                        counter=$((counter + 1))
                else
                        echo -e "\e[38;5;210m[-] ADVERTENCIA: Los permisos del archivo $file son $actual_perms"
                        echo -e "${YELLOW}[!] Pero deberían ser $expected_perms"
                fi
        else
                echo -e "\e[38;5;210m[-] El archivo $file no existe"
        fi
done
