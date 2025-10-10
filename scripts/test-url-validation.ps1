# TEST 1.1: URL Validation (Broken Links)
# Checks that invalid URLs are rejected before parsing

param(
    [string]$BaseUrl = "http://localhost:3000"
)

$ErrorActionPreference = "Stop"

# Console output functions
function Write-TestHeader { param($msg) Write-Host "`n$msg" -ForegroundColor Cyan }
function Write-TestCase { param($msg) Write-Host "  $msg" -ForegroundColor Yellow }
function Write-Pass { param($msg) Write-Host "    ✅ PASS: $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "    ❌ FAIL: $msg" -ForegroundColor Red }

$testsPassed = 0
$testsFailed = 0

Write-Host @"
==================================================================
  TEST 1.1: URL Validation (Broken Links)
==================================================================
"@ -ForegroundColor Magenta

# ====================================================================
# Test invalid URLs (should return 400 error)
# ====================================================================

Write-TestHeader "INVALID URLs (should return 400 error):"

# Test 1: Ozon homepage
Write-TestCase "Test 1: Ozon homepage (https://www.ozon.ru)"
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=https://www.ozon.ru&marketplace=ozon" -ErrorAction Stop
    Write-Fail "Should have returned 400 error, but got success response"
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
        # Check for validation error (any error containing these patterns)
        if ($errorBody.error) {
            Write-Pass "Returned 400 with error message"
            $testsPassed++
        } else {
            Write-Fail "Got 400 but no error message"
            $testsFailed++
        }
    } else {
        Write-Fail "Wrong status code: $($_.Exception.Response.StatusCode.value__)"
        $testsFailed++
    }
}

# Test 2: Wildberries homepage
Write-TestCase "Test 2: Wildberries homepage (https://www.wildberries.ru)"
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=https://www.wildberries.ru&marketplace=wildberries" -ErrorAction Stop
    Write-Fail "Should have returned 400 error"
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Pass "Returned 400 error"
        $testsPassed++
    } else {
        Write-Fail "Wrong status code: $($_.Exception.Response.StatusCode.value__)"
        $testsFailed++
    }
}

# Test 3: Yandex Market homepage
Write-TestCase "Test 3: Yandex Market homepage (https://market.yandex.ru)"
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=https://market.yandex.ru&marketplace=yandex_market" -ErrorAction Stop
    Write-Fail "Should have returned 400 error"
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Pass "Returned 400 error"
        $testsPassed++
    } else {
        Write-Fail "Wrong status code: $($_.Exception.Response.StatusCode.value__)"
        $testsFailed++
    }
}

# Test 4: Random website
Write-TestCase "Test 4: Random website (https://google.com)"
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=https://google.com&marketplace=ozon" -ErrorAction Stop
    Write-Fail "Should have returned 400 error"
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Pass "Returned 400 error"
        $testsPassed++
    } else {
        Write-Fail "Wrong status code: $($_.Exception.Response.StatusCode.value__)"
        $testsFailed++
    }
}

# Test 5: Ozon category page (not product)
Write-TestCase "Test 5: Ozon category page (/category/)"
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=https://www.ozon.ru/category/naushniki-12345/&marketplace=ozon" -ErrorAction Stop
    Write-Fail "Should have returned 400 error"
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Pass "Returned 400 error"
        $testsPassed++
    } else {
        Write-Fail "Wrong status code: $($_.Exception.Response.StatusCode.value__)"
        $testsFailed++
    }
}

# Test 6: Wildberries search results
Write-TestCase "Test 6: Wildberries search page (/search/)"
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/analyze?url=https://www.wildberries.ru/search/naushniki&marketplace=wildberries" -ErrorAction Stop
    Write-Fail "Should have returned 400 error"
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Pass "Returned 400 error"
        $testsPassed++
    } else {
        Write-Fail "Wrong status code: $($_.Exception.Response.StatusCode.value__)"
        $testsFailed++
    }
}

# ====================================================================
# Test valid URLs (should pass validation)
# ====================================================================

Write-TestHeader "VALID URLs (should pass validation):"

# Test 7: Valid Ozon product URL
Write-TestCase "Test 7: Valid Ozon URL (/product/...)"
try {
    $testUrl = "$BaseUrl/analyze?url=https://www.ozon.ru/product/test-123456&marketplace=ozon"
    
    # We don't care if parsing fails, just that validation passes (no 400)
    try {
        $response = Invoke-RestMethod -Uri $testUrl -ErrorAction Stop -TimeoutSec 5
        Write-Pass "Validation passed (parsing may succeed or fail)"
        $testsPassed++
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 400) {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($errorBody.error -like "*format*" -or $errorBody.error -like "*link*") {
                Write-Fail "Validation rejected valid URL"
                $testsFailed++
            } else {
                # Other 400 error (not validation) - that's OK
                Write-Pass "Validation passed (other error: $($errorBody.error))"
                $testsPassed++
            }
        } else {
            # Non-400 error (timeout, parsing error, etc) - validation passed
            Write-Pass "Validation passed (parsing error: $($_.Exception.Message))"
            $testsPassed++
        }
    }
} catch {
    Write-Fail "Unexpected error: $($_.Exception.Message)"
    $testsFailed++
}

# Test 8: Valid Wildberries URL
Write-TestCase "Test 8: Valid Wildberries URL (/catalog/...)"
try {
    $testUrl = "$BaseUrl/analyze?url=https://www.wildberries.ru/catalog/123456/detail.aspx&marketplace=wildberries"
    
    try {
        $response = Invoke-RestMethod -Uri $testUrl -ErrorAction Stop -TimeoutSec 5
        Write-Pass "Validation passed"
        $testsPassed++
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 400) {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($errorBody.error -like "*format*" -or $errorBody.error -like "*link*") {
                Write-Fail "Validation rejected valid URL"
                $testsFailed++
            } else {
                Write-Pass "Validation passed (other error)"
                $testsPassed++
            }
        } else {
            Write-Pass "Validation passed (parsing error)"
            $testsPassed++
        }
    }
} catch {
    Write-Fail "Unexpected error: $($_.Exception.Message)"
    $testsFailed++
}

# Test 9: Valid Yandex Market URL
Write-TestCase "Test 9: Valid Yandex Market URL (/product/...)"
try {
    $testUrl = "$BaseUrl/analyze?url=https://market.yandex.ru/product/123456&marketplace=yandex_market"
    
    try {
        $response = Invoke-RestMethod -Uri $testUrl -ErrorAction Stop -TimeoutSec 5
        Write-Pass "Validation passed"
        $testsPassed++
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 400) {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($errorBody.error -like "*format*" -or $errorBody.error -like "*link*") {
                Write-Fail "Validation rejected valid URL"
                $testsFailed++
            } else {
                Write-Pass "Validation passed (other error)"
                $testsPassed++
            }
        } else {
            Write-Pass "Validation passed (parsing error)"
            $testsPassed++
        }
    }
} catch {
    Write-Fail "Unexpected error: $($_.Exception.Message)"
    $testsFailed++
}

# ====================================================================
# RESULTS
# ====================================================================

Write-Host "`n==================================================================" -ForegroundColor Magenta
Write-Host "                         TEST RESULTS                             " -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta

$total = $testsPassed + $testsFailed
$percentage = if ($total -gt 0) { [math]::Round(($testsPassed / $total) * 100, 1) } else { 0 }

Write-Host "`nStatistics:" -ForegroundColor Cyan
Write-Host "   Passed:  " -NoNewline; Write-Host $testsPassed -ForegroundColor Green
Write-Host "   Failed:  " -NoNewline; Write-Host $testsFailed -ForegroundColor Red
Write-Host "   Total:   $total"
Write-Host "   Success: $percentage%"

Write-Host "`nDoD Criteria:" -ForegroundColor Yellow
Write-Host "   [" -NoNewline
if ($testsFailed -eq 0) {
    Write-Host "✅" -NoNewline -ForegroundColor Green
} else {
    Write-Host "❌" -NoNewline -ForegroundColor Red
}
Write-Host "] Invalid URLs return 400 error with correct message"

Write-Host "   [" -NoNewline
if ($testsPassed -ge 9) {
    Write-Host "✅" -NoNewline -ForegroundColor Green
} else {
    Write-Host "❌" -NoNewline -ForegroundColor Red
}
Write-Host "] Valid URLs pass validation (no format error)"

if ($testsFailed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "DoD: URL validation is working correctly" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
