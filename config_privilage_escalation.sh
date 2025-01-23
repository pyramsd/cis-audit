echo -e "\e[34m[*] Sudo instalado"
if dpkg-query -s sudo &>/dev/null; then
    echo -e "\e[32m[+] Sudo instalado"
else
    echo -e "\e[31m[-] Sudo no instalado"
fi
