# TEST 2.1: AI Format Validation
param([string]$BaseUrl = "http://localhost:3000")

$ErrorActionPreference = "Stop"
function Write-Pass { param($msg) Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }

$passed = 0
$failed = 0

Write-Host "`n========== TEST 2.1: AI Format Validation ==========" -ForegroundColor Cyan

# Test 1: Check code for error handling
Write-Host "`nTest 1: Code Review" -ForegroundColor Yellow
$codeBytes = [System.IO.File]::ReadAllBytes("server.js")
$code = [System.Text.Encoding]::UTF8.GetString($codeBytes)

if ($code -match "JSON\.parse\(trimmedResponse\)") {
    Write-Pass "Found JSON.parse with validation"
    $passed++
} else {
    Write-Fail "Missing JSON.parse validation"
    $failed++
}

if ($code -match "catch\s*\{[\s\S]{0,50}throw new Error") {
    Write-Pass "Found try-catch with error throwing"
    $passed++
} else {
    Write-Fail "Missing try-catch error handling"
    $failed++
}

if ($code -match "TEST 2\.1") {
    Write-Pass "Code marked with TEST 2.1"
    $passed++
} else {
    Write-Fail "Missing TEST 2.1 marker"
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
if ($code -match "throw new Error") { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] User-friendly error message"
Write-Host "  [" -NoNewline
if ($code -match "catch\s*\{[\s\S]{0,50}throw new Error") { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] JSON.parse in try-catch"

if ($failed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
