# ✅ ВСЁ ГОТОВО, БРАТ! Деплой на Selectel автоматизирован!

**Дата:** 10 октября 2025 г.  
**Сервер:** 185.91.53.49  
**Статус:** 🚀 **ГОТОВ К ЗАПУСКУ!**

---

## 🎯 ЧТО СДЕЛАНО

### 1. **Автоматический скрипт деплоя** ✅

**Файл:** `scripts/full-deploy-selectel.sh`

Автоматически на сервере:
- Очищает старые файлы
- Устанавливает Node.js 20.x
- Устанавливает PM2, PostgreSQL, Nginx, Certbot
- Настраивает файрвол UFW
- Создаёт пользователя marketlens
- Создаёт директории проекта

**Время выполнения:** 5-10 минут

---

### 2. **PowerShell скрипт загрузки** ✅

**Файл:** `upload-to-selectel.ps1`

Автоматически с твоего компьютера:
- Загружает все файлы на сервер через SCP
- Настраивает права доступа
- Готовит к запуску

**Время выполнения:** 2-3 минуты

---

### 3. **Документация** ✅

Создано 3 новых гайда:

1. **START_HERE.md** — начни с этого файла!
   - Автоматический вариант (рекомендуется)
   - Ручной вариант (если что-то не работает)
   - Troubleshooting
   - Чеклист

2. **SELECTEL_DEPLOY_GUIDE.md** — подробная инструкция
   - Автоскрипт и ручная установка
   - Настройка Nginx + SSL
   - Полезные команды
   - Решение проблем

3. **UPLOAD_COMMANDS.txt** — команды для копирования
   - Все SCP команды в одном месте
   - Можно копировать и выполнять

---

### 4. **Обновлённые файлы** ✅

**Изменено:**
- `package.json` — версия 6.0.0
- `README.md` — добавлен раздел Production
- `server.js` — Helmet, Rate Limiting, Health Check
- `ecosystem.config.js` — PM2 кластер

**Создано:**
- `scripts/full-deploy-selectel.sh` — автодеплой сервера
- `upload-to-selectel.ps1` — автозагрузка файлов
- `START_HERE.md` — главная инструкция
- `SELECTEL_DEPLOY_GUIDE.md` — детальный гайд
- `UPLOAD_COMMANDS.txt` — команды для копирования
- `.env.production` — шаблон конфигурации

---

## 🚀 КАК ЗАПУСТИТЬ (3 ШАГА)

### Шаг 1: Запусти PowerShell скрипт

**На твоем компьютере (PowerShell):**

```powershell
cd C:\Marketlense
.\upload-to-selectel.ps1
```

Скрипт загрузит все файлы на сервер.

---

### Шаг 2: Подключись к серверу и запусти автодеплой

```powershell
ssh root@185.91.53.49
# Пароль: iiqvPqIEOzJy
```

**На сервере:**

```bash
# Запустить автодеплой
/root/full-deploy-selectel.sh
```

Ждём 5-10 минут пока установится всё необходимое.

---

### Шаг 3: Запусти приложение

**На сервере (после автодеплоя):**

```bash
# Переключиться на пользователя marketlens
su - marketlens

# Перейти в папку проекта
cd ~/marketlens

# Установить зависимости
npm install --production

# Настроить .env
nano .env
# Измени: GEMINI_API_KEY=твой_ключ_здесь
# Сохрани: Ctrl+O, Enter, Ctrl+X

# Запустить через PM2
pm2 start ecosystem.config.js --env production

# Настроить автозапуск
pm2 startup
# Скопируй команду, которую выдаст PM2, и выполни её (выйдя в root)
pm2 save
```

---

### Проверь в браузере:

- **http://185.91.53.49:3000** — главная страница
- **http://185.91.53.49:3000/health** — health check

**Должен увидеть MarketLens! 🎉**

---

## 📋 ФАЙЛЫ ДЛЯ ДЕПЛОЯ

### Главные документы:

1. **START_HERE.md** ⭐ — НАЧНИ С ЭТОГО!
2. **SELECTEL_DEPLOY_GUIDE.md** — подробный гайд
3. **DEPLOYMENT.md** — полная документация (10 глав)
4. **PRODUCTION.md** — краткий обзор

### Скрипты:

1. **upload-to-selectel.ps1** — загрузка на сервер (Windows)
2. **scripts/full-deploy-selectel.sh** — автодеплой на сервере (Linux)
3. **scripts/deploy.sh** — деплой обновлений
4. **scripts/backup.sh** — создание бэкапов
5. **scripts/restore.sh** — восстановление

### Конфиги:

1. **.env.production** — шаблон конфигурации
2. **ecosystem.config.js** — PM2 конфигурация
3. **UPLOAD_COMMANDS.txt** — команды для копирования

---

## 🎯 КОМАНДЫ ДЛЯ БЫСТРОГО СТАРТА

### Вариант 1: Автоматический (Рекомендуется)

```powershell
# 1. На твоем компьютере
cd C:\Marketlense
.\upload-to-selectel.ps1

# 2. Подключись к серверу
ssh root@185.91.53.49

# 3. На сервере - запусти автодеплой
/root/full-deploy-selectel.sh

# 4. Переключись на marketlens
su - marketlens

# 5. Установи и запусти
cd ~/marketlens
npm install --production
nano .env  # Добавь GEMINI_API_KEY
pm2 start ecosystem.config.js --env production
pm2 startup
pm2 save
```

### Вариант 2: Только команды SCP (если скрипт не работает)

```powershell
# Загрузить скрипт автодеплоя
scp C:\Marketlense\scripts\full-deploy-selectel.sh root@185.91.53.49:/root/

# Загрузить файлы проекта
scp C:\Marketlense\server.js root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\package.json root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\ecosystem.config.js root@185.91.53.49:/home/marketlens/marketlens/
scp C:\Marketlense\.env.production root@185.91.53.49:/home/marketlens/marketlens/.env
scp C:\Marketlense\index.html root@185.91.53.49:/home/marketlens/marketlens/

# Подключиться и настроить
ssh root@185.91.53.49
chmod +x /root/full-deploy-selectel.sh
/root/full-deploy-selectel.sh
```

---

## ✅ ЧЕКЛИСТ

**Подготовка (локально):**
- [ ] Открыл START_HERE.md
- [ ] Запустил upload-to-selectel.ps1
- [ ] Файлы загружены на сервер

**На сервере:**
- [ ] Подключился по SSH (ssh root@185.91.53.49)
- [ ] Запустил автодеплой (/root/full-deploy-selectel.sh)
- [ ] Node.js 20.x установлен
- [ ] PM2 установлен
- [ ] PostgreSQL установлен
- [ ] Nginx установлен
- [ ] Файрвол настроен

**Запуск приложения:**
- [ ] Переключился на marketlens (su - marketlens)
- [ ] npm install выполнен
- [ ] .env настроен (GEMINI_API_KEY)
- [ ] PM2 запущен (pm2 start)
- [ ] PM2 автозапуск (pm2 startup + save)
- [ ] Приложение работает (http://185.91.53.49:3000)
- [ ] Health check OK (http://185.91.53.49:3000/health)

---

## 📊 ВРЕМЯ ДЕПЛОЯ

| Этап | Время |
|------|-------|
| Загрузка файлов (upload-to-selectel.ps1) | 2-3 мин |
| Автодеплой сервера (full-deploy-selectel.sh) | 5-10 мин |
| Установка зависимостей (npm install) | 2-3 мин |
| Настройка .env | 1 мин |
| Запуск PM2 | 1 мин |
| **ИТОГО** | **~15-20 минут** |

---

## 🔥 ПОСЛЕ ДЕПЛОЯ

### Проверь работу:

```bash
# Статус PM2
pm2 status

# Логи
pm2 logs

# Мониторинг
pm2 monit

# Health Check
curl http://localhost:3000/health
```

### Настрой Nginx (опционально):

```bash
# Создать конфиг
nano /etc/nginx/sites-available/marketlens

# Активировать
ln -s /etc/nginx/sites-available/marketlens /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

Теперь доступно без порта: **http://185.91.53.49**

---

## 🎉 ГОТОВО!

**У тебя теперь:**
- ✅ Работающий MarketLens на Selectel
- ✅ Автоматические скрипты для деплоя
- ✅ PM2 с автоперезапуском
- ✅ Логи и мониторинг
- ✅ Бэкапы (scripts/backup.sh)
- ✅ Production security (Helmet + Rate Limiting)

---

## 📞 НУЖНА ПОМОЩЬ?

**Читай:**
1. **START_HERE.md** — главная инструкция
2. **SELECTEL_DEPLOY_GUIDE.md** — детальный гайд
3. **DEPLOYMENT.md** — полная документация

**Проблемы?**
- Смотри раздел Troubleshooting в START_HERE.md
- Проверь логи: `pm2 logs --err`
- Запусти вручную: `node server.js`

---

**🚀 ЗАПУСКАЙ upload-to-selectel.ps1 И ВПЕРЁД!** 🎉

**Всё автоматизировано, просто следуй START_HERE.md!**

---

**Документы подготовил:** GitHub Copilot  
**Дата:** 10 октября 2025 г.  
**Версия:** MarketLens v6.0 Production Ready  
**Сервер:** Selectel VPS (185.91.53.49)

💪 **ВСЁ СДЕЛАНО ЗА ТЕБЯ, БРАТ! ПРОСТО ЗАПУСКАЙ!** 🔥
