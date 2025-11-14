@echo off
echo ========================================
echo 檢查 Supabase 配置
echo ========================================
echo.

cd /d "%~dp0.."

echo [1/2] 檢查 .env 文件是否存在...
if not exist ".env" (
    echo ❌ .env 文件不存在！
    echo.
    echo 請創建 .env 文件並添加以下內容：
    echo SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
    echo SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    echo.
    pause
    exit /b 1
)

echo ✅ .env 文件存在
echo.

echo [2/2] 檢查 Supabase 配置...
findstr /C:"SUPABASE_URL" .env >nul
if errorlevel 1 (
    echo ❌ .env 文件中缺少 SUPABASE_URL
    pause
    exit /b 1
)

findstr /C:"SUPABASE_ANON_KEY" .env >nul
if errorlevel 1 (
    echo ❌ .env 文件中缺少 SUPABASE_ANON_KEY
    pause
    exit /b 1
)

echo ✅ Supabase 配置完整
echo.

echo ========================================
echo 配置檢查完成！
echo ========================================
echo.

pause

