# 測試多角色支援功能
# 測試場景：同一個 Google 帳號先登入客戶端，再登入司機端

$apiUrl = "https://api.relaygo.pro/api/auth/register-or-login"
$testFirebaseUid = "test-multi-role-uid-$(Get-Date -Format 'yyyyMMddHHmmss')"
$testEmail = "multi-role-test@relaygo.com"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "測試多角色支援功能" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "測試 Firebase UID: $testFirebaseUid" -ForegroundColor Yellow
Write-Host "測試 Email: $testEmail`n" -ForegroundColor Yellow

# 場景 1: 首次登入客戶端
Write-Host "========================================" -ForegroundColor Green
Write-Host "場景 1: 首次登入客戶端" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$body1 = @{
    firebaseUid = $testFirebaseUid
    email = $testEmail
    role = "customer"
} | ConvertTo-Json

Write-Host "Request Body:" -ForegroundColor Cyan
Write-Host $body1 -ForegroundColor Gray
Write-Host ""

try {
    $response1 = Invoke-WebRequest -Uri $apiUrl -Method POST -ContentType "application/json" -Body $body1
    Write-Host "Status Code: $($response1.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response1.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    Write-Host ""
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# 場景 2: 同一個帳號登入司機端
Write-Host "========================================" -ForegroundColor Green
Write-Host "場景 2: 同一個帳號登入司機端" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$body2 = @{
    firebaseUid = $testFirebaseUid
    email = $testEmail
    role = "driver"
} | ConvertTo-Json

Write-Host "Request Body:" -ForegroundColor Cyan
Write-Host $body2 -ForegroundColor Gray
Write-Host ""

try {
    $response2 = Invoke-WebRequest -Uri $apiUrl -Method POST -ContentType "application/json" -Body $body2
    Write-Host "Status Code: $($response2.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response2.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    Write-Host ""
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# 場景 3: 重新登入客戶端（角色已存在）
Write-Host "========================================" -ForegroundColor Green
Write-Host "場景 3: 重新登入客戶端（角色已存在）" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

try {
    $response3 = Invoke-WebRequest -Uri $apiUrl -Method POST -ContentType "application/json" -Body $body1
    Write-Host "Status Code: $($response3.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response3.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    Write-Host ""
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "測試完成！" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "驗證結果：" -ForegroundColor Yellow
Write-Host "1. 場景 1 應該返回 201 Created，roles = ['customer']" -ForegroundColor Gray
Write-Host "2. 場景 2 應該返回 200 OK，roles = ['customer', 'driver']，message = '角色 driver 已添加'" -ForegroundColor Gray
Write-Host "3. 場景 3 應該返回 200 OK，roles = ['customer', 'driver']，message = '用戶已存在'" -ForegroundColor Gray
Write-Host ""

