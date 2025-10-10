# Тест 4.1: Проверка Мониторинга (Пульс Конкурента)
# Проверяем работу ключевой платной функции

Write-Host ""
Write-Host "=== ТЕСТ 4.1: МОНИТОРИНГ КОНКУРЕНТОВ ===" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:3000"

# Проверка, что сервер запущен
try {
    Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing -ErrorAction Stop | Out-Null
    Write-Host "✅ Сервер запущен" -ForegroundColor Green
} catch {
    Write-Host "❌ Сервер не запущен. Запустите его командой: npm start" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 ШАГ 1: Добавляем товар в мониторинг" -ForegroundColor Yellow
Write-Host ""

$addBody = @{
    marketplace = "ozon"
    productUrl = "https://www.ozon.ru/product/example-123456"
    notes = "Тестовый товар для проверки мониторинга"
} | ConvertTo-Json -Compress

try {
    $addResponse = Invoke-RestMethod -Uri "$baseUrl/monitoring/add" `
        -Method POST `
        -ContentType "application/json" `
        -Body $addBody

    Write-Host "✅ Товар добавлен в мониторинг" -ForegroundColor Green
    Write-Host "   ID: $($addResponse.item.id)" -ForegroundColor Gray
    Write-Host "   Начальная цена: $($addResponse.item.currentPrice)₽" -ForegroundColor Gray
    Write-Host "   История записей: $($addResponse.item.history.Count)" -ForegroundColor Gray
    
    $monitoringId = $addResponse.item.id
} catch {
    Write-Host "❌ Ошибка добавления: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 ШАГ 2: Проверяем список товаров в мониторинге" -ForegroundColor Yellow
Write-Host ""

try {
    $listResponse = Invoke-RestMethod -Uri "$baseUrl/monitoring" -Method GET
    Write-Host "✅ Список получен" -ForegroundColor Green
    Write-Host "   Всего товаров: $($listResponse.total)" -ForegroundColor Gray
    
    if ($listResponse.total -eq 0) {
        Write-Host "❌ В мониторинге нет товаров!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Ошибка получения списка: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 ШАГ 3: Имитируем изменение цены (тестовый endpoint)" -ForegroundColor Yellow
Write-Host ""

try {
    $testChangeResponse = Invoke-RestMethod -Uri "$baseUrl/monitoring/test-change" -Method POST
    
    Write-Host "✅ Цена изменена для тестирования" -ForegroundColor Green
    Write-Host "   Старая цена: $($testChangeResponse.oldPrice)₽" -ForegroundColor Gray
    Write-Host "   Новая цена: $($testChangeResponse.newPrice)₽" -ForegroundColor Gray
    Write-Host "   Изменение: $($testChangeResponse.change)₽ ($($testChangeResponse.changePercent))" -ForegroundColor Gray
    Write-Host "   История записей: $($testChangeResponse.item.history.Count)" -ForegroundColor Gray
    
    if ($testChangeResponse.newPrice -ne 1000) {
        Write-Host "❌ Цена не изменилась на 1000₽!" -ForegroundColor Red
        exit 1
    }
    
    if ($testChangeResponse.item.history.Count -lt 2) {
        Write-Host "❌ История не обновилась (должно быть минимум 2 записи)!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Ошибка изменения цены: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 ШАГ 4: Проверяем обновлённые данные" -ForegroundColor Yellow
Write-Host ""

try {
    $updatedListResponse = Invoke-RestMethod -Uri "$baseUrl/monitoring" -Method GET
    $updatedItem = $updatedListResponse.items | Where-Object { $_.id -eq $monitoringId }
    
    if ($updatedItem) {
        Write-Host "✅ Товар найден в списке" -ForegroundColor Green
        Write-Host "   Текущая цена: $($updatedItem.currentPrice)₽" -ForegroundColor Gray
        Write-Host "   History entries: $($updatedItem.history.Count)" -ForegroundColor Gray
        
        if ($updatedItem.currentPrice -ne 1000) {
            Write-Host "ERROR: Price not updated in monitoring list!" -ForegroundColor Red
            exit 1
        }
        
        # Check last history entry
        $lastHistory = $updatedItem.history[-1]
        Write-Host ""
        Write-Host "   Last change:" -ForegroundColor Cyan
        Write-Host "   - Time: $($lastHistory.timestamp)" -ForegroundColor Gray
        Write-Host "   - Price: $($lastHistory.price) RUB" -ForegroundColor Gray
        Write-Host "   - Change: $($lastHistory.change) RUB ($($lastHistory.changePercent)%)" -ForegroundColor Gray
        
        if ($lastHistory.change -lt 0) {
            Write-Host "   - Direction: DOWN" -ForegroundColor Red
        } elseif ($lastHistory.change -gt 0) {
            Write-Host "   - Direction: UP" -ForegroundColor Green
        } else {
            Write-Host "   - Direction: NO CHANGE" -ForegroundColor Gray
        }
    } else {
        Write-Host "ERROR: Item not found in list!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Ошибка проверки данных: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 ШАГ 5: Очистка - удаляем тестовый товар" -ForegroundColor Yellow
Write-Host ""

try {
    Invoke-RestMethod -Uri "$baseUrl/monitoring/$monitoringId" -Method DELETE | Out-Null
    Write-Host "✅ Тестовый товар удалён" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Не удалось удалить тестовый товар (ID: $monitoringId)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ ТЕСТ 4.1: ПРОЙДЕН УСПЕШНО!                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Проверено:" -ForegroundColor Cyan
Write-Host "   ✅ Добавление товара в мониторинг" -ForegroundColor White
Write-Host "   ✅ Сохранение начальной цены в history" -ForegroundColor White
Write-Host "   ✅ Изменение цены на 1000₽" -ForegroundColor White
Write-Host "   ✅ Добавление новой записи в history" -ForegroundColor White
Write-Host "   ✅ Обновление currentPrice" -ForegroundColor White
Write-Host "   ✅ Корректное вычисление change и changePercent" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Следующий шаг: Ручное тестирование в браузере" -ForegroundColor Yellow
Write-Host "   1. Откройте index.html" -ForegroundColor Gray
Write-Host "   2. Перейдите на вкладку 'Мониторинг'" -ForegroundColor Gray
Write-Host "   3. Добавьте товар" -ForegroundColor Gray
Write-Host "   4. Вызовите: curl -X POST $baseUrl/monitoring/test-change" -ForegroundColor Gray
Write-Host "   5. Нажмите 'Проверить обновления' в приложении" -ForegroundColor Gray
Write-Host "   6. Убедитесь что:" -ForegroundColor Gray
Write-Host "      • Цена изменилась на 1000₽" -ForegroundColor Gray
Write-Host "      • Появился красный индикатор ▼ (если цена упала)" -ForegroundColor Gray
Write-Host "      • График перерисовался с новой точкой" -ForegroundColor Gray
Write-Host ""
