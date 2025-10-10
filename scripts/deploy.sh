#!/bin/bash

# ========================================
# MarketLens Deployment Script
# ========================================
# Автоматический деплой новой версии

set -e  # Выйти при ошибке

APP_DIR="/home/marketlens/marketlens"
BACKUP_SCRIPT="/home/marketlens/backup.sh"

echo "🚀 MarketLens Deployment Script v1.0"
echo "===================================="
echo ""

# Проверка, что мы в правильной директории
if [ ! -d "$APP_DIR" ]; then
    echo "❌ Ошибка: Папка приложения не найдена: $APP_DIR"
    exit 1
fi

cd "$APP_DIR" || exit 1

# 1. Создать бэкап перед обновлением
echo "📦 Шаг 1/6: Создание бэкапа..."
if [ -f "$BACKUP_SCRIPT" ]; then
    bash "$BACKUP_SCRIPT"
    echo "✅ Бэкап создан"
else
    echo "⚠️  Скрипт бэкапа не найден, пропускаем"
fi
echo ""

# 2. Получить обновления (если используется Git)
if [ -d ".git" ]; then
    echo "⬇️  Шаг 2/6: Получение обновлений из Git..."
    git pull origin main
    echo "✅ Код обновлён"
else
    echo "⚠️  Шаг 2/6: Git репозиторий не найден"
    echo "   Загрузите файлы вручную через SCP/FTP"
    echo "   Нажмите Enter когда файлы будут загружены..."
    read -r
fi
echo ""

# 3. Установить зависимости
echo "📦 Шаг 3/6: Установка зависимостей..."
npm install --production
echo "✅ Зависимости установлены"
echo ""

# 4. Проверить синтаксис кода
echo "🔍 Шаг 4/6: Проверка синтаксиса..."
if node -c server.js; then
    echo "✅ Синтаксис корректен"
else
    echo "❌ Ошибка синтаксиса в server.js"
    exit 1
fi
echo ""

# 5. Перезапустить через PM2
echo "🔄 Шаг 5/6: Перезапуск приложения..."
pm2 reload ecosystem.config.js --env production
echo "✅ Приложение перезапущено"
echo ""

# 6. Проверить статус
echo "📊 Шаг 6/6: Проверка статуса..."
sleep 3
pm2 status marketlens-api
echo ""

# Проверить health endpoint
echo "🏥 Проверка health check..."
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Health check OK"
else
    echo "⚠️  Health check не отвечает"
    echo "   Проверьте логи: pm2 logs"
fi
echo ""

echo "✅ Деплой завершен успешно!"
echo ""
echo "📊 Полезные команды:"
echo "   pm2 logs          - Посмотреть логи"
echo "   pm2 monit         - Мониторинг в реальном времени"
echo "   pm2 restart all   - Полный перезапуск"
echo ""
