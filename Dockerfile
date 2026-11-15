# syntax=docker/dockerfile:1
# Build context: generated docker-context/ from GitHub Actions.
ARG NGINX_VERSION=1.28-alpine
FROM nginx:${NGINX_VERSION}
COPY nginx.conf /etc/nginx/nginx.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/nginx/html/legal/
USER nginx
EXPOSE 8080
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
