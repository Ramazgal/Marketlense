# 🚀 Загрузка MarketLens на GitHub

## ✅ Шаг 1: Создание репозитория на GitHub (выполнить вручную)

1. Перейдите на https://github.com/new
2. Создайте новый репозиторий:
   - **Repository name:** `marketlens` (или любое другое имя)
   - **Description:** `AI-powered MarketLens backend with Amvera GPT-4.1`
   - **Visibility:** Public или Private (на ваш выбор)
   - ⚠️ **НЕ** создавайте README, .gitignore или лицензию (они уже есть)
3. Нажмите **Create repository**
4. Скопируйте URL репозитория (например: `https://github.com/username/marketlens.git`)

---

## ✅ Шаг 2: Подключение к GitHub (выполнить в PowerShell)

### Вариант A: Если репозиторий уже существует

```powershell
# Замените YOUR_USERNAME и YOUR_REPO на ваши данные
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Пример:
# git remote add origin https://github.com/ramzigal/marketlens.git
```

### Вариант B: Проверка подключения

```powershell
git remote -v
```

Должно показать:
```
origin  https://github.com/YOUR_USERNAME/YOUR_REPO.git (fetch)
origin  https://github.com/YOUR_USERNAME/YOUR_REPO.git (push)
```

---

## ✅ Шаг 3: Отправка на GitHub

```powershell
# Переименуйте ветку в main (если нужно)
git branch -M main

# Отправьте код на GitHub
git push -u origin main
```

При первой отправке GitHub может запросить аутентификацию:
- **Username:** ваш логин на GitHub
- **Password:** Personal Access Token (НЕ обычный пароль!)

### Создание Personal Access Token:
1. https://github.com/settings/tokens
2. Generate new token (classic)
3. Выберите срок действия и права:
   - ✅ `repo` (полный доступ к репозиториям)
4. Скопируйте токен и используйте вместо пароля

---

## ✅ Шаг 4: Проверка на GitHub

Откройте ваш репозиторий на GitHub:
```
https://github.com/YOUR_USERNAME/YOUR_REPO
```

Должны увидеть:
- ✅ 88 файлов
- ✅ Коммит: "🚀 MarketLens v6.1.0 - Complete migration to Amvera GPT-4.1"
- ✅ README.md отображается на главной странице

---

## 📊 Что загружено

### Основной код:
- `server.js` (1062 строки) - Production сервер
- `package.json` - Зависимости и скрипты
- `index.html` - Фронтенд
- `manifest.json` - PWA манифест

### Тестирование:
- `mock-server.js` - MOCK AI сервер
- `test-server.js` - Упрощённый тестовый сервер
- `test-ai.html` - UI для тестирования AI
- `diagnose-api.js` - Диагностика Amvera API
- `scripts/` - 17 тестовых скриптов

### Документация:
- `README.md` - Главная документация
- `QUICKSTART.md` - Быстрый старт
- `FINAL_STATUS.md` - Итоговый статус миграции
- `AMVERA_MIGRATION_COMPLETE.md` - Полное резюме
- 30+ других MD файлов с детальной документацией

### Конфигурация:
- `.gitignore` - Исключения (node_modules, .env)
- `.env.example` - Пример переменных окружения
- `ecosystem.config.js` - PM2 конфигурация
- `Dockerfile` - Docker образ

---

## 🔐 Безопасность

### ✅ Что НЕ загружено (защищено .gitignore):
- `.env` - API ключи (AMVERA_API_KEY)
- `node_modules/` - Зависимости
- `monitoring_db.json` - Локальная БД

### ⚠️ Важно:
Файл `.env` НЕ загружается на GitHub! Это правильно — API ключи должны быть в секрете.

Для деплоя на сервер создайте `.env` файл вручную:
```env
AMVERA_API_KEY=ваш_ключ_здесь
PORT=3000
NODE_ENV=production
```

---

## 🎯 Следующие шаги

### После загрузки на GitHub:

1. **Добавьте описание репозитория:**
   - Topics: `nodejs`, `express`, `ai`, `gpt-4`, `marketplace`
   - Website: URL вашего деплоя (если есть)

2. **Настройте GitHub Actions (опционально):**
   - Создайте `.github/workflows/deploy.yml`
   - Автоматический деплой при push

3. **Добавьте README badges:**
   ```markdown
   ![Version](https://img.shields.io/badge/version-6.1.0-blue)
   ![Node](https://img.shields.io/badge/node-%3E%3D20.0.0-green)
   ![License](https://img.shields.io/badge/license-MIT-blue)
   ```

4. **Пригласите коллабораторов:**
   - Settings → Collaborators → Add people

---

## 🐛 Troubleshooting

### Ошибка: "remote origin already exists"
```powershell
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### Ошибка: "failed to push some refs"
```powershell
# Загрузите изменения с GitHub
git pull origin main --allow-unrelated-histories

# Решите конфликты (если есть)
# Затем отправьте снова
git push -u origin main
```

### Ошибка: "Authentication failed"
- Используйте Personal Access Token вместо пароля
- Убедитесь, что токен имеет права `repo`

---

## 📝 Полезные команды

```powershell
# Проверить статус
git status

# Посмотреть историю коммитов
git log --oneline

# Проверить remote
git remote -v

# Отправить изменения
git push

# Загрузить изменения
git pull

# Создать новую ветку
git checkout -b feature/new-feature

# Переключиться на ветку
git checkout main
```

---

## 🎉 Готово!

Ваш код MarketLens v6.1.0 теперь на GitHub! 🚀

**Следующие шаги:**
1. Поделитесь ссылкой на репозиторий
2. Настройте CI/CD (GitHub Actions)
3. Деплойте на Amvera Cloud
4. Добавьте contributors

---

*Создано: 10 октября 2025 г.*  
*Версия: MarketLens 6.1.0*
