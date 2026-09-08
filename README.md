# 🚀 Despliegue Automatizado de Moodle + Correo + Monitorización con Ansible

Este repositorio contiene un conjunto completo de playbooks y roles de Ansible para desplegar un servidor VPS (OVH, 8 vCores, 24 GB RAM) con Ubuntu 26.04 LTS que aloja:

- **Moodle 5.2** (última versión estable) para 200 usuarios concurrentes.
- **Servidor web**: Nginx + PHP-FPM 8.4.
- **Base de datos**: MariaDB 11.x optimizada.
- **Caché**: Redis 7.x.
- **Servidor de correo**: Postfix + Dovecot (usuarios virtuales) + ClamAV + SpamAssassin + DKIM/DMARC/SPF.
- **Monitorización dual**: Fail2ban/RKHunter/Monit + Prometheus/Grafana.
- **Hardening avanzado**: SSH, UFW, sysctl, límites, unattended-upgrades.

## 📋 Requisitos previos

- **Ansible** 2.16+ instalado en tu máquina local.
- **Python 3**.
- Acceso SSH al servidor (puerto 22 inicialmente) con usuario `ubuntu` y contraseña (o clave temporal).
- **VirtualBox** y **Vagrant** (opcional, para pruebas locales).
- **LXD** (opcional, para pruebas rápidas con contenedores).
- **Colecciones de Ansible** (se instalarán con `ansible-galaxy`).

## 📂 Estructura del proyecto

```
ansible-project/
├── .gitignore
├── ansible.cfg
├── requirements.yml
├── Vagrantfile
├── test-with-lxd.sh
├── generate_vault_pass.sh
├── encrypt_secrets.sh
├── .pre-commit-config.yaml
├── .pre-commit-scripts/
├── inventory/
│   ├── production/
│   │   ├── hosts-initial.yml   # Primera conexión (ubuntu, puerto 22, contraseña vault)
│   │   └── hosts.yml           # Después del hardening (mario, puerto 22/6022, clave SSH)
│   ├── staging/
│   │   └── hosts.yml           # Pruebas con Vagrant
│   └── lxd/
│       └── hosts.yml           # Pruebas rápidas con LXD
├── group_vars/
│   └── all.yml                 # Variables globales (secretos cifrados)
├── playbooks/
│   ├── prepare-server.yml      # Solo common + ssh-hardening (hardening inicial)
│   └── site.yml                # Despliegue completo (Moodle + Correo + Monitorización)
├── roles/
│   ├── common/
│   ├── ssh-hardening/
│   ├── mariadb/
│   ├── redis/
│   ├── nginx-php/
│   ├── mail/
│   ├── letsencrypt/
│   ├── moodle/
│   ├── monitoring-base/
│   ├── monitoring-prometheus/
│   └── monitoring-grafana/
├── vault_pass.txt              # (NO SUBIR A GIT) archivo con la contraseña del vault
└── README.md
```

## 🛠️ Instalación y configuración

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio> ansible-project
cd ansible-project
```

### 2. Instalar las colecciones de Ansible

```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Generar la contraseña de Vault

```bash
chmod +x generate_vault_pass.sh
./generate_vault_pass.sh
```

### 4. Crear el archivo de secretos en texto plano (`secrets.plain.yml`)

Crea un archivo `secrets.plain.yml` en el directorio raíz con el siguiente contenido (cambia los valores):

```yaml
---
# MariaDB
mariadb_vault_db_root_password: "TuClaveRoot"
mariadb_vault_db_moodle_password: "TuClaveMoodle"
mariadb_vault_db_exporter_password: "TuClaveExporter"

# Redis
redis_vault_redis_password: "TuClaveRedis"

# Moodle
vault_moodle_admin_pass: "TuClaveAdminMoodle"
vault_upgrade_secret: "TuClaveUpgrade"

# Mail
mail_vmail_admin_pass: "TuClaveCorreoAdmin"

# Grafana
vault_grafana_password: "TuClaveGrafana"

# Usuario ubuntu (primera conexión)
vault_initial_password: "TuContraseñaUbuntu"
```

**⚠️ Importante**: Este archivo NO debe subirse a Git (ya está en `.gitignore`).

### 5. Cifrar los secretos y generar `group_vars/all.yml`

```bash
chmod +x encrypt_secrets.sh
./encrypt_secrets.sh
```

Esto creará `group_vars/all.yml` con todos los secretos cifrados.

### 6. Editar `group_vars/all.yml`

Ajusta las variables no sensibles:

- `dominio_web`, `dominio_correo`, `ip_publica`.
- `admin_user`, `admin_ssh_port`.
- Parámetros de rendimiento (MariaDB, Redis, PHP, Nginx).
- Versiones de Prometheus y exporters.
- **`nginx_use_ssl: true`** para habilitar HTTPS en producción.

### 7. Configurar los inventarios

#### `hosts-initial.yml` (primera conexión)

```yaml
---
all:
  children:
    vps:
      hosts:
        178.32.16.134:
          ansible_user: ubuntu
          ansible_port: 22
          ansible_password: "{{ vault_initial_password }}"
          ansible_python_interpreter: /usr/bin/python3
```

#### `hosts.yml` (después del hardening)

```yaml
---
all:
  children:
    vps:
      hosts:
        178.32.16.134:
          ansible_user: mario
          ansible_port: 22   # o 6022 si lo cambiaste
          ansible_ssh_private_key_file: ~/.ssh/id_ed25519_ansible
          ansible_python_interpreter: /usr/bin/python3
          nginx_use_ssl: true   # Habilitar HTTPS en producción
```

## 🚀 Despliegue en producción (flujo de dos pasos)

### Paso 1: Hardening inicial (con `prepare-server.yml`)

Este playbook se conecta como `ubuntu` con contraseña (del vault) y ejecuta solo los roles `common` y `ssh-hardening`. Crea el usuario `mario`, inyecta la clave pública, cambia el puerto SSH (opcional), deshabilita el usuario `ubuntu` y cierra el puerto 22.

```bash
ansible-playbook -i inventory/production/hosts-initial.yml playbooks/prepare-server.yml --vault-password-file vault_pass.txt
```

**Este paso debe ejecutarse solo la primera vez**, cuando el servidor está recién instalado.

### Paso 2: Despliegue completo (con `site.yml`)

Este playbook se conecta como `mario` (con clave privada) y ejecuta el resto de roles: MariaDB, Redis, Nginx, PHP, Mail, Let's Encrypt, etc.

```bash
ansible-playbook -i inventory/production/hosts.yml playbooks/site.yml --vault-password-file vault_pass.txt
```

**Este paso se puede ejecutar tantas veces como sea necesario** (es idempotente).

## 🔐 SSL en Nginx

Para habilitar HTTPS en Nginx, la variable `nginx_use_ssl` debe estar en `true` en el inventario o en `group_vars/all.yml`. Por defecto está en `false` para pruebas locales.

**Si quieres habilitar SSL en producción**, asegúrate de que:

- Los dominios (`dominio_web` y `dominio_correo`) resuelven a la IP pública.
- Los puertos 80 y 443 están abiertos en UFW (ya están permitidos).
- El rol `letsencrypt` está descomentado en `site.yml`.

## 🧪 Verificación del despliegue

### Verificar todos los servicios

```bash
ssh -p 22 mario@178.32.16.134 -i ~/.ssh/id_ed25519_ansible
systemctl status mariadb postfix dovecot php8.4-fpm redis nginx
```

### Web y Moodle

- Visita `https://{{ dominio_web }}` (si SSL está habilitado) o `http://{{ dominio_web }}`.
- Si Moodle no está instalado, la instalación se realiza automáticamente en el rol `moodle` (cuando esté descomentado).

### Correo electrónico

- Usa **MXToolbox** (<https://mxtoolbox.com>) para verificar DNS (SPF, DKIM, DMARC).
- Envía un correo de prueba con `swaks`:

```bash
swaks --to tu@email.com --server mail.{{ dominio_correo }} --port 587 --tls --auth LOGIN --auth-user admin@{{ dominio_correo }} --auth-password 'tu_contraseña'
```

### Monitorización

- **Prometheus**: `http://{{ ip_publica }}:9090` (solo desde el servidor; usa túnel SSH).
- **Grafana**: `http://{{ ip_publica }}:3000` (usuario `admin`, contraseña definida en vault).

## 🔧 Configuración de SSH

El rol `ssh-hardening` realiza las siguientes acciones:

- Crea el usuario `mario` con sudo sin contraseña.
- Inyecta la clave pública definida en `admin_public_key`.
- Cambia el puerto SSH a `admin_ssh_port` (por defecto 22 o 6022).
- Deshabilita `PermitRootLogin`.
- Establece `PasswordAuthentication no` y `ChallengeResponseAuthentication no`.
- Configura UFW: abre los puertos necesarios (SSH, HTTP, HTTPS, correo, etc.).
- Elimina archivos conflictivos de `cloud-init` que forzaban `PasswordAuthentication yes`.
- Bloquea y elimina al usuario `ubuntu` (común en VPS de OVH).

## 📝 Notas importantes

- **Idempotencia**: todos los roles están diseñados para ser idempotentes; puedes ejecutar los playbooks varias veces sin romper nada.
- **Secretos**: todas las contraseñas están cifradas con Ansible Vault. Asegúrate de no subir `secrets.plain.yml` ni `vault_pass.txt` a Git.
- **Certificados SSL**: el rol `letsencrypt` obtiene certificados para web y correo (si los dominios resuelven). Los certificados se renuevan automáticamente.
- **Dovecot 2.4.2**: la configuración usa la nueva sintaxis (`ssl_server_cert_file`, `mail_path` con `%{user | domain}`, etc.). Asegúrate de que las rutas de los certificados sean correctas.
- **Usuario `ubuntu`**: después del hardening, el usuario `ubuntu` queda deshabilitado/eliminado. El único acceso será con `mario`.
- **Pruebas locales**: usa LXD o Vagrant para validar cambios antes de desplegar en producción.

## 🧰 Herramientas recomendadas

- **MXToolbox**: Verificación de DNS, listas negras, SMTP.
- **Qualys SSL Labs**: Calificación SSL para tu sitio.
- **Security Headers Checker**: Análisis de cabeceras HTTP.
- **Swaks**: Envío de correos de prueba desde la línea de comandos.

## 📚 Recursos adicionales

- [Documentación oficial de Ansible](https://docs.ansible.com/)
- [Moodle 5.2](https://moodledev.io/)
- [Dovecot 2.4](https://doc.dovecot.org/2.4.2/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
