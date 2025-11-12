# ============================================
# Supabase Edge Functions 部署腳本 (Windows PowerShell)
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
    Write-Host "[✓] $Message" -ForegroundColor Green
}

# 函數：打印警告訊息
function Print-Warning {
    param([string]$Message)
    Write-Host "[⚠] $Message" -ForegroundColor Yellow
}

# 函數：打印錯誤訊息
function Print-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

# 函數：打印資訊訊息
function Print-Info {
    param([string]$Message)
    Write-Host "[ℹ] $Message" -ForegroundColor Cyan
}

# ============================================
# 開始部署
# ============================================

Print-Header "Supabase Edge Functions 部署腳本"

Write-Host "專案資訊："
Write-Host "  Project Ref: $PROJECT_REF"
Write-Host "  Dashboard: $PROJECT_URL"
Write-Host ""

# ============================================
# 步驟 1：檢查前置條件
# ============================================

Print-Header "步驟 1：檢查前置條件"

# 檢查 Node.js
Print-Info "檢查 Node.js..."
try {
    $nodeVersion = node --version
    Print-Success "Node.js 已安裝 ($nodeVersion)"
}
catch {
    Print-Error "Node.js 未安裝"
    Write-Host ""
    Write-Host "請先安裝 Node.js: https://nodejs.org"
    exit 1
}

# 檢查 npm
Print-Info "檢查 npm..."
try {
    $npmVersion = npm --version
    Print-Success "npm 已安裝 ($npmVersion)"
}
catch {
    Print-Error "npm 未安裝"
    exit 1
}

# ============================================
# 步驟 2：登入 Supabase
# ============================================

Print-Header "步驟 2：登入 Supabase"

Print-Info "檢查登入狀態..."
try {
    npx supabase projects list 2>&1 | Out-Null
    Print-Success "已登入 Supabase"
}
catch {
    Print-Warning "尚未登入 Supabase"
    Write-Host ""
    Write-Host "即將打開瀏覽器進行登入..."
    Write-Host "請在瀏覽器中完成登入後返回此視窗。"
    Write-Host ""
    Read-Host "按 Enter 繼續"
    
    try {
        npx supabase login
        Print-Success "登入成功"
    }
    catch {
        Print-Error "登入失敗: $_"
        exit 1
    }
}

# ============================================
# 步驟 3：連接到專案
# ============================================

Print-Header "步驟 3：連接到專案"

Print-Info "正在連接到專案 $PROJECT_REF..."
try {
    npx supabase link --project-ref $PROJECT_REF 2>&1 | Out-Null
    Print-Success "專案連接成功"
}
catch {
    Print-Warning "連接失敗，可能已經連接過"
    Print-Info "繼續執行部署..."
}

# ============================================
# 步驟 4：部署 Edge Functions
# ============================================

Print-Header "步驟 4：部署 Edge Functions"

# 切換到腳本所在目錄
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 部署 sync-to-firestore
Print-Info "正在部署 sync-to-firestore 函數..."
try {
    npx supabase functions deploy sync-to-firestore
    Print-Success "sync-to-firestore 部署成功"
}
catch {
    Print-Error "sync-to-firestore 部署失敗: $_"
    Write-Host ""
    Write-Host "請檢查錯誤訊息並重試。"
    exit 1
}

Write-Host ""

# 部署 cleanup-outbox
Print-Info "正在部署 cleanup-outbox 函數..."
try {
    npx supabase functions deploy cleanup-outbox
    Print-Success "cleanup-outbox 部署成功"
}
catch {
    Print-Error "cleanup-outbox 部署失敗: $_"
    Write-Host ""
    Write-Host "請檢查錯誤訊息並重試。"
    exit 1
}

# ============================================
# 部署完成
# ============================================

Print-Header "部署完成！"

Print-Success "已成功部署以下 Edge Functions："
Write-Host "  ✓ sync-to-firestore"
Write-Host "  ✓ cleanup-outbox"
Write-Host ""

Print-Info "接下來的步驟："
Write-Host ""
Write-Host "1. 驗證函數已部署："
Write-Host "   前往：$PROJECT_URL/functions"
Write-Host ""
Write-Host "2. 查看函數日誌："
Write-Host "   點擊函數名稱 → Logs 分頁"
Write-Host ""
Write-Host "3. 測試同步功能："
Write-Host "   - 在應用中創建訂單"
Write-Host "   - 檢查 outbox 表"
Write-Host "   - 等待 30 秒"
Write-Host "   - 檢查 Firestore orders_rt 集合"
Write-Host ""

Print-Success "祝使用愉快！🚀"
Write-Host ""

