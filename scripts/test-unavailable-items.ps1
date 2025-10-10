# TEST 4.5: Live Monitoring - Unavailable Items
# Checks correct handling of unavailable competitor products

param(
    [string]$BaseUrl = "http://localhost:3000"
)

$ErrorActionPreference = "Stop"

# Console output functions
function Write-Success { param($msg) Write-Host "[PASS] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Step { param($msg) Write-Host "`n[STEP] $msg" -ForegroundColor Yellow }

$testsPassed = 0
$testsFailed = 0
$testResults = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [scriptblock]$TestBlock
    )
    
    try {
        Write-Info "Test: $Name"
        $result = & $TestBlock
        
        if ($result.success) {
            Write-Success $result.message
            $script:testsPassed++
            $script:testResults += [PSCustomObject]@{
                Test = $Name
                Status = "PASS"
                Message = $result.message
            }
        } else {
            Write-Fail $result.message
            $script:testsFailed++
            $script:testResults += [PSCustomObject]@{
                Test = $Name
                Status = "FAIL"
                Message = $result.message
            }
        }
    } catch {
        Write-Fail "Exception: $($_.Exception.Message)"
        $script:testsFailed++
        $script:testResults += [PSCustomObject]@{
            Test = $Name
            Status = "ERROR"
            Message = $_.Exception.Message
        }
    }
}

Write-Host @"
==================================================================
  TEST 4.5: Live Monitoring (Unavailable Items Detection)
==================================================================
"@ -ForegroundColor Magenta

# ====================================================================
# STEP 1: Server Health Check
# ====================================================================

Write-Step "STEP 1: Server health check"

Test-Endpoint "Health Check" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 5
        
        if ($response.status -eq "ok") {
            return @{ success = $true; message = "Server is available" }
        } else {
            return @{ success = $false; message = "Unexpected status: $($response.status)" }
        }
    } catch {
        return @{ success = $false; message = "Server unavailable: $_" }
    }
}

# ====================================================================
# STEP 2: Add item with broken URL
# ====================================================================

Write-Step "STEP 2: Adding item with broken URL"

$brokenUrl = "https://www.ozon.ru/product/nonexistent-item-999999999"
$itemId = $null

Test-Endpoint "Add monitoring item" {
    try {
        $body = @{
            productUrl = $brokenUrl
            marketplace = "ozon"
            notes = "Unavailability test"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring/add" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 10
        
        $script:itemId = $response.item.id
        
        if ($script:itemId) {
            return @{ 
                success = $true
                message = "Item added (ID: $script:itemId)"
            }
        } else {
            return @{ success = $false; message = "Failed to add item - no ID returned" }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

Write-Info "Waiting for parser to process the item..."
Start-Sleep -Seconds 3

# ====================================================================
# STEP 3: Check updates (item should become unavailable)
# ====================================================================

Write-Step "STEP 3: Checking for updates"

Test-Endpoint "Call /monitoring/check-updates" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring/check-updates" `
            -Method Post `
            -ContentType "application/json" `
            -TimeoutSec 30
        
        if ($response.PSObject.Properties.Name -contains "unavailable") {
            return @{ 
                success = $true
                message = "Endpoint returned 'unavailable' field"
            }
        } else {
            return @{ 
                success = $false
                message = "Response missing 'unavailable' field"
            }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

Test-Endpoint "Check unavailableCount > 0" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring/check-updates" `
            -Method Post `
            -ContentType "application/json" `
            -TimeoutSec 30
        
        if ($response.unavailableCount -gt 0) {
            return @{ 
                success = $true
                message = "Unavailable items found: $($response.unavailableCount)"
            }
        } else {
            return @{ 
                success = $false
                message = "unavailableCount = 0 (expected > 0)"
            }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

Test-Endpoint "Verify unavailable item data" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring/check-updates" `
            -Method Post `
            -ContentType "application/json" `
            -TimeoutSec 30
        
        $unavailableItem = $response.unavailable | Where-Object { $_.id -eq $script:itemId } | Select-Object -First 1
        
        if ($unavailableItem) {
            $hasTitle = $unavailableItem.PSObject.Properties.Name -contains "title"
            $hasUrl = $unavailableItem.PSObject.Properties.Name -contains "url"
            $hasReason = $unavailableItem.PSObject.Properties.Name -contains "reason"
            
            if ($hasTitle -and $hasUrl -and $hasReason) {
                return @{ 
                    success = $true
                    message = "Item contains all fields (title, url, reason)"
                }
            } else {
                $missing = @()
                if (-not $hasTitle) { $missing += "title" }
                if (-not $hasUrl) { $missing += "url" }
                if (-not $hasReason) { $missing += "reason" }
                
                return @{ 
                    success = $false
                    message = "Missing fields: $($missing -join ', ')"
                }
            }
        } else {
            return @{ 
                success = $false
                message = "Item with ID $script:itemId not found in unavailable[]"
            }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

# ====================================================================
# STEP 4: Verify item status
# ====================================================================

Write-Step "STEP 4: Verifying item status"

Test-Endpoint "Item status changed to 'unavailable'" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring" `
            -Method Get `
            -TimeoutSec 10
        
        $item = $response.items | Where-Object { $_.id -eq $script:itemId } | Select-Object -First 1
        
        if ($item -and $item.status -eq "unavailable") {
            return @{ 
                success = $true
                message = "Status is correct: unavailable"
            }
        } elseif ($item) {
            return @{ 
                success = $false
                message = "Unexpected status: $($item.status) (expected 'unavailable')"
            }
        } else {
            return @{ 
                success = $false
                message = "Item not found in monitoring list"
            }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

Test-Endpoint "Check unavailableSince field exists" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring" `
            -Method Get `
            -TimeoutSec 10
        
        $item = $response.items | Where-Object { $_.id -eq $script:itemId } | Select-Object -First 1
        
        if ($item -and $item.PSObject.Properties.Name -contains "unavailableSince") {
            return @{ 
                success = $true
                message = "Field unavailableSince exists: $($item.unavailableSince)"
            }
        } else {
            return @{ 
                success = $false
                message = "Field unavailableSince is missing"
            }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

# ====================================================================
# STEP 5: Cleanup (delete test item)
# ====================================================================

Write-Step "STEP 5: Cleanup"

Test-Endpoint "Delete test item" {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/monitoring/$script:itemId" `
            -Method Delete `
            -TimeoutSec 10
        
        if ($response.id -eq $script:itemId) {
            return @{ 
                success = $true
                message = "Item deleted (ID: $script:itemId)"
            }
        } else {
            return @{ success = $false; message = "Failed to delete item - unexpected response" }
        }
    } catch {
        return @{ success = $false; message = "Error: $_" }
    }
}

# ====================================================================
# RESULTS
# ====================================================================

Write-Host "`n`n==================================================================" -ForegroundColor Magenta
Write-Host "                         TEST RESULTS                             " -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta

$testResults | Format-Table -AutoSize

$total = $testsPassed + $testsFailed
$percentage = if ($total -gt 0) { [math]::Round(($testsPassed / $total) * 100, 1) } else { 0 }

Write-Host "`nStatistics:" -ForegroundColor Cyan
Write-Host "   Passed:  " -NoNewline; Write-Host $testsPassed -ForegroundColor Green
Write-Host "   Failed:  " -NoNewline; Write-Host $testsFailed -ForegroundColor Red
Write-Host "   Total:   $total"
Write-Host "   Success: $percentage%"

if ($testsFailed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
