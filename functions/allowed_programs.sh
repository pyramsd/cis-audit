allowed_programs=()
# Si no se definió la variable, simplemente continuar
if [[ -z "${ALLOWED_PROGRAMS_FILE:-}" ]]; then
    # No se especificó ningún archivo, así que no hacemos nada
    return 0
fi

# Si se especificó la variable pero el archivo no existe
if [[ ! -f "$ALLOWED_PROGRAMS_FILE" ]]; then
    echo "Error: No se encontró el archivo de programas permitidos: $ALLOWED_PROGRAMS_FILE" >&2
    exit 1
fi

# Si existe, cargarlo al array
mapfile -t allowed_programs < <(grep -vE '^\s*(#|$)' "$ALLOWED_PROGRAMS_FILE")

# Aviso opcional (solo si el archivo está vacío)
if [[ ${#allowed_programs[@]} -eq 0 ]]; then
    echo "Advertencia: El archivo $ALLOWED_PROGRAMS_FILE está vacío o solo contiene comentarios." >&2
fi