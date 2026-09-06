#!/bin/bash
set -e

if [ ! -f secrets.plain.yml ]; then
    echo "ERROR: No existe secrets.plain.yml"
    exit 1
fi

VAULT_PASS_FILE="vault_pass.txt"
if [ ! -f "$VAULT_PASS_FILE" ]; then
    echo "ERROR: No existe vault_pass.txt"
    exit 1
fi

# Vaciar el archivo de salida
> group_vars/all.yml

# Leer el archivo línea por línea
while IFS= read -r line; do
    # Ignorar líneas vacías y comentarios
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    # Buscar líneas con "variable: valor"
    if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*:[[:space:]]*(.+)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        echo "Cifrando $var_name..."
        # Cifrar con --vault-password-file
        encrypted=$(ansible-vault encrypt_string "$var_value" --name "$var_name" --vault-password-file "$VAULT_PASS_FILE" 2>&1)
        if [ $? -ne 0 ]; then
            echo "ERROR: Falló el cifrado de $var_name. Mensaje: $encrypted"
            exit 1
        fi
        # Añadir la línea cifrada al archivo
        echo "$encrypted" >> group_vars/all.yml
    fi
done < secrets.plain.yml

echo "✅ group_vars/all.yml generado con todos los secretos cifrados."