#!/bin/bash

# ========================================
# MarketLens - Полная очистка и деплой
# ========================================
# Автоматический скрипт для развертывания на чистом сервере

set -e  # Выход при ошибке

echo "🔥 MarketLens - Автоматический деплой на Selectel"
echo "=================================================="
echo ""

# ============================================
# ШАГ 1: ОЧИСТКА СТАРОГО ПРОЕКТА
# ============================================
echo "🗑️  ШАГ 1/10: Очистка старых файлов..."
echo ""

# Остановить все PM2 процессы
echo "⏸️  Остановка PM2 процессов..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Убить все Node процессы
echo "⏸️  Остановка Node.js процессов..."
killall node 2>/dev/null || true
sleep 2

# Удалить старые директории проекта
echo "🗑️  Удаление старых файлов проекта..."
rm -rf /home/marketlens/marketlens 2>/dev/null || true
rm -rf /var/www/marketlens 2>/dev/null || true
rm -rf /opt/marketlens 2>/dev/null || true
rm -rf /root/marketlens 2>/dev/null || true

# Удалить логи
echo "🗑️  Удаление старых логов..."
rm -rf /home/marketlens/logs 2>/dev/null || true
rm -rf /home/marketlens/backups 2>/dev/null || true
rm -rf /var/log/marketlens* 2>/dev/null || true

echo "✅ Очистка завершена!"
echo ""

# ============================================
# ШАГ 2: СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ (если не существует)
# ============================================
echo "👤 ШАГ 2/10: Создание пользователя marketlens..."
echo ""

if id "marketlens" &>/dev/null; then
    echo "✅ Пользователь marketlens уже существует"
else
    adduser --disabled-password --gecos "" marketlens
    usermod -aG sudo marketlens
    echo "✅ Пользователь marketlens создан"
fi
echo ""

# ============================================
# ШАГ 3: ОБНОВЛЕНИЕ СИСТЕМЫ
# ============================================
echo "📦 ШАГ 3/10: Обновление системы..."
echo ""

apt update
apt upgrade -y

echo "✅ Система обновлена"
echo ""

# ============================================
# ШАГ 4: УСТАНОВКА NODE.JS 20.x
# ============================================
echo "📦 ШАГ 4/10: Установка Node.js 20.x..."
echo ""

# Проверить версию Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "Node.js уже установлен: $NODE_VERSION"
    
    # Если версия не 20.x, переустановить
    if [[ ! "$NODE_VERSION" =~ ^v20\. ]]; then
        echo "⚠️  Требуется Node.js 20.x, переустанавливаем..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
    fi
else
    echo "Устанавливаем Node.js 20.x..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi

echo "✅ Node.js $(node --version) установлен"
echo "✅ npm $(npm --version) установлен"
echo ""

# ============================================
# ШАГ 5: УСТАНОВКА PM2
# ============================================
echo "📦 ШАГ 5/10: Установка PM2..."
echo ""

if command -v pm2 &> /dev/null; then
    echo "✅ PM2 уже установлен: $(pm2 --version)"
else
    npm install -g pm2
    echo "✅ PM2 установлен"
fi
echo ""

# ============================================
# ШАГ 6: УСТАНОВКА POSTGRESQL (опционально)
# ============================================
echo "📦 ШАГ 6/10: Установка PostgreSQL..."
echo ""

if command -v psql &> /dev/null; then
    echo "✅ PostgreSQL уже установлен"
else
    apt install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
    echo "✅ PostgreSQL установлен"
fi
echo ""

# ============================================
# ШАГ 7: УСТАНОВКА NGINX
# ============================================
echo "📦 ШАГ 7/10: Установка Nginx..."
echo ""

if command -v nginx &> /dev/null; then
    echo "✅ Nginx уже установлен"
else
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "✅ Nginx установлен"
fi
echo ""

# ============================================
# ШАГ 8: УСТАНОВКА CERTBOT (для SSL)
# ============================================
echo "📦 ШАГ 8/10: Установка Certbot..."
echo ""

if command -v certbot &> /dev/null; then
    echo "✅ Certbot уже установлен"
else
    apt install -y certbot python3-certbot-nginx
    echo "✅ Certbot установлен"
fi
echo ""

# ============================================
# ШАГ 9: НАСТРОЙКА ФАЙРВОЛА
# ============================================
echo "🔒 ШАГ 9/10: Настройка файрвола UFW..."
echo ""

if command -v ufw &> /dev/null; then
    # Разрешить SSH
    ufw allow 22/tcp
    # Разрешить HTTP и HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    # Разрешить порт приложения (временно)
    ufw allow 3000/tcp
    
    # Включить UFW (только если еще не включен)
    ufw --force enable 2>/dev/null || true
    
    echo "✅ Файрвол настроен"
    ufw status
else
    echo "⚠️  UFW не найден, устанавливаем..."
    apt install -y ufw
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp
    ufw --force enable
    echo "✅ Файрвол установлен и настроен"
fi
echo ""

# ============================================
# ШАГ 10: СОЗДАНИЕ ДИРЕКТОРИИ ДЛЯ ПРОЕКТА
# ============================================
echo "📁 ШАГ 10/10: Создание директорий..."
echo ""

# Создать директорию проекта
mkdir -p /home/marketlens/marketlens
mkdir -p /home/marketlens/logs
mkdir -p /home/marketlens/backups

# Установить владельца
chown -R marketlens:marketlens /home/marketlens

echo "✅ Директории созданы"
echo ""

# ============================================
# ФИНАЛЬНЫЙ ОТЧЕТ
# ============================================
echo ""
echo "=========================================="
echo "✅ СЕРВЕР ГОТОВ К ДЕПЛОЮ MARKETLENS!"
echo "=========================================="
echo ""
echo "📊 Что установлено:"
echo "   ✅ Node.js $(node --version)"
echo "   ✅ npm $(npm --version)"
echo "   ✅ PM2 $(pm2 --version)"
echo "   ✅ PostgreSQL $(psql --version | head -n1)"
echo "   ✅ Nginx $(nginx -v 2>&1 | cut -d'/' -f2)"
echo "   ✅ Certbot $(certbot --version | cut -d' ' -f2)"
echo "   ✅ UFW файрвол"
echo ""
echo "📁 Директории:"
echo "   /home/marketlens/marketlens  - Проект"
echo "   /home/marketlens/logs        - Логи"
echo "   /home/marketlens/backups     - Бэкапы"
echo ""
echo "🔥 Следующие шаги:"
echo ""
echo "1. Загрузить код проекта в /home/marketlens/marketlens"
echo "   С локальной машины (PowerShell):"
echo "   scp -r C:\\Marketlense\\* root@185.91.53.49:/home/marketlens/marketlens/"
echo ""
echo "2. Подключиться как пользователь marketlens:"
echo "   su - marketlens"
echo ""
echo "3. Перейти в директорию проекта:"
echo "   cd ~/marketlens"
echo ""
echo "4. Установить зависимости:"
echo "   npm install --production"
echo ""
echo "5. Настроить .env файл:"
echo "   cp .env.production .env"
echo "   nano .env"
echo "   (Добавить GEMINI_API_KEY и другие параметры)"
echo ""
echo "6. Запустить через PM2:"
echo "   pm2 start ecosystem.config.js --env production"
echo "   pm2 startup"
echo "   pm2 save"
echo ""
echo "7. Настроить Nginx (как root):"
echo "   exit  # Выйти из пользователя marketlens"
echo "   nano /etc/nginx/sites-available/marketlens"
echo "   (Скопировать конфиг из DEPLOYMENT.md)"
echo ""
echo "8. Получить SSL сертификат:"
echo "   certbot --nginx -d your-domain.com"
echo ""
echo "=========================================="
echo "📖 Полная документация: DEPLOYMENT.md"
echo "=========================================="
echo ""
