$ErrorActionPreference = 'Stop'

Write-Host "=== Test URL validation in /analyze ===" -ForegroundColor Cyan

# Start server
$serverProcess = Start-Process node -ArgumentList 'server.js' -WorkingDirectory 'C:\Marketlense' -PassThru -WindowStyle Hidden

try {
    # Wait for server startup
    Write-Host "Waiting for server..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3

    # Health check
    try {
        $health = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/health' -TimeoutSec 5
        Write-Host "Server is up: $($health.status)" -ForegroundColor Green
    } catch {
        Write-Host "Server unavailable" -ForegroundColor Red
        throw
    }

    # Test 1: Invalid URL (Ozon homepage)
    Write-Host "`nTest 1: Ozon homepage (should return 400)" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/analyze?url=https://www.ozon.ru&marketplace=ozon' -TimeoutSec 5
        Write-Host "FAILED: Expected 400 error, but request succeeded" -ForegroundColor Red
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 400) {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "PASSED: Status $statusCode, error: $($errorBody.error)" -ForegroundColor Green
        } else {
            Write-Host "FAILED: Unexpected status $statusCode" -ForegroundColor Red
        }
    }

    # Test 2: Invalid URL (Wildberries homepage)
    Write-Host "`nTest 2: Wildberries homepage (should return 400)" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/analyze?url=https://www.wildberries.ru&marketplace=wildberries' -TimeoutSec 5
        Write-Host "FAILED: Expected 400 error, but request succeeded" -ForegroundColor Red
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 400) {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "PASSED: Status $statusCode, error: $($errorBody.error)" -ForegroundColor Green
        } else {
            Write-Host "FAILED: Unexpected status $statusCode" -ForegroundColor Red
        }
    }

    # Test 3: Valid product URL
    Write-Host "`nTest 3: Valid Ozon product URL (should process)" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/analyze?url=https://www.ozon.ru/product/test-123&marketplace=ozon' -TimeoutSec 10
        if ($response.marketplace -eq 'ozon') {
            Write-Host "PASSED: Request processed, marketplace: $($response.marketplace)" -ForegroundColor Green
        } else {
            Write-Host "FAILED: Unexpected response" -ForegroundColor Red
        }
    } catch {
        Write-Host "FAILED: Error processing valid URL" -ForegroundColor Red
    }

    Write-Host "`n=== Tests completed ===" -ForegroundColor Cyan

} finally {
    # Stop server
    if ($serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force
        Write-Host "`nServer stopped." -ForegroundColor Gray
    }
}

