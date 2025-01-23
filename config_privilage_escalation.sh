echo -e "\e[34m[*] Sudo instalado"
if dpkg-query -s sudo &>/dev/null; then
    echo -e "\e[32m[+] Sudo instalado"
else
    echo -e "\e[31m[-] Sudo no instalado"
fi

echo -e "\n"

echo -e "\e[34m[*] Los comandos sudo utilizan pty"
output1=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,\h*)?use_pty\b' /etc/sudoers*)
output2=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,\h*)?!use_pty\b' /etc/sudoers*)
exit_code2=$?
echo $exit_code2 
if [[ $output1 == "/etc/sudoers:Defaults       use_pty" && $exit_code2 -ne 0 ]]; then
    echo -e "\e[32m[+] $output1"
else
    echo -e "\e[31m[-] $output1 $output2"
fi