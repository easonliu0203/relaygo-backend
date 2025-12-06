# 測試 Profile API 返回的 email 欄位

$firebaseUid = "test-multi-role-uid-20251202003357"
$apiUrl = "https://api.relaygo.pro/api/profile/upsert?firebaseUid=$firebaseUid"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "測試 Profile API Email 欄位" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Firebase UID: $firebaseUid" -ForegroundColor Yellow
Write-Host "API URL: $apiUrl`n" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $apiUrl -Method GET
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "`nResponse:" -ForegroundColor Cyan
    
    $jsonData = $response.Content | ConvertFrom-Json
    $jsonData | ConvertTo-Json -Depth 10
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "驗證結果" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    if ($jsonData.success -eq $true) {
        Write-Host "✅ API 調用成功" -ForegroundColor Green
        
        if ($jsonData.data.email) {
            Write-Host "✅ Email 欄位存在: $($jsonData.data.email)" -ForegroundColor Green
        } else {
            Write-Host "❌ Email 欄位不存在或為空" -ForegroundColor Red
        }
        
        if ($jsonData.data.userId) {
            Write-Host "✅ UserId 欄位存在: $($jsonData.data.userId)" -ForegroundColor Green
        } else {
            Write-Host "❌ UserId 欄位不存在或為空" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ API 調用失敗" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

