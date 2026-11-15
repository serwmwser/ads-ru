\# Выкладка HiMeet Объявления на сервер (Docker)



Сайт работает в одном контейнере: бэкенд на Node 22 сам отдаёт и API, и статические страницы из `web/public`.

База (SQLite) и загруженные фото хранятся в томе `ads\_data`.



> Данные россиян по 152-ФЗ нужно хранить на сервере в РФ. Если рабочий сервер находится за границей,

> используйте его только для теста, а боевой запуск делайте на сервере в РФ. Контейнер для этого не меняется.



\## 0. Что нужно заранее

\- Сервер Linux (Ubuntu 22.04 или новее), доступ `ssh root@IP\_СЕРВЕРА`

\- Домен или поддомен, например `ads.himeet.online`

\- Код проекта в репозитории GitHub



\## 1. Проверьте, что секреты не попадут в репозиторий (на ноутбуке)

```bash

cd /c/Users/Admin/ads

grep -n "env" .gitignore

```

В выводе должна быть строка `.env`. Если её нет, добавьте её в `.gitignore` до первого коммита.



\## 2. Отправьте новые файлы в репозиторий (на ноутбуке)

```bash

git status --short

git add Dockerfile docker-compose.yml .env.example docs/deploy-ru.md

git commit -m "Деплой: Dockerfile, docker-compose, настройки, инструкция"

git push

```



\## 3. Настройте DNS

У регистратора домена добавьте запись типа A:

\- имя: `ads` (для `ads.himeet.online`)

\- значение: IP сервера

Подождите 5–30 минут, проверка: `ping ads.himeet.online`



\## 4. Подготовьте сервер

```bash

ssh root@IP\_СЕРВЕРА

```

Проверьте, что заняты порты 80 и 443 (если там уже работает nginx или Caddy, смотрите раздел 7):

```bash

ss -tlnp | grep -E ":80 |:443 "

```

Установите Docker, если его ещё нет:

```bash

docker --version || curl -fsSL https://get.docker.com | sh

```



\## 5. Скачайте проект и настройте

```bash

git clone https://github.com/ВАШ\_АККАУНТ/ВАШ\_РЕПОЗИТОРИЙ.git /opt/ads

cd /opt/ads

cp .env.example .env

nano .env

```

В `.env` проверьте `APP\_DOMAIN`, `CORS\_ORIGINS`, `MARKET`. Секретные ключи (ЮKassa, SMS, Stripe) вносите только здесь.

```bash

chmod 600 .env

```



\## 6. Запуск

```bash

docker compose up -d --build

docker compose logs --tail 50 ads

curl -I http://127.0.0.1:3100

```

Ответ `HTTP/1.1 200` (или 3xx) значит, что сайт запустился.



\## 7. HTTPS через Caddy (если порты 80 и 443 свободны)

```bash

apt install -y caddy

cat > /etc/caddy/Caddyfile <<'EOF'

ads.himeet.online {

&#x20;   reverse\_proxy 127.0.0.1:3100

}

EOF

systemctl reload caddy

```

Сертификат выпустится автоматически. Откройте https://ads.himeet.online.

Если на сервере уже есть nginx, добавьте в него сайт `ads.himeet.online` с `proxy\_pass http://127.0.0.1:3100;`.



\## 8. Обновление сайта

```bash

cd /opt/ads

git pull --ff-only

docker compose up -d --build

```

Данные в томе при этом не теряются.



\## 9. Резервная копия базы и фото

Имя тома смотрите так: `docker volume ls | grep ads\_data`

```bash

docker run --rm -v ads\_ads\_data:/data -v /root:/backup alpine tar czf /backup/ads-data.tgz -C /data .

```

Скачайте архив к себе: `scp root@IP\_СЕРВЕРА:/root/ads-data.tgz .`



\## 10. Полезные команды

\- Журнал: `docker compose logs -f ads`

\- Перезапуск: `docker compose restart ads`

\- Остановка: `docker compose down` (данные остаются в томе)

