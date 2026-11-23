# Evidencias de validación — Docker multi-stage

Guardar capturas de terminal legibles, sin revelar .env ni credenciales.

1. **Repositorio público nuevo:** árbol con frontend/, backend/, db/, Dockerfiles y docker-compose.yml.
2. **`docker compose up -d --build`:** compilación exitosa de frontend, backend, nginx y MySQL.
3. **`docker compose ps`:** servicios arriba y MySQL saludable.
4. **Imágenes:** `docker image ls --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'` para mostrar los tamaños reales de las cuatro imágenes.
5. **Web funcional:** página http://localhost:3001 mostrando productos provenientes de la API.
6. **API:** http://127.0.0.1:8093/api/v1/products con JSON y Swagger en /api/documentation.
7. **Caché:** segunda compilación con `time docker compose --progress plain build` y capas reutilizadas (`CACHED`), tiempo observado: 6.846 s.
8. **Persistencia:** verificar que existen cinco productos, ejecutar `docker compose down` (sin `-v`), después `docker compose up -d --wait` y comprobar que los mismos cinco productos permanecen. No tocar los pedidos reales del proyecto anterior.

> Los diagramas Mermaid están en el README y GitHub los renderiza directamente.
