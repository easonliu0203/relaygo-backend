#!/bin/bash

# Firebase 專案設定自動化腳本
# 使用方法: ./scripts/firebase-setup.sh

set -e

echo "🔥 Firebase 專案設定開始..."

# 檢查必要工具
check_dependencies() {
    echo "📋 檢查必要工具..."
    
    if ! command -v firebase &> /dev/null; then
        echo "❌ Firebase CLI 未安裝"
        echo "請執行: npm install -g firebase-tools"
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter 未安裝"
        echo "請先安裝 Flutter SDK"
        exit 1
    fi
    
    if ! command -v flutterfire &> /dev/null; then
        echo "❌ FlutterFire CLI 未安裝"
        echo "請執行: dart pub global activate flutterfire_cli"
        exit 1
    fi
    
    echo "✅ 所有必要工具已安裝"
}

# Firebase 登入
firebase_login() {
    echo "🔐 Firebase 登入..."
    firebase login
}

# 建立 Firebase 專案
create_firebase_project() {
    echo "🏗️ 建立 Firebase 專案..."
    
    read -p "請輸入專案 ID (例如: ride-booking-app-12345): " PROJECT_ID
    
    if [ -z "$PROJECT_ID" ]; then
        echo "❌ 專案 ID 不能為空"
        exit 1
    fi
    
    echo "建立專案: $PROJECT_ID"
    firebase projects:create $PROJECT_ID
    
    echo "設定預設專案..."
    firebase use $PROJECT_ID
    
    echo "✅ Firebase 專案建立完成"
}

# 初始化 Firebase 服務
init_firebase_services() {
    echo "⚙️ 初始化 Firebase 服務..."
    
    # 初始化 Firebase
    firebase init
    
    echo "✅ Firebase 服務初始化完成"
}

# 設定 Flutter Firebase
setup_flutter_firebase() {
    echo "📱 設定 Flutter Firebase 配置..."
    
    cd mobile
    
    # 使用 FlutterFire CLI 配置
    flutterfire configure
    
    cd ..
    
    echo "✅ Flutter Firebase 配置完成"
}

# 建立環境變數檔案
create_env_files() {
    echo "📝 建立環境變數檔案..."
    
    # 複製範例檔案
    if [ ! -f "mobile/.env" ]; then
        cp mobile/.env.example mobile/.env
        echo "✅ 已建立 mobile/.env"
        echo "⚠️ 請編輯 mobile/.env 填入實際配置值"
    fi
    
    if [ ! -f "backend/.env" ]; then
        cp backend/.env.example backend/.env
        echo "✅ 已建立 backend/.env"
        echo "⚠️ 請編輯 backend/.env 填入實際配置值"
    fi
}

# 安裝依賴
install_dependencies() {
    echo "📦 安裝專案依賴..."
    
    # 安裝後端依賴
    echo "安裝後端依賴..."
    cd backend
    npm install
    cd ..
    
    # 安裝 Flutter 依賴
    echo "安裝 Flutter 依賴..."
    cd mobile
    flutter pub get
    cd ..
    
    echo "✅ 依賴安裝完成"
}

# 設定 Firebase 安全規則
setup_security_rules() {
    echo "🔒 設定 Firebase 安全規則..."
    
    # Firestore 規則
    cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用戶只能讀寫自己的資料
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 聊天室規則
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // 訂單狀態 (只讀，由後端更新)
    match /order_status/{orderId} {
      allow read: if request.auth != null;
      allow write: if false; // 只允許後端更新
    }
    
    // 司機位置 (司機可寫，客戶可讀)
    match /driver_locations/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
  }
}
EOF

    # Storage 規則
    cat > storage.rules << 'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 用戶頭像
    match /avatars/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 司機證件
    match /driver_documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 聊天檔案
    match /chat_files/{chatId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF

    # 部署規則
    firebase deploy --only firestore:rules,storage
    
    echo "✅ 安全規則設定完成"
}

# 主要執行流程
main() {
    echo "🚀 開始 Firebase 專案設定..."
    
    check_dependencies
    firebase_login
    create_firebase_project
    init_firebase_services
    setup_flutter_firebase
    create_env_files
    install_dependencies
    setup_security_rules
    
    echo ""
    echo "🎉 Firebase 專案設定完成！"
    echo ""
    echo "📋 後續步驟："
    echo "1. 編輯 mobile/.env 和 backend/.env 填入實際配置值"
    echo "2. 在 Firebase Console 中啟用所需的認證方式"
    echo "3. 設定 Google Maps API 金鑰"
    echo "4. 執行 npm run dev 啟動後端服務"
    echo "5. 執行 flutter run 啟動客戶端應用"
    echo ""
    echo "📚 詳細文檔請參考: docs/20250928_0500_06_Firebase專案設定與客戶端架構規劃.md"
}

# 執行主程式
main "$@"
