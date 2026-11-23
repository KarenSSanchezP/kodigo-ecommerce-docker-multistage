#!/usr/bin/env bash
# Reutiliza los repositorios públicos sin traer sus historiales Git ni secretos.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -e frontend || -e backend ]]; then
  echo "ERROR: ya existe frontend/ o backend/. No se sobrescribirá código." >&2
  exit 1
fi
for cmd in git cp mktemp; do command -v "$cmd" >/dev/null || { echo "Falta $cmd"; exit 1; }; done
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo 'Descargando la versión pública del frontend...'
git clone --depth 1 https://github.com/KarenSSanchezP/frontend-ecommerce-kodigo.git "$TMP/frontend"
echo 'Descargando la versión pública del backend...'
git clone --depth 1 https://github.com/KarenSSanchezP/api-ecommerce-kodigo.git "$TMP/backend"
# Crear copias sin los directorios .git de los proyectos originales.
rm -rf "$TMP/frontend/.git" "$TMP/backend/.git"
mv "$TMP/frontend" ./frontend
mv "$TMP/backend" ./backend

# Aplicar Dockerfiles y configuración de producción SOLO en este nuevo repositorio.
cp docker/frontend/Dockerfile frontend/Dockerfile
cp docker/frontend/.dockerignore frontend/.dockerignore
cp docker/frontend/next.config.ts frontend/next.config.ts
cp docker/backend/Dockerfile backend/Dockerfile
cp docker/backend/.dockerignore backend/.dockerignore
mkdir -p backend/docker/nginx
cp docker/nginx/Dockerfile backend/docker/nginx/Dockerfile
cp docker/nginx/production.conf backend/docker/nginx/production.conf
mkdir -p db
cp docker/db/Dockerfile db/Dockerfile

# El catálogo consulta la API cuando llega una solicitud HTTP, no durante next build.
CATALOG=frontend/components/product-catalog.tsx
if ! grep -Fq "import { connection } from 'next/server';" "$CATALOG"; then
  sed -i "/^import { getProducts } from '@\/lib\/products';$/a import { connection } from 'next/server';" "$CATALOG"
fi
if ! grep -Fq 'await connection();' "$CATALOG"; then
  sed -i '/^export async function ProductCatalog() {$/a\  await connection();' "$CATALOG"
fi

echo 'Código importado. Revisa frontend/ y backend/; este script NO modifica los repositorios originales.'
