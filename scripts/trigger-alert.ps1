# Trigger an alert by killing the app, wait for it to fire, then restore.
# Used in: deck §10 demo, lab Track 02 grading checkpoint.

Write-Host "Step 1: kill app container"
docker stop day23-app

Write-Host "Step 2: wait 90s for ServiceDown alert to fire"
$alertFired = $false
for ($i=1; $i -le 18; $i++) {
    Start-Sleep -Seconds 5
    try {
        $resp = Invoke-RestMethod -Uri "http://localhost:9093/api/v2/alerts"
        # The response is an array of alerts. We check if any has state 'active'
        $activeAlerts = $resp | Where-Object { $_.status.state -eq "active" }
        if ($activeAlerts) {
            Write-Host "  alert fired (after $($i*5)s)"
            $alertFired = $true
            break
        }
    } catch {
        # Ignore errors if alertmanager is not reachable yet
    }
    Write-Host "  no alert yet ($($i*5)s)"
}

if (!$alertFired) {
    Write-Host "Warning: Alert did not fire within 90s"
}

Write-Host "Step 3: restart app"
docker start day23-app

Write-Host "Step 4: wait 60s for alert to resolve"
for ($i=1; $i -le 12; $i++) {
    Start-Sleep -Seconds 5
    try {
        $resp = Invoke-RestMethod -Uri "http://localhost:9093/api/v2/alerts"
        $activeAlerts = $resp | Where-Object { $_.status.state -eq "active" }
        if (!$activeAlerts) {
            Write-Host "  alert resolved"
            exit 0
        }
    } catch {
        # Ignore errors
    }
    Write-Host "  alert still active ($($i*5)s)"
}

Write-Host "alert did not resolve within 60s"
exit 1
