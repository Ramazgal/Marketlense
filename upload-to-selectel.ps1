# ========================================
# MarketLens - Автоматическая загрузка на Selectel
# ========================================
# PowerShell скрипт для Windows

$SERVER = "185.91.53.49"
$USER = "root"
$PASSWORD = "iiqvPqIEOzJy"
$LOCAL_DIR = "C:\Marketlense"

Write-Host "🚀 MarketLens - Загрузка на Selectel" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Функция для выполнения SCP
function Upload-File {
    param($LocalFile, $RemotePath)
    
    $fileName = Split-Path $LocalFile -Leaf
    Write-Host "📤 Загрузка: $fileName" -ForegroundColor Cyan
    
    scp "$LocalFile" "${USER}@${SERVER}:${RemotePath}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ OK" -ForegroundColor Green
    } else {
        Write-Host "   ❌ ОШИБКА" -ForegroundColor Red
    }
}

Write-Host "📦 ШАГ 1/4: Загрузка скрипта автодеплоя..." -ForegroundColor Yellow
Upload-File "$LOCAL_DIR\scripts\full-deploy-selectel.sh" "/root/"
Write-Host ""

Write-Host "📦 ШАГ 2/4: Загрузка основных файлов..." -ForegroundColor Yellow
Upload-File "$LOCAL_DIR\server.js" "/home/marketlens/marketlens/"
Upload-File "$LOCAL_DIR\package.json" "/home/marketlens/marketlens/"
Upload-File "$LOCAL_DIR\package-lock.json" "/home/marketlens/marketlens/"
Upload-File "$LOCAL_DIR\ecosystem.config.js" "/home/marketlens/marketlens/"
Upload-File "$LOCAL_DIR\.env.production" "/home/marketlens/marketlens/.env"
Upload-File "$LOCAL_DIR\index.html" "/home/marketlens/marketlens/"
Upload-File "$LOCAL_DIR\manifest.json" "/home/marketlens/marketlens/"
Write-Host ""

Write-Host "📦 ШАГ 3/4: Загрузка скриптов управления..." -ForegroundColor Yellow
Upload-File "$LOCAL_DIR\scripts\deploy.sh" "/home/marketlens/marketlens/scripts/"
Upload-File "$LOCAL_DIR\scripts\backup.sh" "/home/marketlens/marketlens/scripts/"
Upload-File "$LOCAL_DIR\scripts\restore.sh" "/home/marketlens/marketlens/scripts/"
Write-Host ""

Write-Host "📦 ШАГ 4/4: Настройка прав..." -ForegroundColor Yellow
Write-Host "   Подключаемся к серверу для настройки..." -ForegroundColor Cyan

# SSH команды для выполнения на сервере
$sshCommands = @"
chmod +x /root/full-deploy-selectel.sh
mkdir -p /home/marketlens/marketlens/scripts
chown -R marketlens:marketlens /home/marketlens/marketlens
chmod +x /home/marketlens/marketlens/scripts/*.sh
"@

# Сохранить команды во временный файл
$tempFile = "$env:TEMP\marketlens-setup.sh"
$sshCommands | Out-File -FilePath $tempFile -Encoding ASCII

# Загрузить и выполнить
scp "$tempFile" "${USER}@${SERVER}:/tmp/marketlens-setup.sh"
ssh "${USER}@${SERVER}" "bash /tmp/marketlens-setup.sh && rm /tmp/marketlens-setup.sh"

Remove-Item $tempFile

Write-Host "   ✅ Права настроены" -ForegroundColor Green
Write-Host ""

# ========================================
# ФИНАЛЬНЫЕ ИНСТРУКЦИИ
# ========================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ ЗАГРУЗКА ЗАВЕРШЕНА!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "🔥 СЛЕДУЮЩИЕ ШАГИ:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Подключись к серверу:" -ForegroundColor Cyan
Write-Host "   ssh root@185.91.53.49" -ForegroundColor White
Write-Host "   Пароль: iiqvPqIEOzJy" -ForegroundColor White
Write-Host ""
Write-Host "2. Запусти автодеплой (на сервере):" -ForegroundColor Cyan
Write-Host "   /root/full-deploy-selectel.sh" -ForegroundColor White
Write-Host "   (Установит Node.js, PM2, PostgreSQL, Nginx, Certbot)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Переключись на пользователя marketlens:" -ForegroundColor Cyan
Write-Host "   su - marketlens" -ForegroundColor White
Write-Host ""
Write-Host "4. Установи зависимости:" -ForegroundColor Cyan
Write-Host "   cd ~/marketlens" -ForegroundColor White
Write-Host "   npm install --production" -ForegroundColor White
Write-Host ""
Write-Host "5. Настрой .env файл:" -ForegroundColor Cyan
Write-Host "   nano .env" -ForegroundColor White
Write-Host "   Добавь: GEMINI_API_KEY=твой_ключ" -ForegroundColor Gray
Write-Host "   Сохрани: Ctrl+O, Enter, Ctrl+X" -ForegroundColor Gray
Write-Host ""
Write-Host "6. Запусти через PM2:" -ForegroundColor Cyan
Write-Host "   pm2 start ecosystem.config.js --env production" -ForegroundColor White
Write-Host "   pm2 startup" -ForegroundColor White
Write-Host "   pm2 save" -ForegroundColor White
Write-Host ""
Write-Host "7. Проверь работу в браузере:" -ForegroundColor Cyan
Write-Host "   http://185.91.53.49:3000" -ForegroundColor White
Write-Host "   http://185.91.53.49:3000/health" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "📖 Полная инструкция: SELECTEL_DEPLOY_GUIDE.md" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Нажми Enter для завершения..." -ForegroundColor Yellow
Read-Host
