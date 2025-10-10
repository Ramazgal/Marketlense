# Quick Test Suite for Marketlense
# Runs essential tests without complex formatting

$baseUrl = "http://localhost:3000"
$passed = 0
$failed = 0

Write-Host "`n========== MARKETLENSE QUICK TEST ==========" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n[1/6] Health Check..." -NoNewline
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -TimeoutSec 5
    if ($health.status -eq "ok") {
        Write-Host " PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL (wrong status)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host " FAIL (no response)" -ForegroundColor Red
    $failed++
}

# Test 2: Linting
Write-Host "[2/6] Code Linting..." -NoNewline
$lintResult = npm run lint 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
    $passed++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed++
}

# Test 3: Monitoring List
Write-Host "[3/6] Monitoring List..." -NoNewline
try {
    $list = Invoke-RestMethod -Uri "$baseUrl/monitoring"
    Write-Host " PASS ($($list.items.Count) items)" -ForegroundColor Green
    $passed++
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    $failed++
}

# Test 4: Add Item
Write-Host "[4/6] Add Monitoring Item..." -NoNewline
try {
    $newItem = @{
        marketplace = "ozon"
        productUrl = "https://www.ozon.ru/product/test-$(Get-Random)"
        notes = "Test"
    } | ConvertTo-Json
    
    $result = Invoke-RestMethod -Uri "$baseUrl/monitoring/add" -Method Post -Body $newItem -ContentType "application/json"
    Write-Host " PASS (ID: $($result.item.id))" -ForegroundColor Green
    $passed++
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    $failed++
}

# Test 5: Price Change Simulation
Write-Host "[5/6] Price Change Simulation..." -NoNewline
try {
    $result = Invoke-RestMethod -Uri "$baseUrl/monitoring/test-change" -Method Post -ContentType "application/json"
    Write-Host " PASS (change: $($result.priceChange) rub)" -ForegroundColor Green
    $passed++
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    $failed++
}

# Test 6: Check Updates
Write-Host "[6/6] Check Updates..." -NoNewline
try {
    $result = Invoke-RestMethod -Uri "$baseUrl/monitoring/check-updates" -Method Post -ContentType "application/json"
    Write-Host " PASS (processed: $($result.processed))" -ForegroundColor Green
    $passed++
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    $failed++
}

# Summary
$total = $passed + $failed
$rate = [math]::Round(($passed / $total) * 100, 0)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "RESULTS: $passed/$total passed ($rate%)" -ForegroundColor $(if ($rate -eq 100) { "Green" } elseif ($rate -ge 80) { "Yellow" } else { "Red" })
Write-Host "============================================`n" -ForegroundColor Cyan

if ($rate -eq 100) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "$failed test(s) failed" -ForegroundColor Yellow
    exit 1
}
