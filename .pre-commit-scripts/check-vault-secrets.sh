#!/bin/bash
# Verifica que todas las variables vault_ estén cifradas
if grep -E '^vault_[a-zA-Z0-9_]+:' group_vars/all.yml | grep -v '!vault' > /dev/null; then
    echo "❌ Error: Hay secretos sin cifrar en group_vars/all.yml"
    exit 1
fi
exit 0
