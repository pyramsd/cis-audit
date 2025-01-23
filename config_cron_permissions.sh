cron_files="/etc/crontab"
cron_files_hourly="/etc/cron.hourly"
cron_files_daily="/etc/cron.daily"
cron_files_weekly="/etc/cron.weekly"
cron_files_monthly="/etc/cron.monthly"
cron_files_d="/etc/cron.d"

echo -e "\e[34m[*] Asegúrese de que cron está activado y activo\e[0m"
cron_enabled=$(systemctl is-enabled cron)
cron_activated=$(systemctl is-active cron)
if [[ $cron_enabled == "enabled" ]]; then
        echo -e "\e[32m[+] Cron: $cron_enabled\e[0m"
else
        echo -e "\e[38;5;210m[!] Cron: $cron_enabled\e[0m"
fi

if [[ $cron_activated == "active" ]]; then
        echo -e "\e[32m[+] Cron: $cron_activated"
else
        echo -e "\e[38;5;210m[!] Cron: $cron_activated"
fi

echo -e "\n"

echo -e "\e[34m[*] Asegúrese de que los permisos en /etc/crontab están configurados\e[0m"
permissions_cron=$(stat -c "%a:%U%G" $cron_files)
permissions_cron_hourly=$(stat -c "%a:%U:%G" $cron_files_hourly)
permissions_cron_daily=$(stat -c "%a:%U:%G" $cron_files_daily)
permissions_cron_weekly=$(stat -c "%a:%U:%G" $cron_files_weekly)
permissions_cron_monthly=$(stat -c "%a:%U:%G" $cron_files_monthly)
permissions_cron_files_d=$(stat -c "%a:%U:%G" $cron_files_d)
echo "Permisos de $cron_files:"
if [[ $permissions_Cron == "600:root:root" ]]; then
        echo -e "\e[32m[+] $permissions_cron\e[0m\n"
else
        echo -e "\e[38;5;210m[!] $permissions_cron -> 600:root:root\e[0m\n"
fi

echo "Permisos de $cron_files_hourly"
if [[ $permissions_cron_hourly == "700:root:root" ]]; then
        echo -e "[\e[32m$permissions_cron_hourly\e[0m\n"
else
        echo -e "\e[38;5;210m[!] $permissions_cron_hourly -> 700:root:root\e[0m\n"
fi

echo "Permisos de $cron_files_daily"
if [[ $permissions_cron_daily == "700:root:root" ]]; then
        echo -e "[\e[32m$permissions_cron_hourly\e[0m\n"
else
        echo -e "\e[38;5;210m[!] $permissions_cron_hourly -> 700:root:root\e[0m\n"
fi

echo "Permisos de $cron_files_weekly"
if [[ $permissions_cron_weekly == "700:root:root" ]]; then
        echo -e "[\e[32m$permissions_cron_weekly\e[0m\n"
else
        echo -e "\e[38;5;210m[!] $permissions_cron_weekly -> 700:root:root\e[0m\n"
fi

echo "Permisos de $cron_files_monthly"
if [[ $permissions_cron_monthly == "700:root:root" ]]; then
        echo -e "[\e[32m$permissions_cron_monthly\e[0m\n"
else
        echo -e "\e[38;5;210m[!] $permissions_cron_monthly -> 700:root:root\e[0m\n"
fi

echo "Permisos de $cron_files_d"
if [[ $permissions_cron_files_d == "700:root:root" ]]; then
        echo -e "[\e[32m$permissions_cron_files_d\e[0m\n"
else
        echo -e "\e[38;5;210m[!] $permissions_cron_files_d -> 700:root:root\e[0m\n"
fi
