# 🚀 Amvera Deploy - Быстрый старт

**Дата:** 10 октября 2025 г.  
**Платформа:** [Amvera.ru](https://amvera.ru)  
**Статус:** ✅ API ключ добавлен в `.env`

---

## 📋 Что такое Amvera?

**Amvera** — российская PaaS-платформа для деплоя приложений (аналог Heroku/Render).

**Преимущества:**
- 🌍 Российские дата-центры
- ⚡ Быстрый деплой из Git
- 💰 Бесплатный тариф
- 🔧 Поддержка Node.js, PostgreSQL, Redis
- 🔐 Автоматический SSL

---

## 🔑 API Ключ добавлен

**Файл `.env` обновлён:**
```env
# Amvera API Key (для деплоя)
AMVERA_API_KEY=eyJhbGciOi...
```

✅ **DoD выполнен:** Файл `.env` содержит актуальный ключ Amvera.

⚠️ **Безопасность:** Файл `.env` добавлен в `.gitignore` и не попадёт в Git!

---

## 🎯 Что дальше?

### Вариант 1: Деплой через Web UI (рекомендуется)

1. **Зайди на Amvera:**
   - https://console.amvera.ru
   - Логин: ramazgal (kazan090813@gmail.com)

2. **Создай новый проект:**
   - New Project → Node.js
   - Подключи GitHub репозиторий
   - Branch: `main`

3. **Настрой Environment Variables:**
   ```
   NODE_ENV=production
   PORT=3000
   GEMINI_API_KEY=твой_ключ
   ```

4. **Deploy:**
   - Нажми "Deploy"
   - Через 2-3 минуты приложение запустится

---

### Вариант 2: Деплой через CLI

```bash
# Установить Amvera CLI
npm install -g @amvera/cli

# Логин с API ключом
amvera auth login --token $AMVERA_API_KEY

# Создать проект
amvera create marketlens --type nodejs

# Задеплоить
amvera deploy
```

---

## 📊 Структура для Amvera

Amvera автоматически определит Node.js проект по `package.json`.

**Что нужно в проекте:**
- ✅ `package.json` — зависимости и скрипты
- ✅ `server.js` — точка входа
- ✅ `npm start` — команда запуска

**Уже есть в проекте!**

---

## 🔧 Настройка для Amvera

### 1. Обновить `package.json`

Amvera запускает `npm start`, проверь что в `package.json`:

```json
{
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": "20.x"
  }
}
```

### 2. Настроить переменные окружения

**В Amvera Console → Settings → Environment Variables:**

```
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
GEMINI_API_KEY=твой_gemini_ключ
```

### 3. База данных (опционально)

**Если нужна PostgreSQL:**
- Amvera → Add-ons → PostgreSQL
- Скопируй `DATABASE_URL`
- Добавь в Environment Variables

---

## 🚀 Быстрый деплой (3 шага)

### Шаг 1: Push на GitHub

```powershell
git add .
git commit -m "Prepare for Amvera deploy"
git push
```

### Шаг 2: Подключи репозиторий в Amvera

1. Amvera Console → New Project
2. Connect GitHub → Выбери `marketlens`
3. Branch: `main`

### Шаг 3: Настрой и задеплой

1. **Environment Variables:**
   ```
   GEMINI_API_KEY=твой_ключ
   ```

2. **Deploy:**
   - Нажми "Deploy"
   - Через 2-3 минуты → готово!

3. **Результат:**
   ```
   https://marketlens-твой-проект.amvera.app
   ```

---

## 📱 После деплоя

### Обновить фронтенд (index.html)

**Если фронтенд на GitHub Pages, обнови API_BASE_URL:**

```javascript
const API_BASE_URL = (() => {
    // Для GitHub Pages → Amvera backend
    if (window.location.hostname.includes('github.io')) {
        return 'https://marketlens-твой-проект.amvera.app';
    }
    // Для localhost
    return 'http://localhost:3000';
})();
```

### Настроить CORS на сервере

**В Amvera Environment Variables добавь:**
```
FRONTEND_URL=https://твой-username.github.io
```

---

## 🔄 Автоматический деплой

**Amvera поддерживает Auto Deploy:**

1. Amvera Console → Settings → Auto Deploy
2. Включи "Deploy on push to main"
3. Теперь каждый `git push` → автоматический деплой!

---

## 📊 Мониторинг

**В Amvera Console:**
- **Logs** — логи приложения в реальном времени
- **Metrics** — CPU, RAM, запросы
- **Health** — статус приложения

**Health Check endpoint:**
```
https://marketlens-твой-проект.amvera.app/health
```

---

## 💰 Тарифы

**Free Plan:**
- 256 MB RAM
- 0.5 CPU
- 1 GB disk
- **Достаточно для MVP!**

**Paid Plans:**
- От 200₽/месяц
- Больше ресурсов
- Кастомные домены

---

## 🔗 Полезные ссылки

- **Amvera Console:** https://console.amvera.ru
- **Документация:** https://docs.amvera.ru
- **Support:** https://t.me/amvera_support
- **GitHub:** https://github.com/amvera-ru

---

## ✅ Чеклист

- [x] API ключ добавлен в `.env`
- [x] `.env` добавлен в `.gitignore`
- [ ] Код отправлен на GitHub (`git push`)
- [ ] Проект создан в Amvera Console
- [ ] GitHub репозиторий подключён
- [ ] Environment Variables настроены
- [ ] Первый деплой выполнен
- [ ] Health check работает
- [ ] CORS настроен (если нужен)
- [ ] Фронтенд обновлён с новым API URL

---

## 🚨 Troubleshooting

### Ошибка: "Module not found"

**Решение:** Проверь `package.json`, все зависимости должны быть в `dependencies` (не в `devDependencies`).

### Ошибка: "Port already in use"

**Решение:** Amvera автоматически назначает порт через переменную `PORT`. Убедись что в `server.js`:
```javascript
const PORT = process.env.PORT || 3000;
```

### Приложение не запускается

**Решение:**
1. Проверь логи в Amvera Console → Logs
2. Убедись что `npm start` запускает `node server.js`
3. Проверь что GEMINI_API_KEY добавлен

---

## 🎉 Готово!

**Теперь у тебя:**
- ✅ API ключ Amvera сохранён безопасно
- ✅ Проект готов к деплою
- ✅ Инструкции по деплою

**Следующий шаг:** Push на GitHub и создай проект в Amvera Console!

---

**Документация:** AMVERA_DEPLOY.md  
**Дата:** 10 октября 2025 г.  
**Проект:** MarketLens v6.0.0
