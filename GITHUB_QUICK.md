# 🚀 Быстрая инструкция: Загрузка на GitHub

## Вариант 1: Если репозиторий НЕ создан

### Шаг 1: Создайте репозиторий на GitHub
1. Откройте: https://github.com/new
2. Заполните:
   - Name: `marketlens`
   - Description: `AI-powered MarketLens with Amvera GPT-4.1`
   - Public/Private: на ваш выбор
   - ⚠️ НЕ добавляйте README, .gitignore, LICENSE
3. Нажмите "Create repository"
4. Скопируйте URL (например: `https://github.com/username/marketlens.git`)

### Шаг 2: Выполните команды (замените URL на свой):

```powershell
# Добавьте remote (замените на ваш URL!)
git remote add origin https://github.com/YOUR_USERNAME/marketlens.git

# Переименуйте ветку в main
git branch -M main

# Отправьте на GitHub
git push -u origin main
```

---

## Вариант 2: Если репозиторий УЖЕ создан

### Просто выполните:

```powershell
# Добавьте remote (замените на ваш URL!)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Переименуйте ветку
git branch -M main

# Отправьте
git push -u origin main
```

---

## 🔐 Аутентификация

При первом push GitHub попросит войти:

### Вариант A: Personal Access Token (рекомендуется)
1. Перейдите: https://github.com/settings/tokens
2. "Generate new token (classic)"
3. Выберите срок и права: ✅ `repo`
4. Скопируйте токен
5. Используйте токен вместо пароля

### Вариант B: GitHub CLI (современный способ)
```powershell
# Установите GitHub CLI
winget install --id GitHub.cli

# Авторизуйтесь
gh auth login

# Отправьте код
git push -u origin main
```

---

## ✅ Проверка

После успешной отправки:
```powershell
# Проверьте remote
git remote -v

# Должно показать:
# origin  https://github.com/username/repo.git (fetch)
# origin  https://github.com/username/repo.git (push)
```

Откройте репозиторий в браузере:
```
https://github.com/YOUR_USERNAME/YOUR_REPO
```

---

## 🎯 Что дальше?

После загрузки на GitHub вы можете:
- ✅ Поделиться ссылкой на проект
- ✅ Настроить GitHub Pages для документации
- ✅ Добавить GitHub Actions для CI/CD
- ✅ Пригласить коллабораторов
- ✅ Деплоить на Amvera/Vercel/Railway

---

## 📝 Команда для копирования:

**Замените YOUR_USERNAME и YOUR_REPO на свои данные!**

```powershell
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

---

*Готово к отправке! 🚀*
