# Простой тест таймаутов: инструкция по ручной проверке

Write-Host "🕐 Тест таймаутов fetch-запросов (15 секунд)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Способ 1: Через DevTools (рекомендуется)" -ForegroundColor Green
Write-Host "1. Откройте index.html в браузере"
Write-Host "2. Откройте DevTools (F12)"
Write-Host "3. Перейдите на вкладку Network"
Write-Host "4. Выберите 'Throttling' → 'Offline'"
Write-Host "5. Нажмите кнопку 'Анализ' или 'Поиск'"
Write-Host "6. Через 15 секунд должна появиться ошибка:"
Write-Host "   'Сервер слишком долго не отвечает. Попробуйте позже.'"
Write-Host ""

Write-Host "📋 Способ 2: Добавить задержку в server.js" -ForegroundColor Yellow
Write-Host "1. Откройте server.js"
Write-Host "2. Найдите строку 386: app.get('/analyze', async (req, res) => {"
Write-Host "3. Добавьте после неё:"
Write-Host "   await new Promise(resolve => setTimeout(resolve, 20000));"
Write-Host "4. Перезапустите сервер (npm start)"
Write-Host "5. Откройте index.html и нажмите 'Анализ'"
Write-Host "6. Через 15 секунд должна появиться ошибка"
Write-Host ""

Write-Host "📋 Способ 3: Использовать curl для теста" -ForegroundColor Cyan
Write-Host "Выполните команду:"
Write-Host "  curl -X GET 'http://localhost:3000/analyze?url=https://ozon.ru/product/123&marketplace=ozon' -m 20"
Write-Host "(сервер должен ответить в течение REQUEST_TIMEOUT_MS из .env)"
Write-Host ""

Write-Host "✅ Что проверяем:" -ForegroundColor Green
Write-Host "- Через 15 секунд запрос должен быть прерван (AbortController)"
Write-Host "- Кнопка должна разблокироваться"
Write-Host "- Должна появиться красная ошибка с текстом о таймауте"
Write-Host "- Спиннер должен исчезнуть"
Write-Host ""

Write-Host "🔍 Проверка кода в index.html:" -ForegroundColor Magenta
Write-Host "Найдите в index.html три блока с таймаутом:"
Write-Host ""

$indexPath = Join-Path (Split-Path $PSScriptRoot -Parent) "index.html"
$content = Get-Content -Path $indexPath -Raw

if ($content -match "setTimeout\(\(\) => abortController\.abort\(\), 15000\)") {
    Write-Host "✅ Таймауты найдены в коде!" -ForegroundColor Green
    $matches = [regex]::Matches($content, "setTimeout\(\(\) => abortController\.abort\(\), 15000\)")
    Write-Host "   Найдено блоков с таймаутом: $($matches.Count)" -ForegroundColor Green
    
    if ($matches.Count -ge 3) {
        Write-Host "   ✅ Все 3 формы защищены (Анализ, Поиск, Мониторинг)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Ожидалось 3 блока, найдено: $($matches.Count)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Таймауты НЕ найдены в коде!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
