# Validación funcional y medición de imágenes

Resultados obtenidos en el entorno de desarrollo durante la evaluación (22 de noviembre de 2026). Los tamaños y tiempos dependen de la plataforma y de la caché existente.

## Salud e integración

| Prueba | Resultado observado |
|---|---|
| GET `http://127.0.0.1:8093/up` | HTTP 200 |
| GET `http://127.0.0.1:8093/api/v1/products` | HTTP 200 |
| GET `http://127.0.0.1:3001` | HTTP 200 |
| Solicitud desde el contenedor `frontend` a `http://nginx/api/v1/products` | HTTP 200; cinco productos recibidos |
| Navegación a frontend, API y Swagger UI | Verificada manualmente en navegador |
| Migraciones de Laravel | Diez migraciones ejecutadas correctamente |
| Seeders | `ProductSeeder` finalizado correctamente |
| Docker Compose | Cuatro contenedores iniciados; MySQL y Nginx `healthy` |

## Tamaño de imágenes

Comando: `docker image ls --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'`.

| Imagen final | Tamaño mostrado por Docker |
|---|---:|
| `kodigo-multistage/nextjs:latest` | **308 MB** |
| `kodigo-multistage/laravel:latest` | **240 MB** |
| `kodigo-multistage/nginx:latest` | **101 MB** |
| `kodigo-multistage/mysql:8.4` | **1.1 GB** |

Como referencia, el equipo también tenía una imagen anterior `api-ecommerce-kodigo-app:latest` de **831 MB**. La imagen Laravel optimizada marca **240 MB**, aproximadamente un **71.1 % menos de tamaño reportado**, aunque **no es una comparación experimental estrictamente controlada**: las dos imágenes provienen de configuraciones y bases distintas. La imagen MySQL sigue utilizando la base oficial, y su tamaño corresponde en gran medida al propio servidor de base de datos.

## Caché de construcción

Comando ejecutado: `time docker compose --progress plain build` (la versión original imprimió una advertencia sobre la posición de `--progress`, pero la construcción finalizó).

**Tiempo observado:** `real 0m6.846s`.

Durante la reconstrucción, las instrucciones de instalación de paquetes, `npm ci`, `next build`, `composer install` y otras etapas principales aparecieron como **`CACHED`**. Esto evidencia reutilización de capas cuando no han cambiado las dependencias ni los archivos relevantes. El resultado es una medición de reconstrucción en caliente, **no de primera compilación ni de reducción porcentual de tiempo**.

## Persistencia de datos

**Pendiente de documentar con el resultado posterior al reinicio.** Comprobar mediante lectura del conteo de productos antes y después de `docker compose down` + `docker compose up -d --wait`, sin opción `-v`.

## Alcance y limitaciones

- Los puertos publicados solo escuchan en loopback (`127.0.0.1`); no se configura TLS público.
- No se registró una prueba de compra Stripe en este nuevo entorno Docker; requiere sandbox y webhook activos.
- Los tamaños de `docker image ls` son medidas locales; no confundir con consumo de RAM ni tamaño comprimido en el registro remoto.
- No se hizo un benchmark de múltiples builds en frío ni pruebas de carga. No corresponde afirmar esas mediciones.
