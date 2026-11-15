FROM node:22-bookworm-slim

ENV NODE_ENV=production
WORKDIR /app

COPY backend/package.json backend/package.json
COPY backend/src backend/src
COPY backend/sql backend/sql
COPY web/seo web/seo

# Страницы сайта не хранятся в git: собираем их здесь.
# --api= (пусто): страницы обращаются к тому же серверу, с которого открыты.
RUN node web/seo/build-seo.mjs --api=

RUN mkdir -p backend/data/uploads && chown -R node:node /app

USER node
WORKDIR /app/backend

EXPOSE 3000
VOLUME ["/app/backend/data"]

CMD ["sh", "-c", "node src/migrate.js && node src/server.js"]