# Ubuntu 工具箱 (Ubuntu Toolbox)

一個功能豐富的 Ubuntu 系統管理工具集，提供直觀的交互式界面來執行常見的系統維護任務。

## 🚀 功能特色

- **Docker 清理工具** - 一鍵清理 dangling images 和未使用的 Docker 資源
- **系統狀態監控** - 詳細的 CPU、記憶體、磁碟使用情況查詢
- **網路速度測試** - 內建網路速度測試功能
- **系統健康檢查** - 快速系統總覽和健康狀態評估
- **交互式界面** - 美觀易用的彩色菜單界面

## 📦 安裝

### 自動安裝（推薦）

```bash
# 下載並運行安裝腳本
curl -fsSL https://raw.githubusercontent.com/phdassice/ubuntu-toolbox/main/install.sh | bash
```

### 手動安裝

1. 克隆或下載此倉庫：
```bash
git clone https://github.com/phdassice/ubuntu-toolbox.git
cd ubuntu-toolbox
```

2. 運行安裝腳本：
```bash
chmod +x install.sh
./install.sh
```

3. 或者手動複製到系統路徑：
```bash
sudo cp toolbox /usr/local/bin/
sudo chmod +x /usr/local/bin/toolbox
```

## 🎯 使用方法

安裝完成後，在終端中輸入：

```bash
toolbox
```

然後根據菜單提示選擇要執行的功能：

```
╔═══════════════════════════════════════════════════════════════╗
║                    Ubuntu 工具箱                          ║
║                    v1.0.0                                ║
╚═══════════════════════════════════════════════════════════════╝

請選擇要執行的功能：

1. Docker Dangling Images 清理
2. 系統狀態查詢
3. 網路速度測試
4. 系統資訊總覽
0. 退出工具箱

請輸入選項 [0-4]:
```

## 🛠️ 功能詳情

### 1. Docker Dangling Images 清理
- 檢查並清理未使用的 Docker images
- 顯示清理前後的磁碟空間對比
- 提供完整的 Docker 系統清理選項
- 安全確認機制防止誤刪

### 2. 系統狀態查詢
- **系統資訊**: 作業系統、核心版本、主機名稱、運行時間
- **CPU 資訊**: 型號、核心數、使用率
- **記憶體資訊**: 總量、已使用、可用、使用率
- **磁碟使用**: 各分割區的使用情況
- **網路資訊**: 網路介面和活躍連接

### 3. 網路速度測試
- 使用 speedtest-cli 進行準確的速度測試
- 顯示延遲、下載速度、上傳速度
- 自動評估網路性能等級
- 可選擇保存測試結果到文件

### 4. 系統資訊總覽
- 快速健康檢查（磁碟、記憶體、系統負載）
- 系統統計資訊
- 顯示 CPU 和記憶體使用率最高的進程
- 彩色狀態指示器

## 📋 系統需求

- Ubuntu 18.04 或更新版本
- Bash shell
- 基本的系統權限

### 依賴套件
工具箱會自動檢查並安裝以下依賴：

- `bc` - 數學計算
- `curl` - 網路請求
- `net-tools` - 網路工具（netstat）
- `speedtest-cli` - 網路速度測試

## 🗑️ 卸載

運行卸載腳本：

```bash
curl -fsSL https://raw.githubusercontent.com/phdassice/ubuntu-toolbox/main/uninstall.sh | bash
```

或手動刪除：

```bash
sudo rm /usr/local/bin/toolbox
```

## 🎨 螢幕截圖

工具箱使用彩色界面提供更好的用戶體驗：

- 🔵 藍色 - 標題和提示
- 🟢 綠色 - 成功訊息和正常狀態
- 🟡 黃色 - 警告和輸入提示
- 🔴 紅色 - 錯誤和警告狀態
- 🟣 紫色 - 特殊資訊
- 🟦 青色 - 裝飾元素

## 🤝 貢獻

歡迎提交 Issues 和 Pull Requests！

### 開發指南

1. Fork 此倉庫
2. 創建功能分支：`git checkout -b feature-name`
3. 提交更改：`git commit -am 'Add some feature'`
4. 推送到分支：`git push origin feature-name`
5. 提交 Pull Request

## 📄 授權

本專案採用 MIT 授權 - 詳見 [LICENSE](LICENSE) 文件。

## 📞 支援

如果您遇到問題或有建議，請：

1. 查看 [Issues](https://github.com/phdassice/ubuntu-toolbox/issues) 頁面
2. 創建新的 Issue 描述問題
3. 或者發送電子郵件至維護者

## 🚀 更新日誌

### v1.0.0
- 初始版本發布
- Docker dangling images 清理功能
- 系統狀態查詢功能
- 網路速度測試功能
- 系統資訊總覽功能
- 彩色交互式界面

---

**享受使用 Ubuntu 工具箱！** 🎉
