# ============================================
# Supabase Outbox Pattern 自動部署腳本 (Windows PowerShell)
# ============================================
# 
# 功能：自動執行可以自動化的部署步驟
# 
# 使用方式：
#   .\deploy.ps1
# 
# ============================================

$ErrorActionPreference = "Stop"

# 專案配置
$PROJECT_REF = "vlyhwegpvpnjyocqmfqc"
$PROJECT_URL = "https://app.supabase.com/project/$PROJECT_REF"

# 函數：打印標題
function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "============================================" -ForegroundColor Blue
    Write-Host ""
}

# 函數：打印成功訊息
function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

# 函數：打印警告訊息
function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# 函數：打印錯誤訊息
function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# 函數：打印資訊訊息
function Print-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

# 函數：檢查命令是否存在
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        Print-Success "$Command 已安裝"
        return $true
    }
    catch {
        Print-Error "$Command 未安裝"
        return $false
    }
}

# ============================================
# 開始部署
# ============================================

Print-Header "Supabase Outbox Pattern 部署腳本"

Write-Host "專案資訊："
Write-Host "  Project Ref: $PROJECT_REF"
Write-Host "  Dashboard: $PROJECT_URL"
Write-Host ""

# ============================================
# 步驟 0：檢查前置條件
# ============================================

Print-Header "步驟 0：檢查前置條件"

# 檢查 Supabase CLI
if (-not (Test-Command "supabase")) {
    Print-Error "請先安裝 Supabase CLI"
    Write-Host ""
    Write-Host "安裝方式："
    Write-Host "  Windows (Scoop): scoop install supabase"
    Write-Host "  npm: npm install -g supabase"
    exit 1
}

# 檢查 Firebase CLI（可選）
$FIREBASE_CLI_INSTALLED = Test-Command "firebase"
if (-not $FIREBASE_CLI_INSTALLED) {
    Print-Warning "Firebase CLI 未安裝（步驟 5 需要手動部署規則）"
}

# 檢查是否已登入 Supabase
Print-Info "檢查 Supabase 登入狀態..."
try {
    supabase projects list 2>&1 | Out-Null
    Print-Success "已登入 Supabase"
}
catch {
    Print-Warning "尚未登入 Supabase"
    Print-Info "正在打開登入頁面..."
    supabase login
}

# ============================================
# 步驟 1：執行資料庫 Migration
# ============================================

Print-Header "步驟 1：執行資料庫 Migration"

Print-Info "正在推送 migration 到 Supabase..."

# 切換到腳本所在目錄
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

try {
    supabase db push
    Print-Success "Migration 執行成功"
    Print-Info "已創建："
    Write-Host "  - outbox 表"
    Write-Host "  - orders_outbox_trigger"
    Write-Host "  - cleanup_old_outbox_events() 函數"
}
catch {
    Print-Error "Migration 執行失敗: $_"
    exit 1
}

# ============================================
# 步驟 2：配置環境變數（需手動）
# ============================================

Print-Header "步驟 2：配置環境變數（需手動操作）"

Print-Warning "此步驟需要手動在 Supabase Dashboard 中完成"
Write-Host ""
Write-Host "請按照以下步驟操作："
Write-Host ""
Write-Host "1. 前往 Firebase Console 獲取憑證："
Write-Host "   URL: https://console.firebase.google.com"
Write-Host ""
Write-Host "2. 獲取 Firebase Project ID："
Write-Host "   - 點擊齒輪圖示 ⚙️ → 專案設定"
Write-Host "   - 複製「專案 ID」"
Write-Host ""
Write-Host "3. 獲取 Firebase API Key："
Write-Host "   - 在專案設定中找到「您的應用程式」"
Write-Host "   - 複製 Web API Key"
Write-Host ""
Write-Host "4. 前往 Supabase Dashboard 設置環境變數："
Write-Host "   URL: $PROJECT_URL/settings/functions"
Write-Host ""
Write-Host "5. 添加以下兩個 Secrets："
Write-Host "   - FIREBASE_PROJECT_ID = <您的 Firebase Project ID>"
Write-Host "   - FIREBASE_API_KEY = <您的 Firebase API Key>"
Write-Host ""

Read-Host "完成後按 Enter 繼續"

# ============================================
# 步驟 3：部署 Edge Functions
# ============================================

Print-Header "步驟 3：部署 Edge Functions"

# 部署 sync-to-firestore
Print-Info "正在部署 sync-to-firestore 函數..."
try {
    supabase functions deploy sync-to-firestore
    Print-Success "sync-to-firestore 部署成功"
}
catch {
    Print-Error "sync-to-firestore 部署失敗: $_"
    exit 1
}

# 部署 cleanup-outbox
Print-Info "正在部署 cleanup-outbox 函數..."
try {
    supabase functions deploy cleanup-outbox
    Print-Success "cleanup-outbox 部署成功"
}
catch {
    Print-Error "cleanup-outbox 部署失敗: $_"
    exit 1
}

Print-Success "所有 Edge Functions 部署完成"

# ============================================
# 步驟 4：設置 Cron Job（需手動）
# ============================================

Print-Header "步驟 4：設置 Cron Job（需手動操作）"

Print-Warning "此步驟需要手動在 Supabase Dashboard 中完成"
Write-Host ""
Write-Host "請按照以下步驟操作："
Write-Host ""
Write-Host "1. 前往 Supabase Dashboard SQL Editor："
Write-Host "   URL: $PROJECT_URL/sql"
Write-Host ""
Write-Host "2. 點擊 'New query'"
Write-Host ""
Write-Host "3. 複製並執行 setup_cron_jobs.sql 的內容"
Write-Host "   檔案位置: $ScriptDir\setup_cron_jobs.sql"
Write-Host ""
Write-Host "4. 驗證 Cron Jobs 已創建："
Write-Host "   應該看到兩個任務："
Write-Host "   - sync-orders-to-firestore (每 30 秒)"
Write-Host "   - cleanup-old-outbox-events (每天凌晨 2 點)"
Write-Host ""

Read-Host "完成後按 Enter 繼續"

# ============================================
# 步驟 5：更新 Firestore 安全規則
# ============================================

Print-Header "步驟 5：更新 Firestore 安全規則"

Print-Info "Firestore 規則已自動更新（添加 orders_rt 規則）"

if ($FIREBASE_CLI_INSTALLED) {
    Print-Info "正在部署 Firestore 規則到 Firebase..."
    Set-Location "$ScriptDir\..\firebase"
    
    try {
        firebase deploy --only firestore:rules
        Print-Success "Firestore 規則部署成功"
    }
    catch {
        Print-Error "Firestore 規則部署失敗: $_"
        Print-Warning "請手動執行: cd firebase; firebase deploy --only firestore:rules"
    }
}
else {
    Print-Warning "Firebase CLI 未安裝，請手動部署規則"
    Write-Host ""
    Write-Host "手動部署步驟："
    Write-Host "1. 安裝 Firebase CLI: npm install -g firebase-tools"
    Write-Host "2. 登入 Firebase: firebase login"
    Write-Host "3. 部署規則: cd firebase; firebase deploy --only firestore:rules"
    Write-Host ""
}

# ============================================
# 部署完成
# ============================================

Print-Header "部署完成！"

Print-Success "自動化步驟已完成"
Write-Host ""
Write-Host "部署摘要："
Write-Host "  ✅ 步驟 1：資料庫 Migration"
Write-Host "  ⚠️  步驟 2：環境變數（需手動驗證）"
Write-Host "  ✅ 步驟 3：Edge Functions"
Write-Host "  ⚠️  步驟 4：Cron Job（需手動驗證）"
Write-Host "  ✅ 步驟 5：Firestore 規則"
Write-Host ""

Print-Info "接下來的步驟："
Write-Host ""
Write-Host "1. 驗證環境變數已設置："
Write-Host "   $PROJECT_URL/settings/functions"
Write-Host ""
Write-Host "2. 驗證 Cron Jobs 已創建："
Write-Host "   執行 SQL: SELECT * FROM cron.job;"
Write-Host ""
Write-Host "3. 測試同步功能："
Write-Host "   - 在應用中創建訂單"
Write-Host "   - 檢查 Supabase outbox 表"
Write-Host "   - 等待 30 秒"
Write-Host "   - 檢查 Firestore orders_rt 集合"
Write-Host ""

Print-Info "詳細文檔請參考: DEPLOYMENT_GUIDE.md"

Write-Host ""
Print-Success "祝部署順利！🚀"
Write-Host ""

