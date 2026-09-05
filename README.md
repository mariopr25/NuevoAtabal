# 🚀 Despliegue Automatizado de Moodle + Correo + Monitorización

Este repositorio contiene un conjunto completo de playbooks y roles de Ansible para desplegar un servidor VPS (OVH, 8 vCores, 24 GB RAM) con Ubuntu 26.04 LTS que aloja:

- **Moodle 5.2** (última versión estable) para 200 usuarios concurrentes.
- **Servidor web**: Nginx + PHP-FPM 8.4.
- **Base de datos**: MariaDB 11.x optimizada.
- **Caché**: Redis 7.x.
- **Servidor de correo**: Postfix + Dovecot (usuarios virtuales) + ClamAV + SpamAssassin + DKIM/DMARC/SPF.
- **Monitorización dual**: Fail2ban/RKHunter/Monit + Prometheus/Grafana.
- **Hardening avanzado**: SSH, UFW, sysctl, límites, unattended-upgrades.

---

## 📋 Requisitos previos

- **Ansible** 2.16+ instalado en tu máquina local.
- **Python 3**.
- Acceso SSH al servidor (puerto 22 inicialmente) con clave pública.
- **VirtualBox** y **Vagrant** (opcional, para pruebas locales).
- **LXD** (opcional, para pruebas ligeras).

---

## 🛠️ Instalación y configuración

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio> ansible-project
cd ansible-project
```

### 2. Generar la contraseña de Vault

```bash
chmod +x generate_vault_pass.sh
./generate_vault_pass.sh
```

### 3. Crear el archivo de secretos en texto plano (fuera del repositorio)

Crea un archivo `secrets.plain.yml` en el directorio raíz con el siguiente contenido (cambia los valores):

```yaml
---
vault_db_root_password: "TuClaveRoot"
vault_db_moodle_password: "TuClaveMoodle"
vault_db_exporter_password: "TuClaveExporter"
vault_redis_password: "TuClaveRedis"
vault_moodle_admin_pass: "TuClaveAdminMoodle"
vault_grafana_password: "TuClaveGrafana"
vault_upgrade_secret: "TuClaveUpgrade"
vmail_admin_pass: "TuClaveCorreoAdmin"
```

**⚠️ Importante**: Este archivo NO debe subirse a Git (ya está en `.gitignore`).

### 4. Cifrar los secretos y generar `group_vars/all.yml`

```bash
chmod +x encrypt_secrets.sh
./encrypt_secrets.sh
```

Esto creará `group_vars/all.yml` con todos los secretos cifrados.

### 5. Editar `group_vars/all.yml`

Ajusta las variables no sensibles:

- `dominio_web`, `dominio_correo`, `ip_publica`.
- `admin_user`, `admin_ssh_port`.
- Parámetros de rendimiento (MariaDB, Redis, PHP, Nginx).
- Versiones de Prometheus y exporters.

### 6. Configurar los inventarios

#### Producción (`inventory/production/hosts.yml`)

Reemplaza `tu_ip_publica` por la IP real de tu VPS.

#### Staging (`inventory/staging/hosts.yml`)

Para pruebas con Vagrant, ya está configurado.

### 7. (Opcional) Configurar pre-commit hooks

```bash
pip install pre-commit
pre-commit install
```

Esto evitará que subas accidentalmente secretos sin cifrar.

---

## 🚀 Ejecución del playbook

### En producción

```bash
ansible-playbook -i inventory/production/hosts.yml playbooks/site.yml --ask-vault-pass
```

### En pruebas con Vagrant

```bash
vagrant up --provider=virtualbox
```

El provisioner ejecutará Ansible automáticamente.

### En pruebas con LXD

```bash
lxc launch ubuntu:26.04 moodle-test
lxc list moodle-test   # obtén la IP
ansible-playbook -i "IP_DEL_CONTENEDOR," -u root --private-key ~/.ssh/id_rsa playbooks/site.yml
```

---

## ✅ Validación del despliegue

### 🌐 Web y Moodle

- Visita `https://{{ dominio_web }}` y completa la instalación (si no se hizo automáticamente).
- Verifica que el sitio cargue correctamente.

### 📧 Correo electrónico

- Usa **MXToolbox** (<https://mxtoolbox.com>) para verificar:
  - Registros DNS (A, MX, TXT, SPF, DKIM, DMARC).
  - Listas negras (blacklist checks).
  - Diagnóstico SMTP.
- Envía un correo de prueba con `swaks`:

  ```bash
  swaks --to tu@email.com --server {{ dominio_correo }} --port 587 --tls --auth LOGIN --auth-user admin@{{ dominio_correo }} --auth-password 'tu_contraseña' --header "Subject: Test" --body "Test"
  ```

- Revisa las cabeceras del correo recibido para verificar DKIM, SPF, DMARC y puntuación de SpamAssassin.

### 📊 Monitorización

- **Prometheus**: `http://{{ ip_publica }}:9090` (solo desde el servidor; usa túnel SSH para acceder). Todos los targets deben estar UP.
- **Grafana**: `http://{{ ip_publica }}:3000` (usuario `admin`, contraseña definida en vault). Los dashboards importados deben mostrar datos.
- **Monit**: `monit status` (en el servidor) muestra todos los servicios en verde.

### 🔒 Seguridad del sistema

- SSH en puerto 6022 (o el configurado) con clave pública.
- `ufw status verbose` muestra las reglas esperadas.
- `fail2ban-client status` muestra los jails activos.

---

## 🧰 Herramientas recomendadas para validación

### Para correo y DNS

- **MXToolbox** (web): Verificación de DNS, listas negras, SMTP.
- **swaks** (CLI): Envío de correos de prueba.
- **aboutmy.email**: Análisis detallado de SPF, DKIM, DMARC.
- **MailTrap** (sandbox): Captura de correos en desarrollo.

### Para SSL/TLS y seguridad web

- **Qualys SSL Labs**: Calificación A+ para tu sitio.
- **Security Headers Checker**: Análisis de cabeceras HTTP (CSP, HSTS, etc.).

### Para seguridad del servidor

- **CQwerty Shield** (extensión Chrome): Calificación instantánea.
- **websec-audit** (CLI): Verifica SPF, DMARC, DKIM y listas negras.

---

## 🧩 Plugins de VS Code recomendados y su utilidad

 | Plugin | ID | Utilidad |
 | ------ | -- | -------- |
 | **Ansible** | `redhat.ansible` | Resaltado de sintaxis, autocompletado, linting y ejecución de tareas Ansible desde el editor. |
 | **YAML** | `redhat.vscode-yaml` | Validación y autocompletado para archivos YAML (inventarios, variables, playbooks). |
 | **GitLens** | `eamodio.gitlens` | Visualización avanzada de historial de Git, blame, autores y comparaciones. |
 | **Prettier** | `esbenp.prettier-vscode` | Formateo automático de YAML, JSON, Markdown para mantener consistencia. |
 | **EditorConfig** | `editorconfig.editorconfig` | Mantiene reglas de formato (indentación, saltos de línea) entre diferentes editores y equipos. |
 | **Remote - SSH** | `ms-vscode-remote.remote-ssh` | Permite conectarte al VPS y editar archivos remotos directamente desde VS Code. |
 | **Git Graph** | `mhutchie.git-graph` | Visualización gráfica del historial de commits y ramas. |
 | **Hashicorp Terraform** | `hashicorp.terraform` | (Opcional) Si usas Terraform para infraestructura adicional. |

---

## 📝 Notas importantes

- El playbook es **idempotente**: puedes ejecutarlo varias veces sin romper nada.
- **Orden de ejecución**: `letsencrypt` se ejecuta **antes** que `nginx-php` para que los certificados estén disponibles.
- **Usuarios virtuales de correo**: los usuarios se almacenan en `/etc/dovecot/passwd`; el usuario administrador es `admin@{{ dominio_correo }}`.
- **Prometheus y Grafana** escuchan en `127.0.0.1` por seguridad; para acceder desde fuera, usa un túnel SSH.
- **Registros DNS**: el playbook genera `dns_records.txt`; debes añadirlos manualmente en tu proveedor DNS.

---

## 🔄 Cambios respecto a versiones anteriores

- **Inventarios migrados a YAML** para mejor legibilidad y coherencia.
- **Let's Encrypt se ejecuta antes de Nginx** (modo standalone).
- **Correo con usuarios virtuales** (passwd-file) en lugar de usuarios del sistema.
- **Gestión de secretos mejorada** con `secrets.plain.yml` + script de cifrado + pre-commit.
- **Prometheus y Grafana escuchan en localhost**.
- **Versiones de exporters parametrizadas**.
- **Logs de PHP** en `/var/log/php` con permisos adecuados.

---

## 📚 Recursos adicionales

- [Documentación oficial de Ansible](https://docs.ansible.com/)
- [Moodle 5.2](https://moodledev.io/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)

---

**¡Disfruta de tu infraestructura educativa segura, escalable y monitorizada!**
