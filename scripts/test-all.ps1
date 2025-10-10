# ========================================
# MARKETLENSE - COMPREHENSIVE TEST SUITE
# ========================================
# Запуск всех тестов для проверки функционала

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:3000"

# Цвета для вывода
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ $msg" -ForegroundColor Cyan }
function Write-Section { param($msg) Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow; Write-Host "  $msg" -ForegroundColor Yellow; Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Yellow }

$passedTests = 0
$failedTests = 0
$totalTests = 0

# ========================================
# TEST 1: Server Health Check
# ========================================
Write-Section "TEST 1: Health Check"
$totalTests++

try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 5
    if ($health.status -eq "ok") {
        Write-Success "Server is running"
        $passedTests++
    } else {
        Write-Fail "Server returned wrong status: $($health.status)"
        $failedTests++
    }
} catch {
    Write-Fail "Server not responding: $_"
    $failedTests++
    Write-Host "`nRemaining tests skipped (server not running)" -ForegroundColor Red
    exit 1
}

# ========================================
# TEST 2: Code Linting
# ========================================
Write-Section "TEST 2: Code Quality (ESLint)"
$totalTests++

try {
    $lintOutput = npm run lint 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Linter passed with no errors"
        $passedTests++
    } else {
        Write-Fail "Linting errors detected"
        $failedTests++
        Write-Host $lintOutput -ForegroundColor Gray
    }
} catch {
    Write-Fail "Linter error: $_"
    $failedTests++
}

# ========================================
# TEST 3: Smoke Test (main endpoints)
# ========================================
Write-Section "TEST 3: Smoke Test"
$totalTests++

try {
    $smokeOutput = powershell -File scripts/smoke-test.ps1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Smoke test passed"
        $passedTests++
        Write-Info "Checked: /analyze, /search, /monitoring"
    } else {
        Write-Fail "Smoke test failed"
        $failedTests++
    }
} catch {
    Write-Fail "Smoke test error: $_"
    $failedTests++
}

# ========================================
# TEST 4.1: Price Monitoring
# ========================================
Write-Section "TEST 4.1: Price Monitoring"

# Подтест 4.1.1: Получение списка
$totalTests++
try {
    $monList = Invoke-RestMethod -Uri "$baseUrl/monitoring" -Method Get
    Write-Success "Got monitoring list (items: $($monList.items.Count))"
    $passedTests++
} catch {
    Write-Fail "Failed to get monitoring list: $_"
    $failedTests++
}

# Subtest 4.1.2: Add item
$totalTests++
try {
    $newItem = @{
        marketplace = "ozon"
        productUrl = "https://www.ozon.ru/product/test-$(Get-Random)"
        notes = "Autotest $(Get-Date -Format 'HH:mm:ss')"
    } | ConvertTo-Json
    
    $addResult = Invoke-RestMethod -Uri "$baseUrl/monitoring/add" -Method Post -Body $newItem -ContentType "application/json"
    Write-Success "Item added to monitoring (ID: $($addResult.item.id))"
    $passedTests++
    $testItemId = $addResult.item.id
} catch {
    Write-Fail "Failed to add item: $_"
    $failedTests++
}

# Subtest 4.1.3: Price change simulation
$totalTests++
try {
    $changeResult = Invoke-RestMethod -Uri "$baseUrl/monitoring/test-change" -Method Post -ContentType "application/json"
    Write-Success "Price change simulation completed"
    Write-Info "Change: $($changeResult.priceChange) rub ($($changeResult.changePercent)%)"
    $passedTests++
} catch {
    Write-Fail "Failed to simulate price change: $_"
    $failedTests++
}

# Subtest 4.1.4: Check updates
$totalTests++
try {
    $updateResult = Invoke-RestMethod -Uri "$baseUrl/monitoring/check-updates" -Method Post -ContentType "application/json"
    Write-Success "Updates check completed"
    Write-Info "Processed: $($updateResult.processed) | Changes: $($updateResult.changesDetected)"
    $passedTests++
} catch {
    Write-Fail "Failed to check updates: $_"
    $failedTests++
}

# ========================================
# TEST 5: Input Validation
# ========================================
Write-Section "TEST 5: Input Validation"

# Subtest 5.1: Invalid URL
$totalTests++
try {
    $result = powershell -File scripts/test-validation.ps1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Invalid URL validation works"
        $passedTests++
    } else {
        Write-Fail "Validation test failed"
        $failedTests++
    }
} catch {
    Write-Fail "Validation test error: $_"
    $failedTests++
}

# Subtest 5.2: Empty data
$totalTests++
try {
    $result = powershell -File scripts/test-empty-data.ps1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Empty data handling works"
        $passedTests++
    } else {
        Write-Fail "Empty data test failed"
        $failedTests++
    }
} catch {
    Write-Fail "Empty data test error: $_"
    $failedTests++
}

# ========================================
# TEST 6: Timeouts (15 seconds)
# ========================================
Write-Section "TEST 6: Timeouts"
$totalTests++

Write-Info "Running timeout test (takes ~15 seconds)..."
try {
    $result = powershell -File scripts/test-timeout-simple.ps1 2>&1
    if ($result -match "timeout|exceeded|15 seconds") {
        Write-Success "15 second timeout works correctly"
        $passedTests++
    } else {
        Write-Fail "Timeout did not trigger properly"
        $failedTests++
    }
} catch {
    Write-Fail "Timeout test error: $_"
    $failedTests++
}

# ========================================
# FINAL REPORT
# ========================================
Write-Section "TEST RESULTS SUMMARY"

$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Passed:      " -NoNewline; Write-Host "$passedTests/$totalTests" -ForegroundColor Green
Write-Host "Failed:      " -NoNewline; Write-Host "$failedTests/$totalTests" -ForegroundColor Red
Write-Host "Success Rate:" -NoNewline; Write-Host "$successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

Write-Host ""

if ($successRate -eq 100) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host "Most tests passed, but some issues found" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "CRITICAL ISSUES DETECTED" -ForegroundColor Red
    exit 1
}
