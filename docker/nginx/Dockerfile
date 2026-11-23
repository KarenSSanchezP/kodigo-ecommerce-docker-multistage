# Imagen ligera e independiente de Nginx. Reutiliza el contexto de la API.
FROM nginx:stable-alpine
COPY docker/nginx/production.conf /etc/nginx/conf.d/default.conf
COPY public/ /var/www/html/public/
EXPOSE 80
