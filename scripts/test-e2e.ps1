$ErrorActionPreference = "Stop"
$base = "http://localhost:3333"
$email = "e2e-" + (Get-Date -Format "yyyyMMddHHmmss") + "@vitalis.test"
$password = "12345678"

Write-Host "== Health =="
Invoke-RestMethod "$base/health" | ConvertTo-Json

Write-Host "`n== Ready =="
try {
  Invoke-RestMethod "$base/health/ready" | ConvertTo-Json -Depth 5
} catch {
  Write-Warning "Ready falhou"
}

Write-Host "`n== Register =="
$bodyReg = '{"name":"Teste E2E","email":"' + $email + '","password":"' + $password + '"}'
$reg = Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType "application/json" -Body $bodyReg
$token = $reg.accessToken

Write-Host "`n== Assessment =="
$bodyAss = '{"age":28,"gender":"Male","heightCm":175,"weightKg":80,"dailySteps":8500,"caloriesIntake":2200,"hoursOfSleep":7.5,"exerciseHoursPerWeek":3,"smoker":"No","alcoholPerWeek":2,"diabetic":"No","heartDisease":"No"}'
$assessment = Invoke-RestMethod -Method Post -Uri "$base/assessments" -ContentType "application/json" -Headers @{ Authorization = "Bearer $token" } -Body $bodyAss

Write-Host "Perfil:" $assessment.plan.profile
Write-Host "Score:" $assessment.plan.profileScore
Write-Host "Cluster:" $assessment.plan.clusterLabel

Write-Host "`n== Dashboard =="
Invoke-RestMethod -Uri "$base/dashboard" -Headers @{ Authorization = "Bearer $token" } | Out-Null
Write-Host "E2E OK"
