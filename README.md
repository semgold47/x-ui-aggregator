# 📋 x-ui-aggregator

Простой агрегатор подписок 3x-UI / Xray, который объединяет **несколько серверов 3x-ui** в одну общую подписку.  
Умеет **суммировать трафик** (upload/download) со всех серверов, а лимит (total) и дату истечения (expire) брать с **первого сервера** в списке.  
Заголовок `Subscription-Userinfo` корректно передаётся клиенту.

> Работает на базе OpenResty + Luaб запускается в Docker-контейнере.

---

## 🚀 Что делает

- Запрашивает подписки с нескольких серверов 3x-UI
- Объединяет конфигурации в одну
- Суммирует `upload` и `download` из заголовков `Subscription-Userinfo` чтобы в верху в приложении видеть расход трафика и дату окончания подписки 
- Возвращает итоговую подписку для клиента

---

## ✅ Требования

- Docker 20.10+
- Docker Compose 2.0+
- Один или несколько серверов с 3x-UI (или совместимой панелью)
- Одинаковый `subscription-id` для одного пользователя на всех серверах

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
SITE_PORT=443

# Список серверов 3x-UI через пробел. В конце каждого URL обязателен слеш!
SERVERS="https://example1.com/path/ https://example2.com/path/ https://example3.com/path/"

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

Подстановочный URL для клиента (доступен через HTTPS, порт 443):

https://<SITE_HOST>/<SUB>/<subscription-id>

Пример:

https://example.com/sub/subscription-id

> Примечание: Порт 1222 используется только для внутреннего проброса на Docker-хосте. Для внешних клиентов подключение происходит через стандартный HTTPS-порт (443), поэтому порт в URL указывать не нужно.

## 🔎 Проверка

Проверьте заголовок Subscription-Userinfo с помощью curl:

curl -v "https://example.com/sub/subscription-id" 2>&1 | grep -i "subscription-userinfo"

Ожидаемый вывод (значения могут отличаться):

< subscription-userinfo: upload=187976030; download=3561853884; total=107374182400; expire=1735689600

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
## 🔗 Исходный проект
Основано на apa4h/nginx-3x-ui-subscription-proxy

---

## 📄 Лицензия

MIT. Свободно используйте, изменяйте и распространяйте.

---

## 💬 Обратная связь

Если есть вопросы или предложения, открывайте `Issue` в репозитории.

Спасибо за использование `x-ui-aggregator`! 😊
