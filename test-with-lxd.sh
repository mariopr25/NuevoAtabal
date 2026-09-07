#!/bin/bash
# test-with-lxd.sh - Prueba rápida del playbook en un contenedor LXD
# Usa el plugin LXD de Ansible (sin SSH)

set -e

CONTAINER_NAME="moodle-test"
PLAYBOOK="playbooks/site.yml"
INVENTORY="inventory/lxd/hosts.yml"
VAULT_PASS="vault_pass.txt"

# --- CONFIGURACIÓN DE CLAVES ---
SSH_PUB_KEY="$HOME/.ssh/id_ed25519_migracion.pub"
# --- FIN CONFIGURACIÓN ---

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Prueba con LXD para Moodle ===${NC}"

# Verificar que la clave pública existe
if [ ! -f "$SSH_PUB_KEY" ]; then
    echo -e "${RED}No existe la clave pública: $SSH_PUB_KEY${NC}"
    exit 1
fi

# Verificar que LXD está instalado
if ! command -v lxc &> /dev/null; then
    echo -e "${RED}LXD no está instalado. Sigue el tutorial en el README.${NC}"
    exit 1
fi

# Verificar que la colección community.general está instalada
if ! ansible-galaxy collection list community.general &> /dev/null; then
    echo -e "${YELLOW}Instalando colección community.general...${NC}"
    ansible-galaxy collection install community.general
fi

# Verificar que el vault pass existe
if [ ! -f "$VAULT_PASS" ]; then
    echo -e "${RED}No existe $VAULT_PASS. Ejecuta generate_vault_pass.sh${NC}"
    exit 1
fi

# Verificar que group_vars/all.yml existe
if [ ! -f "group_vars/all.yml" ]; then
    echo -e "${RED}No existe group_vars/all.yml. Ejecuta encrypt_secrets.sh${NC}"
    exit 1
fi

# Asegurar que existe el directorio inventory/lxd
mkdir -p inventory/lxd

# Función para obtener la IP del contenedor
get_container_ip() {
    local ip
    ip=$(lxc list "$CONTAINER_NAME" --format csv -c n,4 | awk -F, '{print $2}' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    if [ -z "$ip" ] || [ "$ip" == "127.0.0.1" ]; then
        ip=$(lxc info "$CONTAINER_NAME" | grep -oP 'inet:\s+\K[0-9.]+' | grep -v '127.0.0.1' | head -1)
    fi
    echo "$ip"
}

# Función para inyectar la clave pública en el contenedor
inject_ssh_key() {
    echo "Inyectando clave pública SSH en el contenedor..."
    lxc exec "$CONTAINER_NAME" -- mkdir -p /root/.ssh
    lxc exec "$CONTAINER_NAME" -- chmod 700 /root/.ssh
    cat "$SSH_PUB_KEY" | lxc exec "$CONTAINER_NAME" -- tee /root/.ssh/authorized_keys > /dev/null
    lxc exec "$CONTAINER_NAME" -- chmod 600 /root/.ssh/authorized_keys
    echo "Verificando clave inyectada..."
    lxc exec "$CONTAINER_NAME" -- cat /root/.ssh/authorized_keys
}

# Lanzar contenedor si no existe
if ! lxc info "$CONTAINER_NAME" &> /dev/null; then
    echo "Creando contenedor $CONTAINER_NAME con Ubuntu 26.04..."
    lxc launch ubuntu:26.04 "$CONTAINER_NAME"
    sleep 5
    
    # Esperar a que la red esté lista
    echo "Esperando que el contenedor tenga red..."
    CONTAINER_IP=""
    while [ -z "$CONTAINER_IP" ] || [ "$CONTAINER_IP" == "127.0.0.1" ]; do
        CONTAINER_IP=$(get_container_ip)
        sleep 2
    done
    echo "IP obtenida: $CONTAINER_IP"
    
    echo "Instalando Python (necesario para Ansible)..."
    lxc exec "$CONTAINER_NAME" -- apt update
    lxc exec "$CONTAINER_NAME" -- apt install -y python3 python3-apt
    
    # Inyectar clave pública para root
    inject_ssh_key
    
    # Crear snapshot base para reinicios rápidos
    echo "Creando snapshot base..."
    lxc snapshot "$CONTAINER_NAME" base
else
    echo "Restaurando snapshot base del contenedor..."
    lxc restore "$CONTAINER_NAME" base
    sleep 5
    
    # Esperar a que la red esté lista
    echo "Esperando que el contenedor tenga red..."
    CONTAINER_IP=""
    while [ -z "$CONTAINER_IP" ] || [ "$CONTAINER_IP" == "127.0.0.1" ]; do
        CONTAINER_IP=$(get_container_ip)
        sleep 2
    done
    echo "IP obtenida: $CONTAINER_IP"
    
    # Inyectar clave pública para root (por si el snapshot no la tiene)
    inject_ssh_key
fi

# Obtener IP final (solo para mostrar)
IP=$(get_container_ip)
if [ -z "$IP" ] || [ "$IP" == "127.0.0.1" ]; then
    echo -e "${RED}No se pudo obtener la IP del contenedor.${NC}"
    exit 1
fi
echo "IP del contenedor: $IP"

# Crear inventario YAML usando el plugin LXD (sin SSH)
cat > "$INVENTORY" <<EOF
---
all:
  children:
    moodle_lxd:
      hosts:
        $CONTAINER_NAME:
          ansible_connection: community.general.lxd
          ansible_host: $CONTAINER_NAME
          ansible_user: root
          ansible_python_interpreter: /usr/bin/python3
          lxd_ssl_verify: false
          ansible_remote_tmp: /tmp/ansible_tmp
          ansible_pipelining: true
EOF

echo "Ejecutando playbook contra el contenedor LXD usando el plugin LXD..."
export ANSIBLE_ROLES_PATH="$PWD/roles"
# Saltar la tarea de DNS (no necesaria para pruebas)
ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --vault-password-file "$VAULT_PASS" --skip-tags dns

echo -e "${GREEN}✅ Prueba completada. El contenedor $CONTAINER_NAME está listo.${NC}"
echo "Para volver a probar desde cero: lxc restore $CONTAINER_NAME base"