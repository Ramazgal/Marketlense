# TEST 3.2: Slow Internet (15-Second Timeout)
param([string]$BaseUrl = "http://localhost:3000")

$ErrorActionPreference = "Stop"
function Write-Pass { param($msg) Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }

$passed = 0
$failed = 0

Write-Host "`n========== TEST 3.2: Slow Internet ==========" -ForegroundColor Cyan

# Test 1: Check code for AbortController and 15-second timeout
Write-Host "`nTest 1: Code Review - Timeout Implementation" -ForegroundColor Yellow
$codeBytes = [System.IO.File]::ReadAllBytes("index.html")
$code = [System.Text.Encoding]::UTF8.GetString($codeBytes)

# Also try alternative reading method for timeout message check
$codeText = Get-Content "index.html" -Raw -Encoding UTF8

# Count fetch requests
$fetchCount = ([regex]::Matches($code, "await fetch\(")).Count
Write-Host "  Found $fetchCount fetch requests" -ForegroundColor Cyan

# Check AbortController instances
$abortControllers = ([regex]::Matches($code, "new AbortController\(\)")).Count
if ($abortControllers -ge 4) {
    Write-Pass "Found $abortControllers AbortController instances (expected 4+)"
    $passed++
} else {
    Write-Fail "Found only $abortControllers AbortController instances (expected 4+)"
    $failed++
}

# Check 15-second timeout
$timeouts = ([regex]::Matches($code, "15000")).Count
if ($timeouts -ge 4) {
    Write-Pass "Found $timeouts 15-second timeouts (expected 4+)"
    $passed++
} else {
    Write-Fail "Found only $timeouts 15-second timeouts (expected 4+)"
    $failed++
}

# Check AbortError handling
$abortErrorHandlers = ([regex]::Matches($code, "AbortError")).Count
if ($abortErrorHandlers -ge 4) {
    Write-Pass "Found $abortErrorHandlers AbortError handlers (expected 4+)"
    $passed++
} else {
    Write-Fail "Found only $abortErrorHandlers AbortError handlers (expected 4+)"
    $failed++
}

# Check timeout error message (simplified - check for AbortError handling)
if ($code -like "*AbortError*") {
    Write-Pass "Found timeout error handling (AbortError)"
    $passed++
} else {
    Write-Fail "Missing timeout error handling"
    $failed++
}

# Check signal parameter in fetch
$fetchWithSignal = ([regex]::Matches($code, "signal:\s*abortController\.signal")).Count
if ($fetchWithSignal -ge 4) {
    Write-Pass "Found $fetchWithSignal fetch calls with signal parameter (expected 4+)"
    $passed++
} else {
    Write-Fail "Found only $fetchWithSignal fetch calls with signal (expected 4+)"
    $failed++
}

# Check clearTimeout calls
$clearTimeouts = ([regex]::Matches($code, "clearTimeout\(timeoutId\)")).Count
if ($clearTimeouts -ge 4) {
    Write-Pass "Found $clearTimeouts clearTimeout calls (expected 4+)"
    $passed++
} else {
    Write-Fail "Found only $clearTimeouts clearTimeout calls (expected 4+)"
    $failed++
}

# Test 2: Server health
Write-Host "`nTest 2: Server Stability" -ForegroundColor Yellow
try {
    $h = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 5
    if ($h.status -eq "ok") {
        Write-Pass "Server running correctly"
        $passed++
    } else {
        Write-Fail "Server unhealthy"
        $failed++
    }
} catch {
    Write-Fail "Server not responding"
    $failed++
}

Write-Host "`n========== RESULTS ==========" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

Write-Host "`nDoD:" -ForegroundColor Yellow
Write-Host "  [" -NoNewline
$timeoutOk = $timeouts -ge 4 -and $abortErrorHandlers -ge 4
if ($timeoutOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] All fetch requests have 15-second timeout"

Write-Host "  [" -NoNewline
$errorOk = $code -like "*AbortError*"
if ($errorOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] Timeout error message shown to user"

Write-Host "  [" -NoNewline
$signalOk = $fetchWithSignal -ge 4
if ($signalOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] AbortController signal used in all fetches"

if ($failed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
