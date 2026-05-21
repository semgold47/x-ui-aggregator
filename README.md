# x-ui-aggregator

Простой агрегатор подписок 3x-UI / Xray, который объединяет конфигурации и суммирует значения `upload`/`download` из заголовков `Subscription-Userinfo`.

> Работает на базе OpenResty + Lua и запускается в Docker-контейнере.

---

## 🚀 Что делает

- Запрашивает подписки с нескольких серверов 3x-UI
- Декодирует Base64-конфигурации
- Объединяет конфигурации в одну
- Суммирует `upload` и `download` из заголовков `Subscription-Userinfo`
- Возвращает итоговую подписку для клиента

---

## ✅ Требования

- Docker 20.10+
- Docker Compose 2.0+
- Один или несколько серверов с 3x-UI (или совместимой панелью)
- Одинаковый `subscription-id` для одного пользователя на всех серверах
- Включённая поддержка `Subscription-Userinfo` на каждом сервере 3x-UI

---

## 🛠 Установка и запуск

1. Клонируйте репозиторий:

```bash
git clone https://github.com/semgold47/x-ui-aggregator /opt/x-ui-aggregator
cd /opt/x-ui-aggregator
```

2. Скопируйте пример конфигурации:

```bash
cp .env.example .env
```

3. Отредактируйте `.env` согласно вашим параметрам.

```env
# Режим TLS: off (http) или on (https)
TLS_MODE=off

# Путь к SSL-сертификатам, если TLS_MODE=on
PATH_SSL_KEY=/etc/letsencrypt/live/your.domain

# Ваш домен или IP
SITE_HOST=your-server-ip

# Порт для агрегатора
SITE_PORT=1222

# Список серверов 3x-UI через пробел. В конце каждого URL обязателен слеш!
SERVERS=https://example.com/path/ https://example.com/path/

# Путь подписки в URL
SUB=sub
```

> Важно: `SERVERS` должен содержать доступные URL-адреса, а `subscription-id` должен быть одинаковым на всех серверах.

4. Запустите контейнер:

```bash
docker-compose up -d
```

Контейнер будет слушать порт, указанный в `SITE_PORT`.

---

## 🌐 Как использовать

Подстановочный URL для клиента:

```text
http://<SITE_HOST>:<SITE_PORT>/<SUB>/<ваш_subscription-id>
```

Пример:

```text
http://123.123.123.123:1222/sub/path
```

---

## 🔎 Проверка

Проверьте заголовок `Subscription-Userinfo` с помощью `curl`:

```bash
curl -v "http://123.123.123.123:1222/sub/path" 2>&1 | grep -i "subscription-userinfo"
```

Ожидаемый ответ:

```text
< Subscription-Userinfo: upload=187976030; download=3561853884; total=107374182400; expire=1735689600
```

- `upload` и `download` — суммируются с всех серверов
- `total` и `expire` берутся с первого сервера

Если заголовок отсутствует, проверьте логи контейнера:

```bash
docker logs x-ui-aggregator --tail 50
```

---

## 🧩 Настройки логики агрегации

Если нужно изменить алгоритм объединения данных, правьте `config_fetcher.lua`.

Текущая логика:

```lua
-- upload и download суммируются
-- total и expire берутся с первого сервера (idx == 1)
```

После правок перезапустите контейнер:

```bash
docker-compose restart
```

---

## 🔐 HTTPS (TLS)

Для работы через HTTPS:

- Получите сертификаты (например, Let's Encrypt)
- Установите:

```env
TLS_MODE=on
PATH_SSL_KEY=/путь/к/папке/с/сертификатами
SITE_HOST=ваш.домен
SITE_PORT=443
```

Убедитесь, что в папке находятся файлы `fullchain.pem` и `privkey.pem`.

Перезапустите контейнер:

```bash
docker-compose down && docker-compose up -d
```

---

## 🛠 Устранение неполадок

| Проблема | Причина | Что проверить |
|---|---|---|
| Нет серверов в переменной окружения | Не задана переменная `SERVERS` | Откройте `.env` и проверьте `SERVERS` |
| Заголовок `Subscription-Userinfo` отсутствует | Поддержка заголовка отключена на сервере | В панели 3x-UI включите `Subscription-Userinfo` |
| Ошибка `failed to decode base64` | Один из серверов вернул некорректный Base64 | Убедитесь, что все конечные точки возвращают корректную Base64-подписку |
| Конфигурации не объединяются | Разные `subscription-id` на серверах | Проверьте, что `subscription-id` одинаковый для всех серверов |

---

## 📁 Структура репозитория

```text
.env.example
Dockerfile
README.md
config_fetcher.lua
docker-compose.yml
nginx.conf.esh
```

---

## 📄 Лицензия

MIT. Свободно используйте, изменяйте и распространяйте.

---

## 💬 Обратная связь

Если есть вопросы или предложения, открывайте `Issue` в репозитории.

Спасибо за использование `x-ui-aggregator`! 😊"""