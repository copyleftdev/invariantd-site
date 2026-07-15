FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY dashboard/ /srv/dashboard/

EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:80/ || exit 1
