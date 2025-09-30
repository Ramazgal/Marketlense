$ErrorActionPreference = 'Stop'
$wd = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent

$proc = Start-Process node -ArgumentList 'server.js' -WorkingDirectory $wd -PassThru -WindowStyle Hidden

try {
    $maxAttempts = 20
    for ($attempt = 0; $attempt -lt $maxAttempts; $attempt++) {
        try {
            Invoke-RestMethod -Uri 'http://127.0.0.1:3000/health' -TimeoutSec 2 | Out-Null
            break
        } catch {
            Start-Sleep -Milliseconds 500
            if ($attempt -eq $maxAttempts - 1) {
                throw
            }
        }
    }

    $analyzeUri = 'http://127.0.0.1:3000/analyze?url=' + [uri]::EscapeDataString('https://www.ozon.ru/product/example-oz-10001') + '&marketplace=ozon&withCompetitors=true'
    $analyze = Invoke-RestMethod -Uri $analyzeUri -TimeoutSec 15

    $searchUri = 'http://127.0.0.1:3000/search?query=' + [uri]::EscapeDataString('умная колонка') + '&limit=3'
    $search = Invoke-RestMethod -Uri $searchUri -TimeoutSec 15

    $monitorBody = @{ productUrl = 'https://www.wildberries.ru/catalog/54712891/detail.aspx'; marketplace = 'wildberries'; notes = 'autotest' }
    $monitor = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/monitoring/add' -Method Post -Body ($monitorBody | ConvertTo-Json) -ContentType 'application/json' -TimeoutSec 15

    [pscustomobject]@{
        Analyze    = $analyze
        Search     = $search
        Monitoring = $monitor
    } | ConvertTo-Json -Depth 6
} finally {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force
    }
}
