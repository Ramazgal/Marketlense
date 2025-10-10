#!/bin/bash

# ========================================
# MarketLens Restore Script
# ========================================
# Восстановление из резервной копии

set -e  # Выйти при ошибке

BACKUP_DIR="/home/marketlens/backups"
APP_DIR="/home/marketlens/marketlens"

echo "🔄 MarketLens Restore Script"
echo "==========================="
echo ""

# Проверить наличие бэкапов
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null)" ]; then
    echo "❌ Бэкапы не найдены в $BACKUP_DIR"
    exit 1
fi

# Показать список доступных бэкапов
echo "📦 Доступные бэкапы:"
echo ""
ls -lh "$BACKUP_DIR"/backup_*.tar.gz | awk '{print NR". "$9" ("$5")"}'
echo ""

# Выбрать бэкап
echo "Введите номер бэкапа для восстановления (или 'q' для выхода):"
read -r CHOICE

if [ "$CHOICE" = "q" ]; then
    echo "Отменено"
    exit 0
fi

# Получить имя файла бэкапа
BACKUP_FILE=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz | sed -n "${CHOICE}p")

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Неверный выбор"
    exit 1
fi

echo ""
echo "📦 Выбран бэкап: $(basename "$BACKUP_FILE")"
echo ""

# Подтверждение
echo "⚠️  ВНИМАНИЕ: Текущие файлы будут заменены!"
echo "   Продолжить? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "🔄 Начинаем восстановление..."
echo ""

# Остановить приложение
echo "⏸️  Остановка приложения..."
pm2 stop marketlens-api || echo "⚠️  Приложение не запущено"

# Распаковать бэкап во временную папку
TEMP_DIR="$BACKUP_DIR/restore_temp"
mkdir -p "$TEMP_DIR"

echo "📂 Распаковка архива..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Найти папку с бэкапом (она начинается с temp_)
RESTORE_FROM=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -z "$RESTORE_FROM" ]; then
    echo "❌ Ошибка: Не удалось найти файлы в архиве"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Восстановить файлы
RESTORED=0

if [ -f "$RESTORE_FROM/monitoring_db.json" ]; then
    cp "$RESTORE_FROM/monitoring_db.json" "$APP_DIR/"
    echo "✅ monitoring_db.json восстановлен"
    ((RESTORED++))
fi

if [ -f "$RESTORE_FROM/.env" ]; then
    echo "⚠️  .env найден в бэкапе"
    echo "   Восстановить .env? (yes/no)"
    read -r RESTORE_ENV
    if [ "$RESTORE_ENV" = "yes" ]; then
        cp "$RESTORE_FROM/.env" "$APP_DIR/"
        echo "✅ .env восстановлен"
        ((RESTORED++))
    fi
fi

# Удалить временную папку
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Восстановлено файлов: $RESTORED"
echo ""

# Запустить приложение
echo "▶️  Запуск приложения..."
pm2 start marketlens-api || pm2 restart marketlens-api

sleep 3
pm2 status marketlens-api

echo ""
echo "✅ Восстановление завершено!"
echo ""
echo "📊 Проверьте логи: pm2 logs"
echo ""
