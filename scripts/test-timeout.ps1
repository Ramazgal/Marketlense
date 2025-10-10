# Скрипт для тестирования таймаутов fetch-запросов
# Имитирует медленный ответ сервера

Write-Host "🕐 Тест таймаутов fetch-запросов" -ForegroundColor Cyan
Write-Host ""

# Создаем временный файл с медленным endpoint'ом
$testServerCode = @'
const express = require('express');
const app = express();
const port = 3001;

// Медленный endpoint для теста
app.get('/slow-analyze', async (req, res) => {
    console.log('Получен запрос на /slow-analyze, ждём 20 секунд...');
    await new Promise(resolve => setTimeout(resolve, 20000)); // 20 секунд
    res.json({ message: 'Этот ответ никогда не должен дойти до клиента' });
});

app.listen(port, () => {
    console.log(`Тестовый медленный сервер запущен на порту ${port}`);
});
'@

$testServerPath = Join-Path $PSScriptRoot "test-slow-server.js"
Set-Content -Path $testServerPath -Value $testServerCode -Encoding UTF8

Write-Host "📝 Создан временный тестовый сервер: $testServerPath" -ForegroundColor Green

# Запускаем тестовый сервер в фоне
Write-Host "🚀 Запуск медленного сервера на порту 3001..." -ForegroundColor Yellow
$serverJob = Start-Job -ScriptBlock {
    param($serverPath)
    Set-Location (Split-Path $serverPath -Parent | Split-Path -Parent)
    node $serverPath
} -ArgumentList $testServerPath

Start-Sleep -Seconds 2

# Проверяем, что сервер запустился
try {
    $healthCheck = Invoke-WebRequest -Uri "http://127.0.0.1:3001/slow-analyze" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "❌ Сервер отвечает слишком быстро!" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "timeout") {
        Write-Host "✅ Тестовый сервер работает (ожидаемый таймаут)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Сервер запущен, но проверка не удалась" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📋 Инструкция по тестированию:" -ForegroundColor Cyan
Write-Host "1. Откройте index.html в браузере"
Write-Host "2. Измените строку fetch в коде (DevTools → Sources):"
Write-Host "   Было: fetch(\`/analyze?...\`)"
Write-Host "   Стало: fetch(\`http://localhost:3001/slow-analyze\`)"
Write-Host "3. Нажмите кнопку 'Анализ'"
Write-Host "4. Через 15 секунд должна появиться ошибка:"
Write-Host "   'Сервер слишком долго не отвечает. Попробуйте позже.'"
Write-Host ""
Write-Host "🔍 Альтернатива (проще): Используйте DevTools → Network → Throttling → Offline"
Write-Host "   Или добавьте breakpoint в сервер и удерживайте его >15 секунд"
Write-Host ""

Write-Host "Нажмите Enter для остановки тестового сервера..." -ForegroundColor Yellow
Read-Host

# Останавливаем сервер
Stop-Job -Job $serverJob
Remove-Job -Job $serverJob
Write-Host "🛑 Тестовый сервер остановлен" -ForegroundColor Green

# Удаляем временный файл
Remove-Item -Path $testServerPath -Force
Write-Host "🗑️  Временный файл удалён" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Тест завершён" -ForegroundColor Green
