allowed_programs=()
if [[ -n "$ALLOWED_PROGRAMS_FILE" && -f "$ALLOWED_PROGRAMS_FILE" ]]; then
    # Leer líneas no vacías ni comentarios
    mapfile -t allowed_programs < <(grep -vE '^\s*(#|$)' "$ALLOWED_PROGRAMS_FILE")
else
    echo "No se encontró el archivo de programas permitidos: $ALLOWED_PROGRAMS_FILE" >&2
    exit 1
fi