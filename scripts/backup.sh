#!/bin/bash

# ========================================
# MarketLens Backup Script
# ========================================
# Создание резервных копий данных

set -e  # Выйти при ошибке

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/home/marketlens/backups"
APP_DIR="/home/marketlens/marketlens"
MAX_BACKUPS=30  # Хранить последние 30 бэкапов

echo "📦 MarketLens Backup Script"
echo "=========================="
echo ""

# Создать папку для бэкапов если не существует
mkdir -p "$BACKUP_DIR"

# Создать временную папку
TEMP_DIR="$BACKUP_DIR/temp_$DATE"
mkdir -p "$TEMP_DIR"

echo "📁 Создание бэкапа: $DATE"
echo ""

# Счётчик файлов
BACKED_UP=0

# 1. Бэкап данных мониторинга
if [ -f "$APP_DIR/monitoring_db.json" ]; then
    cp "$APP_DIR/monitoring_db.json" "$TEMP_DIR/"
    echo "✅ monitoring_db.json"
    ((BACKED_UP++))
else
    echo "⚠️  monitoring_db.json не найден"
fi

# 2. Бэкап .env (важно для восстановления)
if [ -f "$APP_DIR/.env" ]; then
    cp "$APP_DIR/.env" "$TEMP_DIR/"
    echo "✅ .env"
    ((BACKED_UP++))
else
    echo "⚠️  .env не найден"
fi

# 3. Бэкап package.json (для версионирования)
if [ -f "$APP_DIR/package.json" ]; then
    cp "$APP_DIR/package.json" "$TEMP_DIR/"
    echo "✅ package.json"
    ((BACKED_UP++))
fi

# 4. Бэкап ecosystem.config.js
if [ -f "$APP_DIR/ecosystem.config.js" ]; then
    cp "$APP_DIR/ecosystem.config.js" "$TEMP_DIR/"
    echo "✅ ecosystem.config.js"
    ((BACKED_UP++))
fi

echo ""
echo "📦 Создание архива..."

# Создать tar.gz архив
ARCHIVE_NAME="backup_$DATE.tar.gz"
tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$BACKUP_DIR" "temp_$DATE"

# Удалить временную папку
rm -rf "$TEMP_DIR"

# Получить размер архива
ARCHIVE_SIZE=$(du -h "$BACKUP_DIR/$ARCHIVE_NAME" | cut -f1)

echo "✅ Архив создан: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
echo ""

# Удалить старые бэкапы (оставить только последние MAX_BACKUPS)
echo "🗑️  Очистка старых бэкапов..."
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    EXCESS=$((BACKUP_COUNT - MAX_BACKUPS))
    echo "   Найдено $BACKUP_COUNT бэкапов, удаляем $EXCESS старых..."
    ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n +"$((MAX_BACKUPS + 1))" | xargs rm -f
    echo "✅ Удалено $EXCESS старых бэкапов"
else
    echo "   Бэкапов: $BACKUP_COUNT (лимит: $MAX_BACKUPS)"
fi

echo ""
echo "✅ Бэкап завершен!"
echo ""
echo "📊 Статистика:"
echo "   Файлов в бэкапе: $BACKED_UP"
echo "   Размер архива: $ARCHIVE_SIZE"
echo "   Всего бэкапов: $BACKUP_COUNT"
echo ""
echo "📂 Расположение: $BACKUP_DIR/$ARCHIVE_NAME"
echo ""
