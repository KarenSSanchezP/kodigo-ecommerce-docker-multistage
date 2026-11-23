#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ ! -e .env ]] || { echo 'Ya existe .env; se conserva sin cambios.'; exit 0; }
command -v openssl >/dev/null || { echo 'Se necesita openssl para generar claves.'; exit 1; }
cp .env.example .env
set_env() { local name="$1" value="$2"; sed -i "s|^${name}=.*|${name}=${value}|" .env; }
set_env APP_KEY "base64:$(openssl rand -base64 32)"
set_env JWT_SECRET "$(openssl rand -hex 32)"
set_env DB_PASSWORD "$(openssl rand -hex 24)"
set_env MYSQL_ROOT_PASSWORD "$(openssl rand -hex 24)"
chmod 600 .env
printf '%s\n' 'Archivo .env creado con secretos aleatorios y permisos 600.' 'No publiques, imprimas ni compartas .env.'
