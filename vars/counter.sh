counter=0

calcular_porcentaje() {
    local parte=$1
    local total=81

    if [ "$total" -eq 0 ]; then
        echo "Error: División por cero"
        return 1
    fi

    # Usamos bc para precisión decimal
    porcentaje=$(echo "scale=2; ($parte * 100) / $total" | bc)
    echo "$porcentaje%"
}
