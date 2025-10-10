# 🚀 GitHub Pages Setup для MarketLens

## 📋 Что нужно сделать

GitHub Pages позволит разместить фронтенд MarketLens бесплатно на `https://твой-username.github.io/marketlens/`

Бэкенд будет работать на Selectel сервере (185.91.53.49:3000), а фронтенд — на GitHub Pages.

---

## ⚡ БЫСТРЫЙ СТАРТ (5 шагов)

### 1. Создай репозиторий на GitHub

1. Зайди на https://github.com
2. Нажми **New repository** (зелёная кнопка)
3. Назови репозиторий: `marketlens` (или любое имя)
4. **Public** (обязательно для бесплатного GitHub Pages!)
5. Нажми **Create repository**

---

### 2. Инициализируй Git локально

Открой PowerShell в папке `C:\Marketlense` и выполни:

```powershell
# Инициализировать Git
git init

# Добавить все файлы
git add .

# Сделать первый коммит
git commit -m "Initial commit: MarketLens v6.0.0"

# Переименовать ветку в main
git branch -M main
```

---

### 3. Подключи GitHub репозиторий

**Замени `твой-username` на свой username GitHub:**

```powershell
git remote add origin https://github.com/твой-username/marketlens.git
```

**Пример:**
```powershell
git remote add origin https://github.com/ivan-petrov/marketlens.git
```

---

### 4. Загрузи код на GitHub

```powershell
# Отправить код на GitHub
git push -u origin main
```

**Если попросит логин:**
- Username: твой GitHub username
- Password: используй **Personal Access Token** (не пароль!)

**Как создать Token:**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Выбери срок: 90 days
4. Отметь: `repo` (всё в разделе repo)
5. Generate token
6. **Скопируй токен** (он больше не покажется!)
7. Используй его вместо пароля

---

### 5. Включи GitHub Pages

1. Зайди в свой репозиторий на GitHub
2. **Settings** → **Pages** (в левом меню)
3. **Source:** Deploy from a branch
4. **Branch:** `main`
5. **Folder:** `/docs` (выбери `/docs` вместо `/root`!)
6. Нажми **Save**

**Готово!** Через 2-3 минуты сайт будет доступен:

```
https://твой-username.github.io/marketlens/
```

---

## 🎯 Что уже настроено

✅ **API_BASE_URL автоматически определяет:**
- Если `github.io` → использует `http://185.91.53.49:3000`
- Если `localhost` → использует `http://localhost:3000`

✅ **Папка `docs/` создана** с копией `index.html` и `manifest.json`

✅ **`.gitignore` настроен** — не загрузятся:
- `node_modules/`
- `.env`
- `logs/`
- бэкап файлы

---

## 📂 Структура репозитория

После push на GitHub у тебя будет:

```
marketlens/
├── docs/              ← Это для GitHub Pages!
│   ├── index.html     ← Фронтенд с правильным API URL
│   └── manifest.json  ← PWA манифест
├── scripts/           ← Скрипты деплоя
├── server.js          ← Бэкенд (на Selectel)
├── package.json
├── ecosystem.config.js
├── .gitignore
└── README.md
```

**GitHub Pages будет раздавать только папку `docs/`** — это важно!

---

## 🔄 Как обновлять фронтенд

Если изменил `index.html`:

```powershell
# 1. Скопируй изменения в docs/
Copy-Item -Path "C:\Marketlense\index.html" -Destination "C:\Marketlense\docs\index.html" -Force

# 2. Коммит и push
git add .
git commit -m "Update frontend"
git push
```

Через 1-2 минуты изменения появятся на `github.io`.

---

## 🛠️ Полезные команды Git

```powershell
# Проверить статус
git status

# Посмотреть историю коммитов
git log --oneline

# Добавить файлы
git add .

# Сделать коммит
git commit -m "Твоё сообщение"

# Отправить на GitHub
git push

# Проверить remote URL
git remote -v

# Изменить remote URL
git remote set-url origin https://github.com/новый-username/marketlens.git
```

---

## 🔥 Итоговая схема

```
┌─────────────────────────────────────────────────┐
│  GitHub Pages (Фронтенд)                        │
│  https://твой-username.github.io/marketlens/    │
│  ├── index.html                                 │
│  └── manifest.json                              │
└─────────────────────────────────────────────────┘
                    ↓
                 API запросы
                    ↓
┌─────────────────────────────────────────────────┐
│  Selectel VPS (Бэкенд)                          │
│  http://185.91.53.49:3000                       │
│  ├── server.js (Node.js + PM2)                  │
│  ├── PostgreSQL                                 │
│  └── Nginx + SSL (опционально)                  │
└─────────────────────────────────────────────────┘
```

---

## 🚨 CORS на сервере

**Важно!** Чтобы GitHub Pages мог обращаться к API, нужно настроить CORS на сервере.

В `server.js` уже настроено:

```javascript
const allowedOrigins = IS_PRODUCTION
    ? [
        'https://твой-username.github.io',  // ← Добавь свой домен!
        process.env.FRONTEND_URL
      ].filter(Boolean)
    : ['http://localhost:3000', 'http://localhost:5173'];
```

**После создания GitHub Pages репозитория:**

1. Открой `.env.production` на сервере
2. Добавь:
   ```
   FRONTEND_URL=https://твой-username.github.io
   ```
3. Перезапусти PM2:
   ```bash
   pm2 restart marketlens
   ```

---

## ✅ Чеклист GitHub Pages

- [ ] Создан репозиторий на GitHub (Public)
- [ ] `git init` выполнен локально
- [ ] `git commit` сделан
- [ ] `git remote add origin` подключен
- [ ] `git push -u origin main` выполнен
- [ ] GitHub Pages включен (Settings → Pages)
- [ ] Branch: `main`, Folder: `/docs`
- [ ] Сайт доступен на `https://твой-username.github.io/marketlens/`
- [ ] CORS настроен на сервере (добавлен FRONTEND_URL)
- [ ] API работает (проверь Network в DevTools)

---

## 🎉 ГОТОВО!

После этих шагов у тебя будет:
- ✅ Фронтенд на GitHub Pages (бесплатно, https!)
- ✅ Бэкенд на Selectel (185.91.53.49:3000)
- ✅ Автоматическое определение API URL
- ✅ Возможность обновлять через `git push`

**Открывай GitHub и начинай! 🚀**

---

## 📞 Проблемы?

**Ошибка 404 на GitHub Pages:**
- Проверь: Settings → Pages → Source должен быть `/docs`
- Подожди 2-3 минуты после push

**CORS ошибка:**
- Добавь `FRONTEND_URL` в `.env.production` на сервере
- Перезапусти PM2: `pm2 restart marketlens`

**API не работает:**
- Проверь: `http://185.91.53.49:3000/health` должен отвечать
- Открой DevTools → Console → смотри ошибки

---

**Создано:** GitHub Copilot  
**Дата:** 10 октября 2025 г.  
**Проект:** MarketLens v6.0.0 Production
