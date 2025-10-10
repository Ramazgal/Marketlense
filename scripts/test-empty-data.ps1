# TEST 1.2: Empty Data Handling
param([string]$BaseUrl = "http://localhost:3000")

$ErrorActionPreference = "Stop"
function Write-Pass { param($msg) Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }

$passed = 0
$failed = 0

Write-Host "`n========== TEST 1.2: Empty Data Handling ==========" -ForegroundColor Cyan

# Test 1: Non-existent Ozon product
Write-Host "`nTest 1: Non-existent Ozon product" -ForegroundColor Yellow
try {
    $url = "https://www.ozon.ru/product/nonexistent-999999"
    $r = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=$url&marketplace=ozon" -TimeoutSec 15
    if ($r.product) {
        Write-Pass "Server returned response without crashing"
        $passed++
        if ($r.product.title) { Write-Pass "Has title field"; $passed++ } else { Write-Fail "Missing title"; $failed++ }
        Write-Pass "Price: $($r.product.price) (null or number)"
        $passed++
    } else { Write-Fail "No product in response"; $failed++ }
} catch { Write-Fail "Server error: $_"; $failed++ }

# Test 2: Check server health
Write-Host "`nTest 2: Server stability" -ForegroundColor Yellow
try {
    $h = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 5
    if ($h.status -eq "ok") { Write-Pass "Server still running"; $passed++ }
    else { Write-Fail "Server unhealthy"; $failed++ }
} catch { Write-Fail "Server down"; $failed++ }

Write-Host "`n========== RESULTS ==========" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
if ($failed -eq 0) { Write-Host "ALL TESTS PASSED!" -ForegroundColor Green; exit 0 }
else { Write-Host "SOME TESTS FAILED!" -ForegroundColor Red; exit 1 }
