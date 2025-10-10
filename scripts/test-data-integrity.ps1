# Test 4.3: Data Integrity (End-to-End)
# Checks that data is not lost or corrupted from parser to AI

$baseUrl = "http://localhost:3000"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TEST 4.3: DATA INTEGRITY (E2E)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "This test verifies that data flows correctly through:" -ForegroundColor White
Write-Host "  1. Parser (marketplace -> product data)" -ForegroundColor Gray
Write-Host "  2. Evidence builder (product -> facts)" -ForegroundColor Gray
Write-Host "  3. AI strategist (facts -> recommendations)`n" -ForegroundColor Gray

Write-Host "IMPORTANT: Watch the SERVER TERMINAL for logs!" -ForegroundColor Yellow
Write-Host "You'll see two checkpoints:" -ForegroundColor Yellow
Write-Host "  - Checkpoint 1: After parsing (/analyze)" -ForegroundColor Gray
Write-Host "  - Checkpoint 2: Before AI call (/strategize)`n" -ForegroundColor Gray

# Step 1: Analyze product
Write-Host "[Step 1/2] Calling /analyze..." -ForegroundColor Cyan
try {
    $analyzeResult = Invoke-RestMethod -Uri "$baseUrl/analyze?marketplace=ozon&url=https://www.ozon.ru/product/example-oz-10001" -Method Get
    
    Write-Host "  Product parsed:" -ForegroundColor Green
    Write-Host "    Title:   $($analyzeResult.product.title)" -ForegroundColor White
    Write-Host "    Price:   $($analyzeResult.product.price) rub" -ForegroundColor White
    Write-Host "    Rating:  $($analyzeResult.product.rating)" -ForegroundColor White
    Write-Host "    Reviews: $($analyzeResult.product.reviews)" -ForegroundColor White
    Write-Host "    Competitors: $($analyzeResult.competitors.Count)`n" -ForegroundColor White
    
    # Build evidence from parsed data
    $userEvidence = @(
        "Our product: '$($analyzeResult.product.title)', price: $($analyzeResult.product.price) rub",
        "Rating: $($analyzeResult.product.rating) stars, reviews: $($analyzeResult.product.reviews)"
    )
    
    $competitorsEvidence = @()
    foreach ($comp in $analyzeResult.competitors) {
        $competitorsEvidence += "Competitor: '$($comp.title)', price: $($comp.price) rub"
        $competitorsEvidence += "Competitor rating: $($comp.rating) stars, $($comp.reviews) reviews"
    }
    
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Generate strategy
Write-Host "[Step 2/2] Calling /strategize..." -ForegroundColor Cyan
Write-Host "  NOTE: This may fail if Gemini API key is not configured" -ForegroundColor Yellow
Write-Host "  The test focuses on data logging in server terminal`n" -ForegroundColor Yellow

try {
    $strategyBody = @{
        userEvidence = $userEvidence
        competitorsEvidence = $competitorsEvidence
        tone = "analytical"
        focus = @("pricing", "reviews")
    } | ConvertTo-Json
    
    $strategyResult = Invoke-RestMethod -Uri "$baseUrl/strategize" -Method Post -Body $strategyBody -ContentType "application/json"
    
    Write-Host "  Strategy generated successfully`n" -ForegroundColor Green
    
} catch {
    Write-Host "  WARNING: /strategize failed (likely AI API issue)" -ForegroundColor Yellow
    Write-Host "  Error: $_" -ForegroundColor Gray
    Write-Host "  This is OK - check server logs for Checkpoint 2 data`n" -ForegroundColor Gray
}

# Manual verification prompt
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MANUAL VERIFICATION REQUIRED" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Check the SERVER TERMINAL and verify:" -ForegroundColor White
Write-Host ""
Write-Host "1. Checkpoint 1 (after parsing) shows:" -ForegroundColor Yellow
Write-Host "   - Product title: '$($analyzeResult.product.title)'" -ForegroundColor Gray
Write-Host "   - Product price: $($analyzeResult.product.price) rub" -ForegroundColor Gray
Write-Host "   - Product rating: $($analyzeResult.product.rating)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Checkpoint 2 (before AI) shows:" -ForegroundColor Yellow
Write-Host "   - userEvidence contains SAME title" -ForegroundColor Gray
Write-Host "   - userEvidence contains SAME price" -ForegroundColor Gray
Write-Host "   - userEvidence contains SAME rating" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Data integrity check:" -ForegroundColor Yellow
Write-Host "   [ ] Title matches between checkpoints" -ForegroundColor Gray
Write-Host "   [ ] Price matches between checkpoints" -ForegroundColor Gray
Write-Host "   [ ] Rating matches between checkpoints" -ForegroundColor Gray
Write-Host "   [ ] Competitor data matches" -ForegroundColor Gray
Write-Host "   [ ] No null/undefined appeared unexpectedly" -ForegroundColor Gray
Write-Host ""

Write-Host "If all boxes checked: TEST PASSED" -ForegroundColor Green
Write-Host "If any mismatch found: TEST FAILED" -ForegroundColor Red
Write-Host "If Checkpoint 2 missing: Check AI API configuration`n" -ForegroundColor Yellow

Write-Host "========================================`n" -ForegroundColor Cyan

# Exit with success (manual verification required)
Write-Host "Test completed - manual verification required" -ForegroundColor Cyan
exit 0
