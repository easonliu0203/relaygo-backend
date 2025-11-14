#!/bin/bash

# Relay GO Firebase 配置設定腳本
# 使用方法: ./scripts/setup-firebase-config.sh

set -e

echo "🔥 Relay GO Firebase 配置設定腳本"
echo "=================================="

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 檢查是否在正確的目錄
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}錯誤: 請在 Flutter 專案根目錄執行此腳本${NC}"
    exit 1
fi

echo -e "${BLUE}步驟 1: 建立目錄結構${NC}"

# 建立 Android 配置目錄
mkdir -p android/app/src/customer
mkdir -p android/app/src/driver

# 建立 iOS 配置目錄
mkdir -p ios/Runner/Customer
mkdir -p ios/Runner/Driver

echo -e "${GREEN}✅ 目錄結構建立完成${NC}"

echo -e "${BLUE}步驟 2: 檢查配置檔案${NC}"

# 檢查 Android 配置檔案
ANDROID_CUSTOMER_CONFIG="android/app/src/customer/google-services.json"
ANDROID_DRIVER_CONFIG="android/app/src/driver/google-services.json"

if [ -f "$ANDROID_CUSTOMER_CONFIG" ]; then
    echo -e "${GREEN}✅ Android 客戶端配置檔案已存在${NC}"
else
    echo -e "${YELLOW}⚠️  Android 客戶端配置檔案不存在: $ANDROID_CUSTOMER_CONFIG${NC}"
    echo -e "${YELLOW}   請從 Firebase Console 下載 com.relaygo.customer 的 google-services.json${NC}"
fi

if [ -f "$ANDROID_DRIVER_CONFIG" ]; then
    echo -e "${GREEN}✅ Android 司機端配置檔案已存在${NC}"
else
    echo -e "${YELLOW}⚠️  Android 司機端配置檔案不存在: $ANDROID_DRIVER_CONFIG${NC}"
    echo -e "${YELLOW}   請從 Firebase Console 下載 com.relaygo.driver 的 google-services.json${NC}"
fi

# 檢查 iOS 配置檔案
IOS_CUSTOMER_CONFIG="ios/Runner/Customer/GoogleService-Info.plist"
IOS_DRIVER_CONFIG="ios/Runner/Driver/GoogleService-Info.plist"

if [ -f "$IOS_CUSTOMER_CONFIG" ]; then
    echo -e "${GREEN}✅ iOS 客戶端配置檔案已存在${NC}"
else
    echo -e "${YELLOW}⚠️  iOS 客戶端配置檔案不存在: $IOS_CUSTOMER_CONFIG${NC}"
    echo -e "${YELLOW}   請從 Firebase Console 下載 com.relaygo.customer.ios 的 GoogleService-Info.plist${NC}"
fi

if [ -f "$IOS_DRIVER_CONFIG" ]; then
    echo -e "${GREEN}✅ iOS 司機端配置檔案已存在${NC}"
else
    echo -e "${YELLOW}⚠️  iOS 司機端配置檔案不存在: $IOS_DRIVER_CONFIG${NC}"
    echo -e "${YELLOW}   請從 Firebase Console 下載 com.relaygo.driver.ios 的 GoogleService-Info.plist${NC}"
fi

echo -e "${BLUE}步驟 3: 驗證配置檔案內容${NC}"

# 驗證 Android 配置檔案
if [ -f "$ANDROID_CUSTOMER_CONFIG" ]; then
    if grep -q "com.relaygo.customer" "$ANDROID_CUSTOMER_CONFIG"; then
        echo -e "${GREEN}✅ Android 客戶端配置檔案套件名稱正確${NC}"
    else
        echo -e "${RED}❌ Android 客戶端配置檔案套件名稱不正確${NC}"
    fi
fi

if [ -f "$ANDROID_DRIVER_CONFIG" ]; then
    if grep -q "com.relaygo.driver" "$ANDROID_DRIVER_CONFIG"; then
        echo -e "${GREEN}✅ Android 司機端配置檔案套件名稱正確${NC}"
    else
        echo -e "${RED}❌ Android 司機端配置檔案套件名稱不正確${NC}"
    fi
fi

# 驗證 iOS 配置檔案
if [ -f "$IOS_CUSTOMER_CONFIG" ]; then
    if grep -q "com.relaygo.customer.ios" "$IOS_CUSTOMER_CONFIG"; then
        echo -e "${GREEN}✅ iOS 客戶端配置檔案 Bundle ID 正確${NC}"
    else
        echo -e "${RED}❌ iOS 客戶端配置檔案 Bundle ID 不正確${NC}"
    fi
fi

if [ -f "$IOS_DRIVER_CONFIG" ]; then
    if grep -q "com.relaygo.driver.ios" "$IOS_DRIVER_CONFIG"; then
        echo -e "${GREEN}✅ iOS 司機端配置檔案 Bundle ID 正確${NC}"
    else
        echo -e "${RED}❌ iOS 司機端配置檔案 Bundle ID 不正確${NC}"
    fi
fi

echo -e "${BLUE}步驟 4: 測試建置${NC}"

echo -e "${YELLOW}正在測試 Android 客戶端建置...${NC}"
if flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --debug > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Android 客戶端建置成功${NC}"
else
    echo -e "${RED}❌ Android 客戶端建置失敗${NC}"
fi

echo -e "${YELLOW}正在測試 Android 司機端建置...${NC}"
if flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --debug > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Android 司機端建置成功${NC}"
else
    echo -e "${RED}❌ Android 司機端建置失敗${NC}"
fi

echo -e "${BLUE}配置完成總結${NC}"
echo "=================================="

# 統計配置狀態
TOTAL_CONFIGS=4
EXISTING_CONFIGS=0

[ -f "$ANDROID_CUSTOMER_CONFIG" ] && ((EXISTING_CONFIGS++))
[ -f "$ANDROID_DRIVER_CONFIG" ] && ((EXISTING_CONFIGS++))
[ -f "$IOS_CUSTOMER_CONFIG" ] && ((EXISTING_CONFIGS++))
[ -f "$IOS_DRIVER_CONFIG" ] && ((EXISTING_CONFIGS++))

echo -e "配置檔案狀態: ${EXISTING_CONFIGS}/${TOTAL_CONFIGS} 完成"

if [ $EXISTING_CONFIGS -eq $TOTAL_CONFIGS ]; then
    echo -e "${GREEN}🎉 所有 Firebase 配置檔案已正確設定！${NC}"
    echo -e "${GREEN}您現在可以開始開發 Relay GO 應用程式了！${NC}"
    echo ""
    echo -e "${BLUE}執行應用程式:${NC}"
    echo "客戶端: flutter run --flavor customer --target lib/apps/customer/main_customer.dart"
    echo "司機端: flutter run --flavor driver --target lib/apps/driver/main_driver.dart"
else
    echo -e "${YELLOW}⚠️  還有 $((TOTAL_CONFIGS - EXISTING_CONFIGS)) 個配置檔案需要設定${NC}"
    echo -e "${YELLOW}請參考 firebase-config-guide.md 完成剩餘配置${NC}"
fi

echo ""
echo -e "${BLUE}需要幫助？${NC}"
echo "📖 查看完整指南: cat firebase-config-guide.md"
echo "🔥 Firebase Console: https://console.firebase.google.com/"
echo "📱 Flutter 文檔: https://flutter.dev/docs"
