#!/bin/bash

# Pterodactyl 工具安裝腳本
# 此腳本會將 Pterodactyl 管理工具安裝到系統中，使其可以全局使用
# 支持本地安裝和遠程安裝：curl -sSL https://your-repo/install.sh | bash

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 安裝目錄
INSTALL_DIR="/usr/local/bin"
MANAGER_NAME="ptero-manager"
QUICK_NAME="ptero-quick"

# GitHub 倉庫信息（如果你有的話，可以修改這裡）
REPO_URL="https://raw.githubusercontent.com/phdassice/pterodactyl-manger/main/ptero-manger"
USE_REMOTE=false

clear
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}    Pterodactyl 工具安裝程序${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# 檢查是否為 root 或有 sudo 權限
if [[ $EUID -ne 0 ]]; then
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}此安裝需要管理員權限${NC}"
        echo -e "${YELLOW}請輸入密碼以繼續安裝...${NC}"
        echo ""
    fi
fi

# 獲取腳本所在目錄
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>/dev/null && pwd )"

# 如果無法獲取目錄，嘗試使用當前目錄
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(pwd)"
fi

# 檢測是否通過 curl 管道執行（檢查多個可能的文件名）
if [ ! -f "$SCRIPT_DIR/ptero-manager.sh" ] && \
   [ ! -f "$SCRIPT_DIR/install.sh" ] && \
   [ ! -f "$SCRIPT_DIR/quick-commands.sh" ]; then
    echo -e "${YELLOW}檢測到遠程安裝模式${NC}"
    USE_REMOTE=true
    TEMP_DIR=$(mktemp -d)
    SCRIPT_DIR="$TEMP_DIR"
    echo -e "${BLUE}臨時目錄: ${NC}$TEMP_DIR"
else
    echo -e "${GREEN}檢測到本地安裝模式${NC}"
fi

echo -e "${BLUE}安裝目錄: ${NC}$INSTALL_DIR"
echo -e "${BLUE}腳本來源: ${NC}$SCRIPT_DIR"
echo ""

# 檢查是否已經安裝
if [ -f "$INSTALL_DIR/$MANAGER_NAME" ]; then
    echo -e "${YELLOW}檢測到已安裝的版本${NC}"
    read -p "是否要覆蓋安裝？[y/N]: " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}安裝已取消${NC}"
        [ "$USE_REMOTE" = true ] && rm -rf "$TEMP_DIR"
        exit 0
    fi
    echo ""
fi

echo -e "${BLUE}正在安裝 Pterodactyl 管理工具...${NC}"
echo ""

# 遠程下載文件
if [ "$USE_REMOTE" = true ]; then
    echo -e "${YELLOW}[1/3] 下載主管理工具...${NC}"
    if command -v curl &> /dev/null; then
        curl -fsSL "${REPO_URL}/ptero-manager.sh" -o "$SCRIPT_DIR/ptero-manager.sh"
    elif command -v wget &> /dev/null; then
        wget -q "${REPO_URL}/ptero-manager.sh" -O "$SCRIPT_DIR/ptero-manager.sh"
    else
        echo -e "${RED}✗ 需要 curl 或 wget 來下載文件${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    echo -e "${YELLOW}[2/3] 下載快速命令工具...${NC}"
    if command -v curl &> /dev/null; then
        curl -fsSL "${REPO_URL}/quick-commands.sh" -o "$SCRIPT_DIR/quick-commands.sh" 2>/dev/null || true
    elif command -v wget &> /dev/null; then
        wget -q "${REPO_URL}/quick-commands.sh" -O "$SCRIPT_DIR/quick-commands.sh" 2>/dev/null || true
    fi
fi

# 安裝主工具
if [ -f "$SCRIPT_DIR/ptero-manager.sh" ]; then
    echo -e "${YELLOW}[3/3] 安裝主管理工具...${NC}"
    sudo cp "$SCRIPT_DIR/ptero-manager.sh" "$INSTALL_DIR/$MANAGER_NAME"
    sudo chmod +x "$INSTALL_DIR/$MANAGER_NAME"
    echo -e "${GREEN}✓ 主工具已安裝: $MANAGER_NAME${NC}"
else
    echo -e "${RED}✗ 找不到 ptero-manager.sh${NC}"
    [ "$USE_REMOTE" = true ] && rm -rf "$TEMP_DIR"
    exit 1
fi

# 安裝快速命令工具
if [ -f "$SCRIPT_DIR/quick-commands.sh" ]; then
    echo -e "${YELLOW}安裝快速命令工具...${NC}"
    sudo cp "$SCRIPT_DIR/quick-commands.sh" "$INSTALL_DIR/$QUICK_NAME"
    sudo chmod +x "$INSTALL_DIR/$QUICK_NAME"
    echo -e "${GREEN}✓ 快速命令工具已安裝: $QUICK_NAME${NC}"
else
    echo -e "${YELLOW}! 快速命令工具未找到 (可選)${NC}"
fi

# 清理臨時文件
if [ "$USE_REMOTE" = true ]; then
    rm -rf "$TEMP_DIR"
fi


# 驗證安裝
if [ -f "$INSTALL_DIR/$MANAGER_NAME" ] && [ -x "$INSTALL_DIR/$MANAGER_NAME" ]; then
    echo ""
    echo -e "${GREEN}✓ Pterodactyl 管理工具安裝成功！${NC}"
    echo ""
    
    # 檢查依賴
    echo -e "${BLUE}正在檢查系統依賴...${NC}"
    echo ""
    
    missing_deps=""
    
    # 檢查 PHP
    if ! command -v php &> /dev/null; then
        echo -e "${RED}✗ PHP 未安裝${NC}"
        missing_deps="php"
    else
        echo -e "${GREEN}✓ PHP 已安裝 $(php -v | head -1)${NC}"
    fi
    
    # 檢查 Composer
    if ! command -v composer &> /dev/null; then
        echo -e "${YELLOW}! Composer 未安裝 (面板更新需要)${NC}"
    else
        echo -e "${GREEN}✓ Composer 已安裝${NC}"
    fi
    
    # 檢查 Nginx
    if ! command -v nginx &> /dev/null; then
        echo -e "${YELLOW}! Nginx 未安裝${NC}"
    else
        echo -e "${GREEN}✓ Nginx 已安裝${NC}"
    fi
    
    # 檢查 MySQL/MariaDB
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}! MySQL/MariaDB 未安裝${NC}"
    else
        echo -e "${GREEN}✓ MySQL/MariaDB 已安裝${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}          安裝完成！${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${CYAN}使用方法:${NC}"
    echo ""
    echo -e "  ${YELLOW}1. 交互式菜單 (推薦):${NC}"
    echo -e "     ${GREEN}ptero-manager${NC}"
    echo -e "     提供完整的圖形化菜單界面"
    echo ""
    echo -e "  ${YELLOW}2. 快速命令:${NC}"
    echo -e "     ${GREEN}ptero-quick cache-clear${NC}      # 清除快取"
    echo -e "     ${GREEN}ptero-quick restart-wings${NC}    # 重啟 Wings"
    echo -e "     ${GREEN}ptero-quick maintenance-on${NC}   # 進入維護模式"
    echo -e "     ${GREEN}ptero-quick maintenance-off${NC}  # 退出維護模式"
    echo -e "     ${GREEN}ptero-quick restart-all${NC}      # 重啟所有服務"
    echo -e "     ${GREEN}ptero-quick status${NC}           # 查看服務狀態"
    echo ""
    echo -e "  ${YELLOW}3. 查看所有快速命令:${NC}"
    echo -e "     ${GREEN}ptero-quick${NC}"
    echo ""
    echo -e "${CYAN}================================================${NC}"
    echo -e "${BLUE}🎉 現在您可以在任何地方使用這些命令！${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""
    
    # 詢問是否立即運行
    read -p "是否立即運行 Pterodactyl 管理工具？[y/N]: " run_now
    if [[ $run_now =~ ^[Yy]$ ]]; then
        echo ""
        exec sudo ptero-manager
    fi
else
    echo -e "${RED}✗ 安裝失敗${NC}"
    exit 1
fi
