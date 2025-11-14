# 技術債列表 (Technical Debt)

本文檔記錄專案中已知的技術債務，包括問題描述、影響範圍、優先級和解決方案。

---

## 🔴 高優先級 (High Priority)

_目前無高優先級技術債_

---

## 🟡 中優先級 (Medium Priority)

_目前無中優先級技術債_

---

## 🟢 低優先級 (Low Priority)

### 1. Kotlin 增量編譯快取錯誤

**問題描述**：
在執行 `flutter run` 編譯 Android 應用時，Kotlin 編譯器會出現增量編譯快取錯誤，導致編譯過程中顯示大量錯誤訊息。

**錯誤訊息**：
```
e: Daemon compilation failed: null
java.lang.Exception
...
Caused by: java.lang.AssertionError: java.lang.Exception: Could not close incremental caches in D:\repo\mobile\build\<plugin_name>\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
...
Suppressed: java.lang.IllegalStateException: Storage for [D:\repo\mobile\build\<plugin_name>\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\class-fq-name-to-source.tab] is already registered
```

**影響範圍**：
- ✅ **不影響應用功能**：應用最終能成功編譯並正常運行
- ⚠️ **影響開發體驗**：編譯日誌中顯示大量錯誤訊息，可能干擾開發人員判斷真正的錯誤
- ⚠️ **可能影響 CI/CD**：如果 CI/CD 流程對編譯警告/錯誤敏感，可能導致構建失敗

**根本原因**：
Kotlin 編譯器的增量編譯快取系統在處理多個 Flutter 插件時出現路徑衝突：
- 插件源碼路徑：`C:\Users\User\AppData\Local\Pub\Cache\hosted\pub.dev\<plugin>-<version>\android\`
- 專案構建路徑：`D:\repo\mobile\build\<plugin_name>\kotlin\`
- 快取系統嘗試註冊已經註冊的儲存文件，導致衝突

**受影響的插件**：
- `device_info_plus`
- `audioplayers_android`
- `flutter_plugin_android_lifecycle`
- `location`
- `flutter_tts`
- 以及其他 20+ 個 Flutter 插件

**已嘗試的解決方案**：
1. ✅ **執行 `flutter clean`**：清理 Flutter 構建快取 - **無效**
2. ✅ **升級 Android NDK 到 27.0.12077973**：消除 NDK 版本警告 - **無效**（錯誤仍存在）
3. ❌ **執行 `./gradlew cleanBuildCache`**：任務不存在，無法執行
4. ❌ **升級 Kotlin 版本**：目前已是最新穩定版 (2.1.0)，無法再升級

**可能的解決方案**：
1. **等待 Kotlin 編譯器更新**：這可能是 Kotlin 2.1.0 的已知 Bug，等待未來版本修復
2. **禁用 Kotlin 增量編譯**：在 `gradle.properties` 中添加 `kotlin.incremental=false`（會降低編譯速度）
3. **升級 Gradle 版本**：目前使用 Gradle 8.12，可能升級到更新版本會修復此問題
4. **重啟電腦**：釋放可能被鎖定的文件句柄（臨時解決方案）

**優先級**：🟢 **低優先級**
- 不影響應用功能
- 不影響開發流程
- 僅影響編譯日誌的可讀性

**觸發條件**：
- 當 CI/CD 流程開始對編譯警告/錯誤敏感時
- 當錯誤開始影響其他開發人員的工作時
- 當 Kotlin 或 Gradle 發布新版本修復此問題時

**記錄日期**：2025-10-22

**記錄人**：AI Assistant

**相關文件**：
- `mobile/android/app/build.gradle.kts`（已升級 NDK 到 27.0.12077973）
- `mobile/android/settings.gradle.kts`（Kotlin 版本：2.1.0）

---

## 📝 已解決的技術債 (Resolved)

_目前無已解決的技術債_

---

## 📋 技術債管理指南

### 優先級定義

- **🔴 高優先級**：嚴重影響應用功能、安全性或用戶體驗，需要立即解決
- **🟡 中優先級**：影響開發效率或代碼質量，應在下個迭代中解決
- **🟢 低優先級**：輕微影響或僅影響非關鍵流程，可以延後解決

### 更新流程

1. **發現技術債**：開發人員在開發過程中發現問題
2. **記錄技術債**：在本文檔中添加新條目，包含完整的問題描述和影響分析
3. **評估優先級**：根據影響範圍和嚴重程度確定優先級
4. **定期審查**：每月審查一次技術債列表，更新優先級和狀態
5. **解決技術債**：根據優先級安排解決時間，解決後移至「已解決」區域

### 文檔格式

每個技術債條目應包含：
- **問題描述**：清晰描述問題是什麼
- **錯誤訊息**：如果有錯誤訊息，提供完整的錯誤堆疊
- **影響範圍**：列出受影響的功能、模組或流程
- **根本原因**：分析問題的根本原因
- **已嘗試的解決方案**：記錄已經嘗試過但無效的解決方案
- **可能的解決方案**：列出可能的解決方案和預期效果
- **優先級**：根據影響程度確定優先級
- **觸發條件**：什麼情況下需要優先解決此問題
- **記錄日期**：問題首次記錄的日期
- **記錄人**：記錄此問題的人員
- **相關文件**：相關的代碼文件或文檔

---

## 🔗 相關資源

- [Flutter 官方文檔](https://flutter.dev/docs)
- [Kotlin 官方文檔](https://kotlinlang.org/docs/home.html)
- [Gradle 官方文檔](https://docs.gradle.org/)
- [Android NDK 官方文檔](https://developer.android.com/ndk)

---

**最後更新**：2025-10-22

