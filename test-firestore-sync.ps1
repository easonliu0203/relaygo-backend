# Firestore 同步測試腳本 (PowerShell)
#
# 用途：自動驗證 Firestore 同步是否正常工作
#
# 使用方法：
# 1. 設置環境變數（或直接修改下面的變數）
# 2. 執行：.\test-firestore-sync.ps1

# 配置
$SUPABASE_URL = "https://vlyhwegpvpnjyocqmfqc.supabase.co"
$SUPABASE_SERVICE_ROLE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY
$FIREBASE_PROJECT_ID = $env:FIREBASE_PROJECT_ID

# 測試結果
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

# 輔助函數
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

function Test-Condition {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $script:TotalTests++
    
    if ($Passed) {
        $script:PassedTests++
        Write-Success "$Name : PASS $Message"
    } else {
        $script:FailedTests++
        Write-Error-Custom "$Name : FAIL $Message"
    }
}

# 主測試函數
function Run-Tests {
    Write-Section "🚀 開始 Firestore 同步測試"

    # 檢查環境變數
    Write-Section "1️⃣ 檢查環境變數"
    
    if (-not $SUPABASE_SERVICE_ROLE_KEY) {
        Write-Error-Custom "SUPABASE_SERVICE_ROLE_KEY 未設置"
        Write-Info "請設置環境變數或修改腳本中的變數"
        exit 1
    }
    Write-Success "SUPABASE_SERVICE_ROLE_KEY 已設置"

    if (-not $FIREBASE_PROJECT_ID) {
        Write-Warning-Custom "FIREBASE_PROJECT_ID 未設置（可選）"
    } else {
        Write-Success "FIREBASE_PROJECT_ID: $FIREBASE_PROJECT_ID"
    }

    # 測試 Edge Function
    Write-Section "2️⃣ 測試 Edge Function"

    try {
        Write-Info "觸發 sync-to-firestore..."
        
        $headers = @{
            "Authorization" = "Bearer $SUPABASE_SERVICE_ROLE_KEY"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/sync-to-firestore" `
            -Method Post `
            -Headers $headers `
            -ErrorAction Stop

        Test-Condition "Edge Function 回應" $true "Status: 200"
        
        if ($response.success -ne $null) {
            Test-Condition "同步成功數量" ($response.success -gt 0) "成功: $($response.success), 失敗: $($response.failure)"
            Test-Condition "同步失敗數量" ($response.failure -eq 0) "失敗: $($response.failure)"
        }

        Write-Info "回應: $($response | ConvertTo-Json -Depth 3)"

    } catch {
        Write-Error-Custom "Edge Function 測試失敗: $($_.Exception.Message)"
        $script:FailedTests++
    }

    # 檢查 Supabase 資料
    Write-Section "3️⃣ 檢查 Supabase 資料"

    try {
        Write-Info "查詢 bookings 表..."
        
        $headers = @{
            "apikey" = $SUPABASE_SERVICE_ROLE_KEY
            "Authorization" = "Bearer $SUPABASE_SERVICE_ROLE_KEY"
        }
        
        $bookings = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/bookings?select=*&limit=5" `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop

        Test-Condition "Bookings 資料存在" ($bookings.Count -gt 0) "找到 $($bookings.Count) 筆訂單"

        if ($bookings.Count -gt 0) {
            $booking = $bookings[0]
            
            Test-Condition "Booking 有 ID" ($null -ne $booking.id)
            Test-Condition "Booking 有 customer_id" ($null -ne $booking.customer_id)
            Test-Condition "Booking 有 pickup_address" ($null -ne $booking.pickup_address)
            Test-Condition "Booking 有 destination" ($null -ne $booking.destination)
            Test-Condition "Booking 有 status" ($null -ne $booking.status)

            Write-Info "範例訂單: $($booking.id)"
            Write-Info "  - 客戶: $($booking.customer_id)"
            Write-Info "  - 上車: $($booking.pickup_address)"
            Write-Info "  - 目的地: $($booking.destination)"
            Write-Info "  - 狀態: $($booking.status)"
        }

    } catch {
        Write-Error-Custom "Supabase 資料檢查失敗: $($_.Exception.Message)"
        $script:FailedTests++
    }

    # 檢查 Outbox 事件
    Write-Section "4️⃣ 檢查 Outbox 事件"

    try {
        Write-Info "查詢 outbox 表..."
        
        $headers = @{
            "apikey" = $SUPABASE_SERVICE_ROLE_KEY
            "Authorization" = "Bearer $SUPABASE_SERVICE_ROLE_KEY"
        }
        
        $events = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/outbox?select=*&order=created_at.desc&limit=5" `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop

        Test-Condition "Outbox 事件存在" ($events.Count -gt 0) "找到 $($events.Count) 個事件"

        if ($events.Count -gt 0) {
            $event = $events[0]
            
            Test-Condition "Event 有 ID" ($null -ne $event.id)
            Test-Condition "Event 有 aggregate_type" ($event.aggregate_type -eq "booking")
            Test-Condition "Event 有 event_type" ($null -ne $event.event_type)
            Test-Condition "Event 有 payload" ($null -ne $event.payload)

            Write-Info "最新事件: $($event.id)"
            Write-Info "  - 類型: $($event.event_type)"
            Write-Info "  - 時間: $($event.created_at)"
            Write-Info "  - 已處理: $(if ($event.processed) { '是' } else { '否' })"

            # 檢查 payload 格式
            if ($event.payload) {
                $payload = $event.payload
                
                Test-Condition "Payload 有 bookingId" ($null -ne $payload.bookingId)
                Test-Condition "Payload 有 customerId" ($null -ne $payload.customerId)
                Test-Condition "Payload 有 pickupAddress" ($null -ne $payload.pickupAddress)
                Test-Condition "Payload 有 destination" ($null -ne $payload.destination)
            }
        }

    } catch {
        Write-Error-Custom "Outbox 事件檢查失敗: $($_.Exception.Message)"
        $script:FailedTests++
    }

    # 顯示測試結果
    Write-Section "📊 測試結果"

    Write-Info "總測試數: $script:TotalTests"
    Write-Success "通過: $script:PassedTests"
    if ($script:FailedTests -gt 0) {
        Write-Error-Custom "失敗: $script:FailedTests"
    }

    $passRate = [math]::Round(($script:PassedTests / $script:TotalTests) * 100, 1)
    
    if ($script:FailedTests -eq 0) {
        Write-Success "`n🎉 所有測試通過！($passRate%)"
    } else {
        Write-Error-Custom "`n❌ 有 $script:FailedTests 個測試失敗 ($passRate%)"
    }

    # 下一步建議
    Write-Section "🎯 下一步"

    if ($script:FailedTests -eq 0) {
        Write-Info "1. 檢查 Firebase Console 中的 Firestore 資料"
        Write-Info "2. 確認 pickupLocation 和 dropoffLocation 類型是 geopoint"
        Write-Info "3. 測試客戶端 App 是否可以正常顯示訂單"
    } else {
        Write-Info "1. 檢查 Edge Function 日誌："
        Write-Info "   $($SUPABASE_URL.Replace('https://', 'https://supabase.com/dashboard/project/'))/functions"
        Write-Info "2. 檢查環境變數是否正確設置"
        Write-Info "3. 確認 Service Account 格式正確"
    }

    if ($script:FailedTests -gt 0) {
        exit 1
    }
}

# 執行測試
try {
    Run-Tests
} catch {
    Write-Error-Custom "測試執行失敗: $($_.Exception.Message)"
    Write-Host $_.Exception.StackTrace
    exit 1
}

