# Test 4.2: AI Expert Review - Automated Test Runner

Write-Host "`n=== TEST 4.2: AI EXPERT REVIEW ===`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:3000"
$results = @()

# Check server
try {
    Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing -ErrorAction Stop | Out-Null
    Write-Host "[OK] Server is running`n" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Server not running. Start with: npm start" -ForegroundColor Red
    exit 1
}

# Scenario 1: High Price, Low Rating
Write-Host "SCENARIO 1: High Price + Low Rating" -ForegroundColor Yellow
Write-Host "Product: Smart Robot Vacuum 45,000 RUB, 3.8 stars, 87 reviews" -ForegroundColor Gray

$scenario1 = @{
    userEvidence = @(
        "Smart Robot Vacuum XYZ-3000, 45000 RUB",
        "Rating 3.8 stars with 87 reviews",
        "Features: advanced navigation, self-emptying, voice control",
        "Premium build quality with 2-year warranty"
    )
    competitorEvidence = @(
        "Competitor A: 32000 RUB, 4.7 stars, 456 reviews",
        "Competitor B: 28500 RUB, 4.5 stars, 789 reviews",
        "Competitor C: 35000 RUB, 4.6 stars, 234 reviews"
    )
} | ConvertTo-Json -Depth 10

try {
    $response1 = Invoke-RestMethod -Uri "$baseUrl/strategize" -Method POST -ContentType "application/json" -Body $scenario1
    Write-Host "[OK] AI response received" -ForegroundColor Green
    Write-Host "Strategy length: $($response1.strategy.Length) characters`n" -ForegroundColor Gray
    
    $results += [PSCustomObject]@{
        Scenario = "High Price, Low Rating"
        Success = $true
        StrategyLength = $response1.strategy.Length
        Strategy = $response1.strategy
    }
} catch {
    Write-Host "[FAIL] Error: $_`n" -ForegroundColor Red
    $results += [PSCustomObject]@{
        Scenario = "High Price, Low Rating"
        Success = $false
        Error = $_.Exception.Message
    }
}

# Scenario 2: Good Price, Excellent Rating, Low Visibility
Write-Host "SCENARIO 2: Good Price + Excellent Rating + Low Visibility" -ForegroundColor Yellow
Write-Host "Product: Wireless Headphones 3,500 RUB, 4.9 stars, only 12 reviews" -ForegroundColor Gray

$scenario2 = @{
    userEvidence = @(
        "Wireless Bluetooth Headphones ProSound, 3500 RUB",
        "Rating 4.9 stars but only 12 reviews",
        "Features: premium sound, 40h battery, active noise cancellation",
        "Cheaper than top competitors"
    )
    competitorEvidence = @(
        "Competitor A: 4200 RUB, 4.3 stars, 2345 reviews - market leader",
        "Competitor B: 3800 RUB, 4.2 stars, 1567 reviews",
        "Competitor C: 3900 RUB, 4.4 stars, 987 reviews"
    )
} | ConvertTo-Json -Depth 10

try {
    $response2 = Invoke-RestMethod -Uri "$baseUrl/strategize" -Method POST -ContentType "application/json" -Body $scenario2
    Write-Host "[OK] AI response received" -ForegroundColor Green
    Write-Host "Strategy length: $($response2.strategy.Length) characters`n" -ForegroundColor Gray
    
    $results += [PSCustomObject]@{
        Scenario = "Good Price, Low Visibility"
        Success = $true
        StrategyLength = $response2.strategy.Length
        Strategy = $response2.strategy
    }
} catch {
    Write-Host "[FAIL] Error: $_`n" -ForegroundColor Red
    $results += [PSCustomObject]@{
        Scenario = "Good Price, Low Visibility"
        Success = $false
        Error = $_.Exception.Message
    }
}

# Scenario 3: Mid-Range Everything
Write-Host "SCENARIO 3: Mid-Range Everything (Hardest Case)" -ForegroundColor Yellow
Write-Host "Product: Fitness Tracker 5,500 RUB, 4.2 stars, 156 reviews" -ForegroundColor Gray

$scenario3 = @{
    userEvidence = @(
        "Fitness Tracker Smart Band FitPro, 5500 RUB",
        "Rating 4.2 stars with 156 reviews",
        "Features: heart rate monitor, sleep tracking, IP68 waterproof",
        "Standard feature set, no unique selling point"
    )
    competitorEvidence = @(
        "Competitor A: 5200 RUB, 4.3 stars, 234 reviews - slightly better",
        "Competitor B: 5800 RUB, 4.1 stars, 189 reviews - similar",
        "Competitor C: 5400 RUB, 4.2 stars, 167 reviews - very close match"
    )
} | ConvertTo-Json -Depth 10

try {
    $response3 = Invoke-RestMethod -Uri "$baseUrl/strategize" -Method POST -ContentType "application/json" -Body $scenario3
    Write-Host "[OK] AI response received" -ForegroundColor Green
    Write-Host "Strategy length: $($response3.strategy.Length) characters`n" -ForegroundColor Gray
    
    $results += [PSCustomObject]@{
        Scenario = "Mid-Range Everything"
        Success = $true
        StrategyLength = $response3.strategy.Length
        Strategy = $response3.strategy
    }
} catch {
    Write-Host "[FAIL] Error: $_`n" -ForegroundColor Red
    $results += [PSCustomObject]@{
        Scenario = "Mid-Range Everything"
        Success = $false
        Error = $_.Exception.Message
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Success -eq $true }).Count
Write-Host "Scenarios tested: $($results.Count)" -ForegroundColor White
Write-Host "Successful responses: $successCount" -ForegroundColor $(if ($successCount -eq 3) { 'Green' } else { 'Yellow' })

if ($successCount -eq 3) {
    Write-Host "`n[OK] All scenarios received AI responses`n" -ForegroundColor Green
    
    # Quality check hints
    Write-Host "Manual Review Checklist:" -ForegroundColor Cyan
    Write-Host "  1. Are strategies specific (mentions numbers, percentages)?" -ForegroundColor Gray
    Write-Host "  2. Are they actionable (clear next steps)?" -ForegroundColor Gray
    Write-Host "  3. Do they address the actual scenario challenges?" -ForegroundColor Gray
    Write-Host "  4. Do they avoid generic fluff?" -ForegroundColor Gray
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review strategies in docs/TEST_4.2_AI_EXPERT_REVIEW.md" -ForegroundColor White
    Write-Host "  2. Score each strategy (1-10)" -ForegroundColor White
    Write-Host "  3. Get second opinion from another AI" -ForegroundColor White
    Write-Host "  4. Calculate average score" -ForegroundColor White
    Write-Host "  5. Pass requires: average >= 7/10`n" -ForegroundColor White
    
    # Save results to file
    $outputFile = "docs/TEST_4.2_RESULTS.json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "Results saved to: $outputFile`n" -ForegroundColor Green
} else {
    Write-Host "`n[FAIL] Some scenarios failed to get AI responses`n" -ForegroundColor Red
    $results | Where-Object { $_.Success -eq $false } | ForEach-Object {
        Write-Host "  Failed: $($_.Scenario)" -ForegroundColor Red
        Write-Host "  Error: $($_.Error)`n" -ForegroundColor Gray
    }
}

Write-Host "Test completed!`n" -ForegroundColor Cyan
