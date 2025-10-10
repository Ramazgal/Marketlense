# ⚡ БЫСТРЫЕ КОМАНДЫ - GitHub Pages + Selectel

## 🎯 Что нужно сделать

1. **Фронтенд → GitHub Pages** (бесплатно, HTTPS)
2. **Бэкенд → Selectel VPS** (185.91.53.49:3000)

---

## 📦 ЧАСТЬ 1: GitHub Pages (5 команд)

### В PowerShell (C:\Marketlense):

```powershell
# 1. Инициализация
git init
git add .
git commit -m "Initial commit: MarketLens v6.0.0"
git branch -M main

# 2. Подключение (ЗАМЕНИ твой-username!)
git remote add origin https://github.com/твой-username/marketlens.git

# 3. Push на GitHub
git push -u origin main
```

**Потом на GitHub:**
- Settings → Pages → Branch: `main` → Folder: `/docs` → Save
- Через 3 минуты: `https://твой-username.github.io/marketlens/`

---

## 🖥️ ЧАСТЬ 2: Selectel VPS (3 шага)

### 1. Загрузка файлов (PowerShell):

```powershell
.\upload-to-selectel.ps1
```

### 2. SSH и автодеплой:

```bash
ssh root@185.91.53.49
# Пароль: iiqvPqIEOzJy

/root/full-deploy-selectel.sh
```

### 3. Запуск приложения:

```bash
su - marketlens
cd ~/marketlens
npm install --production
nano .env  # Добавь GEMINI_API_KEY и FRONTEND_URL
pm2 start ecosystem.config.js --env production
pm2 startup
pm2 save
```

---

## 🔗 ЧАСТЬ 3: Связать фронт и бэк

### На сервере (SSH):

```bash
su - marketlens
cd ~/marketlens
nano .env
```

**Добавь строку:**
```
FRONTEND_URL=https://твой-username.github.io
```

**Перезапусти:**
```bash
pm2 restart marketlens
```

---

## ✅ Проверка

1. **Фронтенд:** `https://твой-username.github.io/marketlens/`
2. **Бэкенд:** `http://185.91.53.49:3000/health`
3. **API работает:** Открой фронтенд → DevTools (F12) → Console → не должно быть CORS ошибок

---

## 📝 Файлы готовы

- ✅ `docs/index.html` — фронтенд для GitHub Pages
- ✅ `docs/manifest.json` — PWA манифест
- ✅ `.gitignore` — настроен (не загрузится node_modules, .env)
- ✅ API_BASE_URL автоматически:
  - github.io → 185.91.53.49:3000
  - localhost → localhost:3000

---

## 🚨 Если что-то не работает

### CORS ошибка в браузере?
```bash
# На сервере
nano ~/.marketlens/marketlens/.env
# Добавь: FRONTEND_URL=https://твой-username.github.io
pm2 restart marketlens
```

### 404 на GitHub Pages?
- Проверь: Settings → Pages → Folder должен быть `/docs`
- Подожди 3 минуты после push

### Git требует пароль?
Используй **Personal Access Token** (не обычный пароль):
- GitHub → Settings → Developer settings → Personal access tokens
- Generate new token → `repo` → Скопируй токен
- Используй вместо пароля

---

## 📚 Подробные инструкции

- **GitHub:** [GITHUB_SETUP.md](./GITHUB_SETUP.md)
- **Git команды:** [GIT_COMMANDS.txt](./GIT_COMMANDS.txt)
- **Selectel:** [START_HERE.md](./START_HERE.md)
- **Production:** [PRODUCTION.md](./PRODUCTION.md)

---

**Время:** ~20 минут от начала до рабочего сайта 🚀

**Создано:** GitHub Copilot  
**Проект:** MarketLens v6.0.0
