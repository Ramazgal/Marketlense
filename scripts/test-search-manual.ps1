# Test 4.4: Search Relevance (Manual Helper)
# Provides commands for manual testing

$baseUrl = "http://localhost:3000"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TEST 4.4: SEARCH RELEVANCE (Manual)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Run these commands manually and check results:`n" -ForegroundColor Yellow

# Test 1: Brand search
Write-Host "[Test 1] Brand Search - 'MarketLens'" -ForegroundColor Cyan
Write-Host 'Invoke-RestMethod -Uri "http://localhost:3000/search?query=MarketLens&limit=5" | ForEach-Object { $_.results }' -ForegroundColor White
Write-Host "Expected: All results should be MarketLens brand`n" -ForegroundColor Gray

# Test 2: Electronics category
Write-Host "[Test 2] Category Search - Electronics" -ForegroundColor Cyan
Write-Host 'Invoke-RestMethod -Uri "http://localhost:3000/search?query=наушники&limit=5" | ForEach-Object { $_.results }' -ForegroundColor White
Write-Host "Expected: Results should contain headphones (наушники)`n" -ForegroundColor Gray

# Test 3: Smart home
Write-Host "[Test 3] Product Type - Smart Home" -ForegroundColor Cyan
Write-Host 'Invoke-RestMethod -Uri "http://localhost:3000/search?query=колонка&limit=5" | ForEach-Object { $_.results }' -ForegroundColor White
Write-Host "Expected: Results should be speakers/smart speakers`n" -ForegroundColor Gray

# Test 4: Accessories
Write-Host "[Test 4] Accessories Search" -ForegroundColor Cyan
Write-Host 'Invoke-RestMethod -Uri "http://localhost:3000/search?query=рюкзак&limit=5" | ForEach-Object { $_.results }' -ForegroundColor White
Write-Host "Expected: Results should be backpacks`n" -ForegroundColor Gray

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHECKLIST FOR EACH TEST" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "For each result, verify:" -ForegroundColor White
Write-Host "  [ ] Title matches search query" -ForegroundColor Gray
Write-Host "  [ ] Category is appropriate" -ForegroundColor Gray
Write-Host "  [ ] Brand is correct (if specified)" -ForegroundColor Gray
Write-Host "  [ ] No completely irrelevant items`n" -ForegroundColor Gray

Write-Host "Scoring:" -ForegroundColor Yellow
Write-Host "  3/3 relevant = EXCELLENT (100%)" -ForegroundColor Green
Write-Host "  2/3 relevant = GOOD (67%)" -ForegroundColor Green
Write-Host "  1/3 relevant = POOR (33%)" -ForegroundColor Red
Write-Host "  0/3 relevant = FAIL (0%)`n" -ForegroundColor Red

Write-Host "Pass criteria: At least 2/3 tests with 67%+ precision`n" -ForegroundColor Cyan

# Run actual test
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RUNNING AUTOMATED TESTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = 0
$total = 4

# Test 1: MarketLens brand
Write-Host "[1/4] Testing: MarketLens brand..." -NoNewline
try {
    $r = Invoke-RestMethod -Uri "$baseUrl/search?query=MarketLens&limit=5"
    $relevant = ($r.results | Where-Object { $_.brand -eq "MarketLens" }).Count
    $precision = if ($r.count -gt 0) { [math]::Round(($relevant / $r.count) * 100, 0) } else { 0 }
    
    if ($precision -ge 80) {
        Write-Host " PASS ($precision%)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($precision%)" -ForegroundColor Red
    }
} catch {
    Write-Host " ERROR" -ForegroundColor Red
}

# Test 2: Backpack category
Write-Host "[2/4] Testing: Backpack (rucksack)..." -NoNewline
try {
    $r = Invoke-RestMethod -Uri "$baseUrl/search?query=рюкзак&limit=5"
    $relevant = ($r.results | Where-Object { $_.title -like "*юкзак*" }).Count
    $precision = if ($r.count -gt 0) { [math]::Round(($relevant / $r.count) * 100, 0) } else { 0 }
    
    if ($precision -ge 70) {
        Write-Host " PASS ($precision%)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($precision%)" -ForegroundColor Red
    }
} catch {
    Write-Host " ERROR" -ForegroundColor Red
}

# Test 3: Headphones
Write-Host "[3/4] Testing: Headphones..." -NoNewline
try {
    $r = Invoke-RestMethod -Uri "$baseUrl/search?query=наушники&limit=5"
    $relevant = ($r.results | Where-Object { $_.title -like "*наушник*" }).Count
    $precision = if ($r.count -gt 0) { [math]::Round(($relevant / $r.count) * 100, 0) } else { 0 }
    
    if ($precision -ge 70) {
        Write-Host " PASS ($precision%)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($precision%)" -ForegroundColor Red
    }
} catch {
    Write-Host " ERROR" -ForegroundColor Red
}

# Test 4: Electronics category
Write-Host "[4/4] Testing: Electronics category..." -NoNewline
try {
    $r = Invoke-RestMethod -Uri "$baseUrl/search?query=электроника&limit=5"
    $relevant = ($r.results | Where-Object { $_.category -like "*Электроника*" }).Count
    $precision = if ($r.count -gt 0) { [math]::Round(($relevant / $r.count) * 100, 0) } else { 0 }
    
    if ($precision -ge 60) {
        Write-Host " PASS ($precision%)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " FAIL ($precision%)" -ForegroundColor Red
    }
} catch {
    Write-Host " ERROR" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
$rate = [math]::Round(($passed / $total) * 100, 0)
Write-Host "Results: $passed/$total tests passed ($rate%)" -ForegroundColor $(if ($rate -ge 75) { "Green" } elseif ($rate -ge 50) { "Yellow" } else { "Red" })

if ($rate -ge 75) {
    Write-Host "Status: PASS - Search relevance is good" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Status: FAIL - Search needs improvement" -ForegroundColor Red
    exit 1
}
