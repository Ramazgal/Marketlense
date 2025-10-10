# 🚀 MarketLens Production - Быстрый старт

Краткая инструкция по деплою MarketLens на боевой сервер.

---

## ⚡ Для нетерпеливых

**1. Подготовка VPS:**
```bash
# Создайте VPS на Selectel (Ubuntu 22.04, 2CPU, 2GB RAM)
ssh root@YOUR_SERVER_IP

# Установите всё необходимое
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update && sudo apt install -y nodejs postgresql nginx certbot python3-certbot-nginx ufw git
sudo npm install -g pm2
```

**2. Настройка PostgreSQL:**
```bash
sudo -u postgres psql
```
```sql
CREATE USER marketlens_user WITH PASSWORD 'ВАШ_ПАРОЛЬ';
CREATE DATABASE marketlens_db;
GRANT ALL PRIVILEGES ON DATABASE marketlens_db TO marketlens_user;
\q
```

**3. Деплой приложения:**
```bash
# Создать пользователя
sudo adduser marketlens
sudo usermod -aG sudo marketlens
su - marketlens

# Загрузить код (SCP с вашей машины):
# scp -r C:\Marketlense marketlens@YOUR_SERVER_IP:~/marketlens

# Перейти в папку
cd ~/marketlens

# Установить зависимости
npm install --production

# Настроить .env (скопировать из .env.production и заполнить)
nano .env

# Запустить через PM2
pm2 start ecosystem.config.js --env production
pm2 startup
pm2 save
```

**4. Настроить Nginx + SSL:**
```bash
# Nginx конфиг
sudo nano /etc/nginx/sites-available/marketlens
```
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```
```bash
sudo ln -s /etc/nginx/sites-available/marketlens /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# SSL
sudo certbot --nginx -d your-domain.com
```

**5. Файрвол:**
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

**Готово! 🎉** Проверьте: `https://your-domain.com/health`

---

## 📚 Полная документация

Подробная инструкция: **[DEPLOYMENT.md](./DEPLOYMENT.md)**

---

## 🛠️ Полезные команды

### PM2
```bash
pm2 status                 # Статус
pm2 logs                   # Логи
pm2 monit                  # Мониторинг
pm2 restart marketlens-api # Перезапуск
```

### Деплой обновлений
```bash
cd ~/marketlens
./scripts/deploy.sh        # Автоматический деплой
```

### Бэкапы
```bash
./scripts/backup.sh        # Создать бэкап
./scripts/restore.sh       # Восстановить из бэкапа
```

### Логи
```bash
pm2 logs --lines 100       # Последние 100 строк
pm2 logs --err             # Только ошибки
tail -f logs/pm2-error.log # Лог-файл ошибок
```

---

## ⚙️ Переменные окружения (.env)

Обязательные:
```env
NODE_ENV=production
GEMINI_API_KEY=ваш_ключ
CORS_ORIGIN=https://your-domain.com
```

Опциональные:
```env
PORT=3000
RATE_LIMIT_MAX_REQUESTS=100
REQUEST_TIMEOUT_MS=10000
```

---

## 🔐 Безопасность

✅ **Включено:**
- Helmet.js (HTTP headers)
- Rate Limiting (100 req/15 min)
- CORS фильтрация
- SSL/HTTPS через Let's Encrypt
- Файрвол (UFW)

⚠️ **Рекомендации:**
- Смените дефолтные пароли PostgreSQL
- Используйте крепкий GEMINI_API_KEY
- Регулярно обновляйте зависимости: `npm audit fix`
- Настройте автоматические бэкапы

---

## 📊 Мониторинг

**Health Check:**
```bash
curl https://your-domain.com/health
```

**Ожидаемый ответ:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-09T...",
  "uptime": 12345,
  "checks": {
    "ai": "ok",
    "database": { "status": "ok", "size": "15.32 KB" },
    "memory": { "status": "ok", "heapUsed": "45.12 MB" }
  }
}
```

**PM2 Monitoring:**
```bash
pm2 monit                  # Реал-тайм
pm2 install pm2-logrotate  # Ротация логов
```

---

## 🐛 Troubleshooting

**Приложение не запускается:**
```bash
pm2 logs --err --lines 50  # Проверить ошибки
node server.js             # Запустить вручную для отладки
```

**Ошибки SSL:**
```bash
sudo certbot renew         # Обновить сертификат
sudo nginx -t              # Проверить конфиг Nginx
```

**Высокое потребление ресурсов:**
```bash
pm2 reload marketlens-api  # Reload без даунтайма
```

Полное руководство: [DEPLOYMENT.md - Troubleshooting](./DEPLOYMENT.md#10-troubleshooting)

---

## 🎯 Чеклист готовности

- [ ] VPS создан и настроен
- [ ] Node.js 20.x установлен
- [ ] PostgreSQL настроен
- [ ] .env заполнен (GEMINI_API_KEY)
- [ ] PM2 запущен и добавлен в автозапуск
- [ ] Nginx настроен
- [ ] SSL получен (Let's Encrypt)
- [ ] Файрвол включен
- [ ] Health check работает (`/health`)
- [ ] Бэкапы настроены
- [ ] Домен указывает на сервер

---

## 📞 Поддержка

**Документы:**
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Полная инструкция по деплою
- [README.md](./README.md) - Основная документация проекта
- [TEST_5.1_PERSISTENT_STORAGE.md](./TEST_5.1_PERSISTENT_STORAGE.md) - Работа с данными

**Полезные ссылки:**
- [Selectel Cloud](https://selectel.ru/services/cloud/)
- [Let's Encrypt](https://letsencrypt.org/)
- [PM2 Documentation](https://pm2.keymetrics.io/)
- [Nginx Documentation](https://nginx.org/ru/docs/)

---

**MarketLens v6.0 - Production Ready** 🚀
