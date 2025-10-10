# Test script for Amvera GPT-4.1 AI Strategy
# Encoding: UTF-8

$body = @{
    userEvidence = @(
        'Продаём беспроводные наушники за 2990 рублей',
        'Рейтинг 4.8 звёзд',
        '50 отзывов за месяц'
    )
    competitorsEvidence = @(
        'Конкурент A: 3500₽, рейтинг 4.6',
        'Конкурент B: 2700₽, рейтинг 4.2'
    )
    tone = 'analytical'
    focus = @('pricing', 'marketing')
} | ConvertTo-Json

Write-Host "=== Тестирование Amvera GPT-4.1 AI-стратега ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Отправка запроса..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri http://localhost:3000/strategize -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 30
    
    Write-Host ""
    Write-Host "✅ Успешно! Ответ от AI:" -ForegroundColor Green
    Write-Host ""
    Write-Host $response.strategy -ForegroundColor White
    Write-Host ""
    Write-Host "=== Тест пройден успешно ===" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "❌ Ошибка:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Детали ошибки:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Yellow
    }
}
