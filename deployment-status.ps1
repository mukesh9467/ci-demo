# Deployment Progress Tracker
# Updated every 5 minutes

$startTime = Get-Date "2026-03-04 14:21:00"
$now = Get-Date
$elapsed = $now - $startTime
$estimatedTotal = 20 * 60  # 20 minutes in seconds

Write-Host "`n========== DEPLOYMENT PROGRESS ==========" -ForegroundColor Cyan
Write-Host "Start Time:   2026-03-04 14:21:00" -ForegroundColor Green
Write-Host "Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host "Elapsed:      $($elapsed.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Yellow
Write-Host "Estimated:    ~20 minutes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Progress:"
$percent = [Math]::Min(($elapsed.TotalSeconds / $estimatedTotal) * 100, 100)
$bars = [Math]::Round($percent / 5)
$progress = ("[" + ("=" * $bars) + ("-" * (20 - $bars)) + "]").PadRight(24)
Write-Host "$progress $($percent.ToString('F0'))%" -ForegroundColor Yellow
Write-Host ""
Write-Host "Current Status:"
$procCount = Get-Process terraform-provider* -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "  Terraform Providers: $procCount active" -ForegroundColor Green
Write-Host "  Terraform Process:   $(if (Get-Process terraform -ErrorAction SilentlyContinue) { 'Running' } else { 'Idle' })" -ForegroundColor Green
Write-Host ""
Write-Host "Expected Completion: ~14:40-14:41 local time"  -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan
