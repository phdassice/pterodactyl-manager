# Pterodactyl 面板快速管理工具

這是一個用於快速管理 Pterodactyl 面板的 Bash 腳本工具，提供常用的維護和管理功能。

## 功能特色

### 🚀 快取管理
- **清除快取**: 清除視圖、配置、路由和應用快取
- **優化面板**: 優化配置、路由、視圖和自動加載

### 🔧 維護模式
- **進入維護模式**: 快速將面板設為維護狀態
- **退出維護模式**: 恢復面板正常訪問

### 🔄 服務管理
- **重啟 Wings**: 快速重啟 Wings 守護進程
- **查看 Wings 狀態**: 查看 Wings 服務運行狀態
- **重啟面板服務**: 一鍵重啟 Nginx、PHP-FPM 和 Redis

### 🛠️ 系統維護
- **更新面板**: 自動下載並安裝最新版本
- **修復權限**: 自動修復面板文件權限問題
- **查看日誌**: 查看 Laravel、Nginx 和 Wings 日誌
- **快速安裝**: 引導安裝 Pterodactyl 面板

## 安裝方法

### 1. 下載腳本
```bash
cd /root
git clone <repository-url>
cd pterodactyl-tools
```

或直接下載：
```bash
curl -fsSL https://raw.githubusercontent.com/phdassice/pterodactyl-manager/main/install.sh | sudo bash
```

### 2. 添加執行權限
```bash
chmod +x ptero-manager.sh
```

### 3. 運行腳本
```bash
sudo ./ptero-manager.sh
```

## 使用說明

### 基本使用

腳本必須以 root 權限運行：
```bash
sudo ./ptero-manager.sh
```

### 功能說明

#### 1️⃣ 清除快取
清除所有類型的快取，適用於：
- 更新配置後
- 出現錯誤時
- 面板行為異常時

#### 2️⃣ 優化面板
優化面板性能，適用於：
- 生產環境部署
- 性能調優
- 更新後優化

#### 3️⃣ 進入維護模式
將面板設為維護狀態：
- 顯示維護頁面給用戶
- 60秒後自動重試
- 適合更新或維護時使用

#### 4️⃣ 退出維護模式
恢復面板正常訪問：
- 移除維護頁面
- 恢復所有功能

#### 5️⃣ 重啟 Wings
重啟 Wings 守護進程：
- 自動檢測重啟狀態
- 顯示服務狀態
- 失敗時提供日誌查看命令

#### 6️⃣ 查看 Wings 狀態
查看 Wings 服務的完整狀態信息

#### 7️⃣ 重啟面板服務
一鍵重啟所有相關服務：
- Nginx Web 服務器
- PHP-FPM (自動檢測版本)
- Redis 快取服務

#### 8️⃣ 更新面板
自動更新到最新版本：
- 自動進入維護模式
- 下載最新版本
- 更新依賴和數據庫
- 自動退出維護模式

#### 9️⃣ 修復權限
修復面板文件權限：
- 自動檢測 Web 服務器用戶
- 設置正確的所有者和權限
- 適用於權限錯誤問題

#### 🔟 查看日誌
實時查看各種日誌：
- Laravel 應用日誌
- Nginx 錯誤日誌
- Wings 系統日誌

#### 1️⃣1️⃣ 快速安裝面板
引導安裝 Pterodactyl 面板（新服務器）

## 系統要求

- Ubuntu 20.04/22.04 或 CentOS 7/8/Rocky Linux 8
- Root 權限
- 已安裝 Pterodactyl 面板（除了快速安裝功能）

## 常見問題

### 找不到面板路徑
腳本會自動檢測 `/var/www/pterodactyl`，如果路徑不同會提示你輸入正確路徑。

### PHP 版本問題
腳本會自動檢測 PHP 8.0-8.3 版本，如果使用其他版本，請手動修改腳本。

### Wings 重啟失敗
查看日誌：
```bash
journalctl -u wings -n 50
```

### 權限問題
運行修復權限功能：
```bash
sudo ./ptero-manager.sh
# 選擇選項 9
```

## 注意事項

⚠️ **重要提示**：
- 務必使用 root 權限運行
- 更新前建議先備份數據庫
- 生產環境操作請謹慎
- 維護模式會影響用戶訪問

## 貢獻

歡迎提交問題和改進建議！

## 許可證

MIT License

## 相關鏈接

- [Pterodactyl 官方文檔](https://pterodactyl.io/)
- [Pterodactyl GitHub](https://github.com/pterodactyl/panel)
- [Wings GitHub](https://github.com/pterodactyl/wings)

---

**作者**: Beach  
**創建日期**: 2026-01-04  
**版本**: 1.0.0



