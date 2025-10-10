# TEST 3.1: Nervous User (Button Disabling)
param([string]$BaseUrl = "http://localhost:3000")

$ErrorActionPreference = "Stop"
function Write-Pass { param($msg) Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }

$passed = 0
$failed = 0

Write-Host "`n========== TEST 3.1: Nervous User ==========" -ForegroundColor Cyan

# Test 1: Check code for button disabling
Write-Host "`nTest 1: Code Review - Button Disabling Logic" -ForegroundColor Yellow
$codeBytes = [System.IO.File]::ReadAllBytes("index.html")
$code = [System.Text.Encoding]::UTF8.GetString($codeBytes)

# Check analyze button
if ($code -match "analyzeButton\)\s+analyzeButton\.disabled\s*=\s*true") {
    Write-Pass "Analyze button: disabled = true at start"
    $passed++
} else {
    Write-Fail "Analyze button: missing disabled = true"
    $failed++
}

if ($code -match "finally\s*\{[\s\S]{0,200}analyzeButton\.disabled\s*=\s*false") {
    Write-Pass "Analyze button: disabled = false in finally"
    $passed++
} else {
    Write-Fail "Analyze button: missing disabled = false in finally"
    $failed++
}

# Check search button
if ($code -match "searchButton\)\s+searchButton\.disabled\s*=\s*true") {
    Write-Pass "Search button: disabled = true at start"
    $passed++
} else {
    Write-Fail "Search button: missing disabled = true"
    $failed++
}

if ($code -match "finally\s*\{[\s\S]{0,200}searchButton\.disabled\s*=\s*false") {
    Write-Pass "Search button: disabled = false in finally"
    $passed++
} else {
    Write-Fail "Search button: missing disabled = false in finally"
    $failed++
}

# Check monitoring button
if ($code -match "monitoringButton\)\s+monitoringButton\.disabled\s*=\s*true") {
    Write-Pass "Monitoring button: disabled = true at start"
    $passed++
} else {
    Write-Fail "Monitoring button: missing disabled = true"
    $failed++
}

if ($code -match "finally\s*\{[\s\S]{0,200}monitoringButton\.disabled\s*=\s*false") {
    Write-Pass "Monitoring button: disabled = false in finally"
    $passed++
} else {
    Write-Fail "Monitoring button: missing disabled = false in finally"
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
$analyzeOk = $code -match "analyzeButton\.disabled\s*=\s*true" -and $code -match "analyzeButton\.disabled\s*=\s*false"
if ($analyzeOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] Analyze button disabled during request"

Write-Host "  [" -NoNewline
$searchOk = $code -match "searchButton\.disabled\s*=\s*true" -and $code -match "searchButton\.disabled\s*=\s*false"
if ($searchOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] Search button disabled during request"

Write-Host "  [" -NoNewline
$monitoringOk = $code -match "monitoringButton\.disabled\s*=\s*true" -and $code -match "monitoringButton\.disabled\s*=\s*false"
if ($monitoringOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "X" -NoNewline -ForegroundColor Red }
Write-Host "] Monitoring button disabled during request"

if ($failed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
