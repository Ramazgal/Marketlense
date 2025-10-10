# Test 4.4: Search Relevance
# Tests search accuracy with predefined queries

$baseUrl = "http://localhost:3000"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TEST 4.4: SEARCH RELEVANCE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "This test checks search accuracy with 3 test cases:" -ForegroundColor White
Write-Host "  1. Brand-specific query (MarketLens)" -ForegroundColor Gray
Write-Host "  2. Category query (electronics)" -ForegroundColor Gray
Write-Host "  3. Product type query (smart home)`n" -ForegroundColor Gray

$totalTests = 0
$passedTests = 0

# Test Case 1: Brand-specific search
Write-Host "[Test 1/3] Brand search: 'MarketLens'..." -ForegroundColor Cyan
$totalTests++

try {
    $results = Invoke-RestMethod -Uri "$baseUrl/search?query=MarketLens&limit=5"
    
    Write-Host "  Found: $($results.count) results" -ForegroundColor White
    
    $relevantCount = 0
    foreach ($item in $results.results) {
        $isRelevant = $item.brand -eq "MarketLens" -or $item.title -like "*MarketLens*"
        if ($isRelevant) { $relevantCount++ }
        
        $statusIcon = if ($isRelevant) { "[OK]" } else { "[!!]" }
        $statusColor = if ($isRelevant) { "Green" } else { "Red" }
        
        Write-Host "  $statusIcon $($item.title)" -ForegroundColor $statusColor -NoNewline
        Write-Host " ($($item.brand))" -ForegroundColor Gray
    }
    
    $precision = if ($results.count -gt 0) { [math]::Round(($relevantCount / $results.count) * 100, 0) } else { 0 }
    
    Write-Host "`n  Precision: $precision% ($relevantCount/$($results.count) relevant)" -ForegroundColor $(if ($precision -ge 80) { "Green" } else { "Yellow" })
    
    if ($precision -ge 80) {
        Write-Host "  Result: PASS`n" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Result: FAIL (expected >= 80%)`n" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  ERROR: $_`n" -ForegroundColor Red
}

# Test Case 2: Category search
Write-Host "[Test 2/3] Category search: 'умный дом'..." -ForegroundColor Cyan
$totalTests++

try {
    $results = Invoke-RestMethod -Uri "$baseUrl/search?query=умный+дом&limit=5"
    
    Write-Host "  Found: $($results.count) results" -ForegroundColor White
    
    $relevantCount = 0
    foreach ($item in $results.results) {
        $isRelevant = $item.category -like "*Умный дом*" -or 
                      $item.category -like "*Электроника*" -or
                      $item.title -like "*умн*"
        
        if ($isRelevant) { $relevantCount++ }
        
        $statusIcon = if ($isRelevant) { "[OK]" } else { "[!!]" }
        $statusColor = if ($isRelevant) { "Green" } else { "Red" }
        
        Write-Host "  $statusIcon $($item.title)" -ForegroundColor $statusColor -NoNewline
        Write-Host " ($($item.category))" -ForegroundColor Gray
    }
    
    $precision = if ($results.count -gt 0) { [math]::Round(($relevantCount / $results.count) * 100, 0) } else { 0 }
    
    Write-Host "`n  Precision: $precision% ($relevantCount/$($results.count) relevant)" -ForegroundColor $(if ($precision -ge 60) { "Green" } else { "Yellow" })
    
    if ($precision -ge 60) {
        Write-Host "  Result: PASS`n" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Result: FAIL (expected >= 60%)`n" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  ERROR: $_`n" -ForegroundColor Red
}

# Test Case 3: Product type search
Write-Host "[Test 3/3] Product search: 'наушники'..." -ForegroundColor Cyan
$totalTests++

try {
    $results = Invoke-RestMethod -Uri "$baseUrl/search?query=наушники&limit=5"
    
    Write-Host "  Found: $($results.count) results" -ForegroundColor White
    
    $relevantCount = 0
    foreach ($item in $results.results) {
        $isRelevant = $item.title -like "*наушник*" -or 
                      $item.title -like "*headphone*" -or
                      $item.category -like "*Электроника*"
        
        if ($isRelevant) { $relevantCount++ }
        
        $statusIcon = if ($isRelevant) { "[OK]" } else { "[!!]" }
        $statusColor = if ($isRelevant) { "Green" } else { "Red" }
        
        Write-Host "  $statusIcon $($item.title)" -ForegroundColor $statusColor -NoNewline
        Write-Host " ($($item.category))" -ForegroundColor Gray
    }
    
    $precision = if ($results.count -gt 0) { [math]::Round(($relevantCount / $results.count) * 100, 0) } else { 0 }
    
    Write-Host "`n  Precision: $precision% ($relevantCount/$($results.count) relevant)" -ForegroundColor $(if ($precision -ge 70) { "Green" } else { "Yellow" })
    
    if ($precision -ge 70) {
        Write-Host "  Result: PASS`n" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Result: FAIL (expected >= 70%)`n" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  ERROR: $_`n" -ForegroundColor Red
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SEARCH RELEVANCE TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 0) } else { 0 }

Write-Host "Passed: $passedTests/$totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "Success Rate: $successRate%`n" -ForegroundColor $(if ($successRate -ge 67) { "Green" } elseif ($successRate -ge 50) { "Yellow" } else { "Red" })

if ($successRate -ge 67) {
    Write-Host "Status: PASS - Search relevance is acceptable" -ForegroundColor Green
    Write-Host "Note: 2/3 tests passed (minimum requirement)`n" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "Status: FAIL - Search needs improvement" -ForegroundColor Red
    Write-Host "Recommendations:" -ForegroundColor Yellow
    Write-Host "  1. Implement ranking by match score" -ForegroundColor White
    Write-Host "  2. Add synonym support" -ForegroundColor White
    Write-Host "  3. Consider fuzzy matching`n" -ForegroundColor White
    exit 1
}
