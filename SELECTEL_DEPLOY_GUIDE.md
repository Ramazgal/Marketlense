# 🚀 АВТОМАТИЧЕСКИЙ ДЕПЛОЙ НА SELECTEL

**Сервер:** 185.91.53.49  
**Логин:** root  
**Пароль:** iiqvPqIEOzJy

---

## ⚡ БЫСТРЫЙ СТАРТ (5 команд)

### 1. Подключись к серверу

```powershell
ssh root@185.91.53.49
# Пароль: iiqvPqIEOzJy
```

### 2. Скачай скрипт автодеплоя

На сервере выполни:

```bash
# Создать временную папку
mkdir -p /tmp/marketlens-deploy
cd /tmp/marketlens-deploy

# Скачать скрипт (вариант 1 - если есть на GitHub)
# wget https://raw.githubusercontent.com/YOUR_USERNAME/marketlens/main/scripts/full-deploy-selectel.sh

# Или создать вручную (вариант 2)
cat > full-deploy-selectel.sh << 'EOF'
# Скопируй сюда содержимое full-deploy-selectel.sh
EOF

# Сделать исполняемым
chmod +x full-deploy-selectel.sh
```

### 3. Запусти автодеплой

```bash
./full-deploy-selectel.sh
```

**Скрипт автоматически:**
- ✅ Очистит старые файлы
- ✅ Установит Node.js 20.x
- ✅ Установит PM2, PostgreSQL, Nginx, Certbot
- ✅ Настроит файрвол
- ✅ Создаст пользователя marketlens
- ✅ Создаст директории для проекта

**Время:** ~5-10 минут

### 4. Загрузи код проекта

**С локальной машины (PowerShell):**

```powershell
# Вариант 1: Загрузить всё
scp -r C:\Marketlense\* root@185.91.53.49:/home/marketlens/marketlens/

# Вариант 2: Загрузить только нужное
scp C:\Marketlense\server.js root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\package.json root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\ecosystem.config.js root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\.env.production root@185.91.53.49:/home/marketlens/marketlens/.env
scp C:\Marketlense\index.html root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\manifest.json root@185.91.53.49:/home/marketlens/marketlens/
```

### 5. Настрой и запусти приложение

**На сервере:**

```bash
# Переключиться на пользователя marketlens
su - marketlens

# Перейти в папку проекта
cd ~/marketlens

# Установить зависимости
npm install --production

# Настроить .env
nano .env
# Добавь:
# GEMINI_API_KEY=твой_ключ_здесь
# CORS_ORIGIN=http://185.91.53.49
# Сохрани: Ctrl+O, Enter, Ctrl+X

# Запустить через PM2
pm2 start ecosystem.config.js --env production

# Настроить автозапуск
pm2 startup
# Скопируй и выполни команду, которую PM2 выведет
pm2 save

# Проверить статус
pm2 status
pm2 logs
```

### 6. Проверь работу

Открой в браузере:
```
http://185.91.53.49:3000
http://185.91.53.49:3000/health
```

Должен открыться MarketLens! 🎉

---

## 🔧 РУЧНОЙ СПОСОБ (если автоскрипт не работает)

### 1. Очистка сервера

```bash
ssh root@185.91.53.49

# Остановить процессы
pm2 stop all
pm2 delete all
pm2 kill
killall node

# Удалить старые файлы
rm -rf /home/marketlens/marketlens
rm -rf /var/www/marketlens
rm -rf /root/marketlens
rm -rf /home/marketlens/logs
rm -rf /home/marketlens/backups

# Проверить
ls -la /home/marketlens
```

### 2. Установка всего необходимого

```bash
# Обновить систему
apt update && apt upgrade -y

# Установить Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Проверить
node --version  # Должно быть v20.x.x
npm --version

# Установить PM2
npm install -g pm2

# Установить PostgreSQL
apt install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql

# Установить Nginx
apt install -y nginx
systemctl start nginx
systemctl enable nginx

# Установить Certbot
apt install -y certbot python3-certbot-nginx

# Настроить файрвол
apt install -y ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw enable
```

### 3. Создать пользователя

```bash
# Если не существует
adduser --disabled-password --gecos "" marketlens
usermod -aG sudo marketlens

# Создать директории
mkdir -p /home/marketlens/marketlens
mkdir -p /home/marketlens/logs
mkdir -p /home/marketlens/backups
chown -R marketlens:marketlens /home/marketlens
```

### 4. Далее как в пунктах 4-6 выше

---

## 🔥 НАСТРОЙКА NGINX + SSL (опционально)

### 1. Настроить Nginx

```bash
# Как root
nano /etc/nginx/sites-available/marketlens
```

Вставить:

```nginx
server {
    listen 80;
    server_name 185.91.53.49;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Активировать
ln -s /etc/nginx/sites-available/marketlens /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

Теперь доступно на `http://185.91.53.49` (без порта 3000)!

### 2. SSL (если есть домен)

```bash
# Если есть домен, например marketlens.ru
certbot --nginx -d marketlens.ru -d www.marketlens.ru
```

---

## 🐛 TROUBLESHOOTING

### Проблема: PM2 не запускается

```bash
pm2 logs --err
# Смотри ошибки

# Попробуй запустить вручную для отладки
cd /home/marketlens/marketlens
node server.js
```

### Проблема: Не хватает прав

```bash
# Проверить владельца
ls -la /home/marketlens/marketlens

# Исправить
chown -R marketlens:marketlens /home/marketlens/marketlens
```

### Проблема: Порт 3000 занят

```bash
# Найти процесс
lsof -i :3000

# Убить процесс
kill -9 PID
```

### Проблема: Не открывается в браузере

```bash
# Проверить файрвол
ufw status

# Проверить, слушает ли приложение
netstat -tlnp | grep 3000

# Проверить логи Nginx
tail -f /var/log/nginx/error.log
```

---

## ✅ ЧЕКЛИСТ

- [ ] Подключился к серверу
- [ ] Запустил автоскрипт или ручную установку
- [ ] Node.js 20.x установлен
- [ ] PM2 установлен
- [ ] Код загружен на сервер
- [ ] .env настроен (GEMINI_API_KEY)
- [ ] npm install выполнен
- [ ] PM2 запущен (pm2 start)
- [ ] PM2 автозапуск настроен (pm2 startup)
- [ ] Приложение отвечает на :3000/health
- [ ] (Опционально) Nginx настроен
- [ ] (Опционально) SSL получен

---

## 🎯 ГОТОВО!

После выполнения всех шагов:

**Приложение доступно:**
- Напрямую: `http://185.91.53.49:3000`
- Через Nginx: `http://185.91.53.49`
- Health Check: `http://185.91.53.49:3000/health`

**Управление:**
```bash
pm2 status          # Статус
pm2 logs            # Логи
pm2 restart all     # Перезапуск
pm2 monit           # Мониторинг
```

**Деплой обновлений:**
```bash
cd ~/marketlens
./scripts/deploy.sh
```

---

**🎉 ПОЗДРАВЛЯЮ! MarketLens задеплоен на Selectel!** 🚀
