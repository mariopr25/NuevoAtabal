#!/bin/bash
# Genera una contraseña aleatoria para Ansible Vault y la guarda en vault_pass.txt

if [ ! -f vault_pass.txt ]; then
    echo "Generando vault_pass.txt..."
    openssl rand -base64 32 > vault_pass.txt
    chmod 600 vault_pass.txt
    echo "vault_pass.txt creado. No lo subas a Git."
else
    echo "vault_pass.txt ya existe."
fi