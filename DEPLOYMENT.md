# 🚀 DEPLOYMENT GUIDE: MarketLens на Selectel VPS

**Версия:** 6.0.0  
**Дата:** 9 октября 2025 г.  
**Для:** Ubuntu 22.04 LTS на Selectel Cloud

---

## 📋 Оглавление

1. [Подготовка VPS на Selectel](#1-подготовка-vps-на-selectel)
2. [Настройка сервера](#2-настройка-сервера)
3. [Установка Node.js и PostgreSQL](#3-установка-nodejs-и-postgresql)
4. [Деплой приложения](#4-деплой-приложения)
5. [Настройка SSL (Let's Encrypt)](#5-настройка-ssl-lets-encrypt)
6. [Настройка PM2 и автозапуска](#6-настройка-pm2-и-автозапуска)
7. [Мониторинг и логирование](#7-мониторинг-и-логирование)
8. [Бэкапы](#8-бэкапы)
9. [Обновление приложения](#9-обновление-приложения)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Подготовка VPS на Selectel

### 1.1 Заказ VPS

1. Перейдите на [Selectel Cloud](https://selectel.ru/services/cloud/)
2. Выберите конфигурацию:
   - **CPU:** 2 ядра (минимум)
   - **RAM:** 2 GB (рекомендуется 4 GB)
   - **Диск:** 20 GB SSD
   - **ОС:** Ubuntu 22.04 LTS
   - **Регион:** Москва (для лучшей скорости)

3. Получите:
   - IP адрес сервера
   - SSH доступ (ключ или пароль root)

### 1.2 Первое подключение

```bash
# С Windows (PowerShell)
ssh root@YOUR_SERVER_IP

# С Mac/Linux
ssh root@YOUR_SERVER_IP
```

**Важно:** Замените `YOUR_SERVER_IP` на реальный IP вашего сервера!

---

## 2. Настройка сервера

### 2.1 Обновление системы

```bash
# Обновить списки пакетов
apt update

# Установить обновления
apt upgrade -y

# Установить необходимые утилиты
apt install -y curl wget git build-essential ufw
```

### 2.2 Создание пользователя для приложения

```bash
# Создать пользователя
adduser marketlens

# Добавить в группу sudo
usermod -aG sudo marketlens

# Переключиться на нового пользователя
su - marketlens
```

### 2.3 Настройка файрвола (UFW)

```bash
# Выйти обратно в root
exit

# Разрешить SSH
ufw allow 22/tcp

# Разрешить HTTP и HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Разрешить порт приложения (опционально, если без Nginx)
ufw allow 3000/tcp

# Включить файрвол
ufw enable

# Проверить статус
ufw status
```

---

## 3. Установка Node.js и PostgreSQL

### 3.1 Установка Node.js 20.x (LTS)

```bash
# Добавить репозиторий NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Установить Node.js и npm
sudo apt install -y nodejs

# Проверить установку
node --version  # Должно быть v20.x.x
npm --version   # Должно быть v10.x.x
```

### 3.2 Установка PostgreSQL 15

```bash
# Установить PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Запустить сервис
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Проверить статус
sudo systemctl status postgresql
```

### 3.3 Настройка базы данных

```bash
# Войти в PostgreSQL
sudo -u postgres psql

# В консоли PostgreSQL выполнить:
```

```sql
-- Создать пользователя
CREATE USER marketlens_user WITH PASSWORD 'STRONG_PASSWORD_HERE';

-- Создать базу данных
CREATE DATABASE marketlens_db;

-- Выдать права
GRANT ALL PRIVILEGES ON DATABASE marketlens_db TO marketlens_user;

-- Выйти
\q
```

**⚠️ ВАЖНО:** Замените `STRONG_PASSWORD_HERE` на надёжный пароль!

### 3.4 Тестирование подключения

```bash
# Протестировать подключение
psql -U marketlens_user -d marketlens_db -h localhost

# Должны войти в консоль PostgreSQL
# Выйти: \q
```

---

## 4. Деплой приложения

### 4.1 Клонирование репозитория

```bash
# Переключиться на пользователя marketlens
sudo su - marketlens

# Перейти в домашнюю директорию
cd ~

# Клонировать репозиторий (или загрузить через FTP/SCP)
# Вариант 1: Если есть Git репозиторий
git clone https://github.com/YOUR_USERNAME/marketlens.git
cd marketlens

# Вариант 2: Загрузить с локальной машины через SCP
# На локальной машине (PowerShell):
# scp -r C:\Marketlense marketlens@YOUR_SERVER_IP:~/marketlens
```

### 4.2 Установка зависимостей

```bash
# Перейти в папку проекта
cd ~/marketlens

# Установить зависимости
npm install --production
```

### 4.3 Настройка переменных окружения

```bash
# Создать файл .env
nano .env
```

Вставьте следующее содержимое:

```env
# ========================================
# MarketLens Production Configuration
# ========================================

NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Gemini AI API
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
GEMINI_MODEL=gemini-1.5-flash

# PostgreSQL (пока используем JSON, закомментировать)
# DATABASE_URL=postgresql://marketlens_user:STRONG_PASSWORD_HERE@localhost:5432/marketlens_db

# CORS (укажите ваш домен)
CORS_ORIGIN=https://your-domain.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Таймауты
REQUEST_TIMEOUT_MS=10000

# Логирование
LOG_LEVEL=info
LOG_FILE_PATH=./logs
```

**⚠️ ВАЖНО:** 
- Замените `YOUR_GEMINI_API_KEY_HERE` на ваш ключ
- Замените `STRONG_PASSWORD_HERE` на пароль БД
- Замените `your-domain.com` на ваш домен

Сохранить: `Ctrl+O`, `Enter`, `Ctrl+X`

### 4.4 Создание папки для логов

```bash
mkdir -p ~/marketlens/logs
```

### 4.5 Тестовый запуск

```bash
# Запустить сервер вручную
node server.js

# Должно появиться:
# ✅ MarketLens Production Server запущен
```

Откройте в браузере: `http://YOUR_SERVER_IP:3000/health`

Должны увидеть JSON с status: "ok"

**Остановите сервер:** `Ctrl+C`

---

## 5. Настройка SSL (Let's Encrypt)

### 5.1 Регистрация домена

1. Купите домен (например, на [reg.ru](https://www.reg.ru/))
2. Настройте A-запись, указывающую на IP вашего сервера:
   ```
   A    @    YOUR_SERVER_IP
   A    www  YOUR_SERVER_IP
   ```
3. Дождитесь обновления DNS (5-30 минут)

### 5.2 Установка Nginx

```bash
# Установить Nginx
sudo apt install -y nginx

# Запустить
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 5.3 Настройка Nginx как reverse proxy

```bash
# Создать конфиг для сайта
sudo nano /etc/nginx/sites-available/marketlens
```

Вставьте:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com www.your-domain.com;

    # Для Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Proxy на Node.js приложение
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

**⚠️ ВАЖНО:** Замените `your-domain.com` на ваш домен!

```bash
# Создать симлинк
sudo ln -s /etc/nginx/sites-available/marketlens /etc/nginx/sites-enabled/

# Проверить конфиг
sudo nginx -t

# Перезапустить Nginx
sudo systemctl restart nginx
```

### 5.4 Установка Certbot и получение SSL

```bash
# Установить Certbot
sudo apt install -y certbot python3-certbot-nginx

# Получить SSL сертификат
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Ввести email для уведомлений
# Согласиться с Terms of Service (Y)
# Выбрать: Redirect HTTP to HTTPS (2)
```

Сертификат автоматически обновляется! Проверить:

```bash
sudo certbot renew --dry-run
```

---

## 6. Настройка PM2 и автозапуска

### 6.1 Установка PM2 глобально

```bash
sudo npm install -g pm2
```

### 6.2 Запуск приложения через PM2

```bash
# Перейти в папку проекта
cd ~/marketlens

# Запустить через PM2
pm2 start ecosystem.config.js --env production

# Проверить статус
pm2 status

# Посмотреть логи
pm2 logs
```

### 6.3 Настройка автозапуска при перезагрузке

```bash
# Сгенерировать startup скрипт
pm2 startup

# Скопируйте и выполните команду, которую PM2 выведет
# Например:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u marketlens --hp /home/marketlens

# Сохранить список процессов
pm2 save
```

### 6.4 Проверка автозапуска

```bash
# Перезагрузить сервер
sudo reboot

# После перезагрузки подключиться снова
ssh marketlens@YOUR_SERVER_IP

# Проверить, что приложение запущено
pm2 status

# Должен быть online
```

---

## 7. Мониторинг и логирование

### 7.1 PM2 мониторинг

```bash
# Реал-тайм мониторинг
pm2 monit

# Подробная информация
pm2 show marketlens-api

# Логи (последние 100 строк)
pm2 logs --lines 100

# Логи только ошибок
pm2 logs --err
```

### 7.2 Health Check

```bash
# Добавить в crontab проверку здоровья
crontab -e

# Добавить строку (проверка каждые 5 минут):
*/5 * * * * curl -f http://localhost:3000/health || pm2 restart marketlens-api
```

### 7.3 Мониторинг ресурсов

```bash
# Использование CPU и памяти
pm2 status

# Детальная информация о ресурсах
pm2 monit
```

### 7.4 Настройка ротации логов

```bash
# Установить модуль ротации логов
pm2 install pm2-logrotate

# Настроить (опционально)
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

---

## 8. Бэкапы

### 8.1 Создание скрипта резервного копирования

```bash
# Создать папку для бэкапов
mkdir -p ~/backups

# Создать скрипт
nano ~/backup.sh
```

Вставьте:

```bash
#!/bin/bash

# MarketLens Backup Script
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/home/marketlens/backups"
APP_DIR="/home/marketlens/marketlens"

# Создать папку с датой
mkdir -p "$BACKUP_DIR/$DATE"

# Бэкап данных мониторинга
if [ -f "$APP_DIR/monitoring_db.json" ]; then
    cp "$APP_DIR/monitoring_db.json" "$BACKUP_DIR/$DATE/"
    echo "✅ Бэкап monitoring_db.json создан"
fi

# Бэкап .env
cp "$APP_DIR/.env" "$BACKUP_DIR/$DATE/"

# Архивировать
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" -C "$BACKUP_DIR" "$DATE"
rm -rf "$BACKUP_DIR/$DATE"

# Удалить старые бэкапы (старше 30 дней)
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +30 -delete

echo "✅ Бэкап завершен: backup_$DATE.tar.gz"
```

```bash
# Сделать исполняемым
chmod +x ~/backup.sh

# Протестировать
~/backup.sh
```

### 8.2 Автоматические бэкапы (cron)

```bash
# Открыть crontab
crontab -e

# Добавить строку (бэкап каждый день в 3:00)
0 3 * * * /home/marketlens/backup.sh >> /home/marketlens/backup.log 2>&1
```

### 8.3 Восстановление из бэкапа

```bash
# Список бэкапов
ls -lh ~/backups/

# Распаковать бэкап
cd ~/backups
tar -xzf backup_2025-10-09_03-00-00.tar.gz

# Восстановить файл
cp 2025-10-09_03-00-00/monitoring_db.json ~/marketlens/

# Перезапустить приложение
pm2 restart marketlens-api
```

---

## 9. Обновление приложения

### 9.1 Создание deployment скрипта

```bash
# Создать скрипт
nano ~/deploy.sh
```

Вставьте:

```bash
#!/bin/bash

# MarketLens Deployment Script
APP_DIR="/home/marketlens/marketlens"

echo "🚀 Начинаем деплой MarketLens..."

# Перейти в папку приложения
cd "$APP_DIR" || exit 1

# Создать бэкап перед обновлением
echo "📦 Создаём бэкап..."
~/backup.sh

# Получить обновления (если используется Git)
# echo "⬇️ Получаем обновления..."
# git pull origin main

# Или загрузить новые файлы через SCP/FTP
# echo "⬇️ Загрузите новые файлы и нажмите Enter"
# read

# Установить новые зависимости
echo "📦 Устанавливаем зависимости..."
npm install --production

# Перезапустить приложение через PM2
echo "🔄 Перезапускаем приложение..."
pm2 reload ecosystem.config.js --env production

# Проверить статус
pm2 status

echo "✅ Деплой завершен!"
echo "📊 Проверьте логи: pm2 logs"
```

```bash
# Сделать исполняемым
chmod +x ~/deploy.sh
```

### 9.2 Процесс обновления

**С локальной машины (PowerShell):**

```powershell
# Загрузить обновлённые файлы на сервер
scp -r C:\Marketlense\server.js marketlens@YOUR_SERVER_IP:~/marketlens/
scp -r C:\Marketlense\package.json marketlens@YOUR_SERVER_IP:~/marketlens/
```

**На сервере:**

```bash
# Запустить deployment скрипт
~/deploy.sh
```

---

## 10. Troubleshooting

### 10.1 Приложение не запускается

```bash
# Проверить логи PM2
pm2 logs --err --lines 50

# Проверить статус
pm2 status

# Попробовать запустить вручную для диагностики
cd ~/marketlens
node server.js

# Проверить переменные окружения
cat .env

# Проверить права на файлы
ls -la ~/marketlens
```

### 10.2 Ошибки подключения к базе данных

```bash
# Проверить статус PostgreSQL
sudo systemctl status postgresql

# Проверить подключение
psql -U marketlens_user -d marketlens_db -h localhost

# Проверить логи PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

### 10.3 Проблемы с SSL

```bash
# Проверить сертификаты
sudo certbot certificates

# Обновить сертификаты вручную
sudo certbot renew

# Проверить конфиг Nginx
sudo nginx -t

# Перезапустить Nginx
sudo systemctl restart nginx
```

### 10.4 High CPU или Memory Usage

```bash
# Проверить ресурсы
pm2 monit

# Перезапустить приложение
pm2 reload marketlens-api

# Если не помогает - полный рестарт
pm2 restart marketlens-api
```

### 10.5 Rate Limiting срабатывает слишком часто

Отредактируйте `.env`:

```env
RATE_LIMIT_WINDOW_MS=900000  # Увеличить окно
RATE_LIMIT_MAX_REQUESTS=200  # Увеличить лимит
```

Перезапустите:

```bash
pm2 reload marketlens-api
```

---

## 📊 Полезные команды

### PM2

```bash
pm2 start ecosystem.config.js --env production  # Запуск
pm2 stop marketlens-api                          # Остановка
pm2 restart marketlens-api                       # Перезапуск
pm2 reload marketlens-api                        # Reload без даунтайма
pm2 delete marketlens-api                        # Удалить из PM2
pm2 logs                                         # Логи
pm2 monit                                        # Мониторинг
pm2 save                                         # Сохранить список процессов
```

### Nginx

```bash
sudo systemctl start nginx      # Запуск
sudo systemctl stop nginx       # Остановка
sudo systemctl restart nginx    # Перезапуск
sudo systemctl reload nginx     # Перезагрузка конфига
sudo nginx -t                   # Проверка конфига
```

### PostgreSQL

```bash
sudo systemctl start postgresql   # Запуск
sudo systemctl stop postgresql    # Остановка
sudo systemctl restart postgresql # Перезапуск
sudo -u postgres psql             # Консоль PostgreSQL
```

### Файрвол

```bash
sudo ufw status            # Статус
sudo ufw allow 80/tcp      # Разрешить порт
sudo ufw deny 80/tcp       # Заблокировать порт
sudo ufw enable            # Включить
sudo ufw disable           # Выключить
```

---

## ✅ Чеклист готовности к продакшну

- [ ] VPS создан и настроен
- [ ] Node.js 20.x установлен
- [ ] PostgreSQL установлен и настроен
- [ ] Приложение развёрнуто
- [ ] .env файл настроен (GEMINI_API_KEY, CORS_ORIGIN)
- [ ] PM2 настроен и добавлен в автозапуск
- [ ] Nginx установлен и настроен
- [ ] SSL сертификат получен (Let's Encrypt)
- [ ] Файрвол (UFW) настроен
- [ ] Health check работает
- [ ] Логи пишутся и ротируются
- [ ] Бэкапы настроены (cron)
- [ ] Deployment скрипт создан
- [ ] Приложение доступно по HTTPS
- [ ] Rate limiting работает
- [ ] Мониторинг настроен

---

## 🎯 Что дальше?

После успешного деплоя:

1. **Мониторинг:** Настройте [UptimeRobot](https://uptimerobot.com/) для проверки доступности
2. **Аналитика:** Добавьте логирование запросов для аналитики
3. **PostgreSQL:** Мигрируйте с JSON на PostgreSQL для масштабирования
4. **CDN:** Добавьте Cloudflare для ускорения и защиты от DDoS
5. **CI/CD:** Настройте GitHub Actions для автоматического деплоя

---

**Документация подготовлена для:** MarketLens v6.0 Production  
**Автор:** GitHub Copilot  
**Дата:** 9 октября 2025 г.

**Поддержка:** Если возникли проблемы, проверьте раздел [Troubleshooting](#10-troubleshooting)
