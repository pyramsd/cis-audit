#!/usr/bin/env bash

# ====== Configuración ======
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/logs/errors.log"

# ====== Verificación de existencia ======
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: No se encontró el archivo: $LOG_FILE" >&2
    exit 1
fi

# ====== Cargar líneas útiles ======
mapfile -t lineas < <(grep -vE '^\s*(#|$)' "$LOG_FILE")

if (( ${#lineas[@]} == 0 )); then
    echo "El archivo existe pero no tiene contenido útil."
    exit 0
fi

# ====== Agrupar por tipo ======
declare -A grupos
for linea in "${lineas[@]}"; do
    if [[ "$linea" =~ ^\[([A-Z_]+)\]\ (.*) ]]; then
        tipo="${BASH_REMATCH[1]}"
        contenido="${BASH_REMATCH[2]}"
        grupos["$tipo"]+="${contenido}"$'\n'
    fi
done

# ====== Nombres legibles ======
declare -A nombres_legibles=(
    ["FILE_PERMISSION"]="Permisos de archivos"
    ["FIREWALL"]="Firewall"
    ["SOFTWARE"]="Software"
    ["CONFIG"]="Configuración"
    ["PRIVILEGE"]="Escalado de privilegios"
    ["ROOT_ACCOUNT"]="Cuenta root"
    ["GROUP"]="Grupos de usuario"
)

# ====== Funciones de solución ======
mostrar_solucion() {
    local tipo="$1" subtipo="$2"

    echo
    echo -e "${YELLOW}Solución recomendada para $tipo → $subtipo:"

    case "$tipo:$subtipo" in
        "SOFTWARE" | "SOFTWARE:")
            echo -e "1. Crea un archivo que contenga programas permitidos en tu sistema."
            echo -e "  vim whitelist.txt"
            echo -e "  ftp\n  rync\n  telnet\n"
            echo -e "2. Ejecute el script:\n   -> sudo cis-audit --allowded-programs=whitelist.txt${RESET}"
            ;;
        "CONFIG:SUDO")
            sudo_log_file="/var/log/sudo.log"
            if [[ ! -f "$sudo_log_file" ]]; then
                echo -e "\n- Añadir el archivo: $sudo_log_file" >&2
                echo -e "echo \"Defaults        logfile=\"/var/log/sudo.log\"\" >> /etc/sudoers${RESET}" 
            fi
            ;;
        *)
            echo -e "No hay una solución específica registrada para este subtipo."
            ;;
    esac

    echo

    read -p "¿Desea aplicar la solución? (s/N): " resp
    if [[ "$resp" =~ ^[sSyY]$ ]]; then
        echo -e "${GREEN}Aplicando solución...${RESET}"
        aplicar_solucion "$tipo" "$subtipo"
        sleep 1
    else
        echo -e "${BLUE}Volviendo al menú principal...${RESET}"
        sleep 1
    fi
}

aplicar_solucion() {
    local tipo="$1" subtipo="$2"
    case "$tipo:$subtipo" in
        "CONFIG:SUDO")
            sudo_log_file="/var/log/sudo.log"
            if [[ ! -f "$sudo_log_file" ]]; then
                echo "Defaults        logfile=\"/var/log/sudo.log\"" >> /etc/sudoers 
            fi
            ;;
        *)
            echo "Sin acción específica para este tipo/subtipo."
            ;;
    esac
}

# ====== Bucle principal ======
while true; do
    clear
    echo -e "${BLUE}Corregir errores:"
    echo -e "====================${RESET}"
    i=1
    declare -A opciones
    for tipo in "${!grupos[@]}"; do
        nombre="${nombres_legibles[$tipo]:-$tipo}"
        echo -e "${PURPLE}$i.${RESET} $nombre"
        opciones["$i"]="$tipo"
        ((i++))
    done

    echo
    read -p "Seleccione una opción (o 0 para salir): " seleccion
    [[ "$seleccion" == "0" ]] && break
    tipo_elegido="${opciones[$seleccion]}"
    [[ -z "$tipo_elegido" ]] && continue

    # Detectar subtipos
    mapfile -t subtareas < <(echo "${grupos[$tipo_elegido]}" | grep -oE '^[A-Za-z0-9_]+:' | sed 's/://g' | sort -u)

    if (( ${#subtareas[@]} > 0 )); then
        echo
        echo "Subtipos en ${nombres_legibles[$tipo_elegido]:-$tipo_elegido}:"
        j=1
        declare -A subopciones
        for sub in "${subtareas[@]}"; do
            echo -e "${PURPLE}$j.${RESET} $sub"
            subopciones["$j"]="$sub"
            ((j++))
        done

        echo
        read -p "Seleccione un subtipo: " subsel
        subtipo="${subopciones[$subsel]}"
        [[ -z "$subtipo" ]] && continue

        mostrar_solucion "$tipo_elegido" "$subtipo"
    else
        mostrar_solucion "$tipo_elegido" ""
    fi
done
