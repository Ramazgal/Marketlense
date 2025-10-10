# 🚀 ГОТОВО! Запускай деплой на Selectel!

**Сервер:** 185.91.53.49  
**Логин:** root  
**Пароль:** iiqvPqIEOzJy

---

## ⚡ ВАРИАНТ 1: АВТОМАТИЧЕСКИЙ (Рекомендуется)

### Шаг 1: Запусти PowerShell скрипт (на твоем компьютере)

```powershell
cd C:\Marketlense
.\upload-to-selectel.ps1
```

**Скрипт автоматически:**
- ✅ Загрузит все файлы на сервер
- ✅ Настроит права доступа
- ✅ Подготовит к запуску

**Время:** 2-3 минуты

### Шаг 2: Подключись к серверу

```powershell
ssh root@185.91.53.49
# Пароль: iiqvPqIEOzJy
```

### Шаг 3: Запусти автодеплой (на сервере)

```bash
/root/full-deploy-selectel.sh
```

**Скрипт установит:**
- ✅ Node.js 20.x
- ✅ PM2
- ✅ PostgreSQL
- ✅ Nginx
- ✅ Certbot
- ✅ Настроит файрвол

**Время:** 5-10 минут

### Шаг 4: Запусти приложение (на сервере)

```bash
# Переключиться на пользователя marketlens
su - marketlens

# Перейти в папку проекта
cd ~/marketlens

# Установить зависимости
npm install --production

# Настроить .env
nano .env
# Измени GEMINI_API_KEY=твой_ключ_здесь
# Сохрани: Ctrl+O, Enter, Ctrl+X

# Запустить через PM2
pm2 start ecosystem.config.js --env production

# Настроить автозапуск
pm2 startup
# Скопируй команду, которую PM2 выведет, и выполни её (выйдя из marketlens в root)
pm2 save

# Проверить статус
pm2 status
```

### Шаг 5: Проверь в браузере

Открой:
- **http://185.91.53.49:3000** — главная страница
- **http://185.91.53.49:3000/health** — проверка здоровья

**Должен увидеть:**
```json
{
  "status": "ok",
  "version": "6.0.0",
  "checks": {
    "ai": "ok",
    "database": {"status": "ok"},
    "memory": {"status": "ok"}
  }
}
```

---

## ⚡ ВАРИАНТ 2: РУЧНОЙ (если автоматический не работает)

### 1. Загрузи файлы на сервер

**На твоем компьютере (PowerShell):**

```powershell
# Загрузить скрипт автодеплоя
scp C:\Marketlense\scripts\full-deploy-selectel.sh root@185.91.53.49:/root/

# Загрузить код проекта
scp C:\Marketlense\server.js root@185.91.53.49:/tmp/
scp C:\Marketlense\package.json root@185.91.53.49:/tmp/
scp C:\Marketlense\ecosystem.config.js root@185.91.53.49:/tmp/
scp C:\Marketlense\.env.production root@185.91.53.49:/tmp/.env
scp C:\Marketlense\index.html root@185.91.53.49:/tmp/
```

### 2. Подключись и запусти автодеплой

```powershell
ssh root@185.91.53.49
# Пароль: iiqvPqIEOzJy
```

**На сервере:**

```bash
# Сделать скрипт исполняемым
chmod +x /root/full-deploy-selectel.sh

# Запустить
/root/full-deploy-selectel.sh

# Переместить файлы в нужное место
mv /tmp/server.js /home/marketlens/marketlens/
mv /tmp/package.json /home/marketlens/marketlens/
mv /tmp/ecosystem.config.js /home/marketlens/marketlens/
mv /tmp/.env /home/marketlens/marketlens/
mv /tmp/index.html /home/marketlens/marketlens/

# Установить права
chown -R marketlens:marketlens /home/marketlens/marketlens
```

### 3. Далее как в Варианте 1, Шаг 4

---

## 🔥 НАСТРОЙКА NGINX (опционально, для доступа без порта)

**Как root на сервере:**

```bash
# Создать конфиг Nginx
cat > /etc/nginx/sites-available/marketlens << 'EOF'
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
EOF

# Активировать
ln -s /etc/nginx/sites-available/marketlens /etc/nginx/sites-enabled/

# Проверить конфиг
nginx -t

# Перезапустить Nginx
systemctl restart nginx
```

**Теперь доступно без порта:** http://185.91.53.49

---

## 📊 ПОЛЕЗНЫЕ КОМАНДЫ

### Управление приложением

```bash
pm2 status           # Статус
pm2 logs             # Логи (все)
pm2 logs --err       # Только ошибки
pm2 restart all      # Перезапуск
pm2 stop all         # Остановка
pm2 monit            # Мониторинг в реальном времени
```

### Обновление приложения

```bash
cd /home/marketlens/marketlens
./scripts/deploy.sh  # Автоматический деплой обновлений
```

### Бэкапы

```bash
./scripts/backup.sh   # Создать бэкап
./scripts/restore.sh  # Восстановить из бэкапа
```

### Проверка здоровья

```bash
# На сервере
curl http://localhost:3000/health

# С локальной машины
curl http://185.91.53.49:3000/health
```

---

## 🐛 TROUBLESHOOTING

### Проблема: Не могу подключиться по SSH

```powershell
# Проверь, доступен ли сервер
ping 185.91.53.49

# Попробуй с verbose
ssh -v root@185.91.53.49
```

### Проблема: Ошибка при загрузке файлов (SCP)

```powershell
# Проверь, что SSH работает
ssh root@185.91.53.49 "ls -la"

# Попробуй загрузить один файл для теста
scp C:\Marketlense\README.md root@185.91.53.49:/tmp/
```

### Проблема: npm install не работает

```bash
# Проверить версию Node.js
node --version  # Должно быть v20.x.x

# Если нет, переустановить
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
```

### Проблема: PM2 не запускается

```bash
# Проверить логи
pm2 logs --err

# Попробовать запустить вручную
cd /home/marketlens/marketlens
node server.js

# Проверить .env
cat .env
```

### Проблема: Порт 3000 занят

```bash
# Найти процесс
lsof -i :3000

# Убить процесс
kill -9 PID_ПРОЦЕССА
```

### Проблема: Приложение не открывается в браузере

```bash
# Проверить файрвол
ufw status

# Проверить, слушает ли приложение
netstat -tlnp | grep 3000

# Проверить логи PM2
pm2 logs
```

---

## ✅ ЧЕКЛИСТ

- [ ] PowerShell скрипт запущен (upload-to-selectel.ps1)
- [ ] Подключился к серверу по SSH
- [ ] Автодеплой скрипт выполнен (/root/full-deploy-selectel.sh)
- [ ] Node.js 20.x установлен (node --version)
- [ ] Файлы проекта на месте (ls /home/marketlens/marketlens)
- [ ] .env настроен (GEMINI_API_KEY добавлен)
- [ ] npm install выполнен
- [ ] PM2 запущен (pm2 status показывает online)
- [ ] PM2 автозапуск настроен (pm2 startup + pm2 save)
- [ ] Приложение отвечает: http://185.91.53.49:3000/health
- [ ] (Опционально) Nginx настроен
- [ ] (Опционально) Домен настроен + SSL

---

## 🎉 ГОТОВО!

После всех шагов у тебя будет:

✅ **Работающий MarketLens на Selectel**  
✅ **Доступен по адресу:** http://185.91.53.49:3000  
✅ **Автоматический перезапуск** (PM2)  
✅ **Логи и мониторинг** (PM2 + Pino)  
✅ **Бэкапы** (scripts/backup.sh)  

---

## 📞 НУЖНА ПОМОЩЬ?

**Документация:**
- **SELECTEL_DEPLOY_GUIDE.md** — подробный гайд
- **DEPLOYMENT.md** — полная документация (10 глав)
- **PRODUCTION.md** — краткий обзор

**Команды:**
```bash
pm2 logs        # Смотри логи
pm2 monit       # Мониторинг
pm2 restart all # Перезапуск
```

---

**🚀 ЗАПУСКАЙ И ПРОВЕРЯЙ! Всё готово для деплоя!** 🎉
