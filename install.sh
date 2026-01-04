    #!/bin/bash

    # Pterodactyl 工具安裝腳本
    # 此腳本會將 Pterodactyl 管理工具安裝到系統中，使其可以全局使用

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
        fi
    fi

    # 檢查是否已經安裝
    if [ -f "$INSTALL_DIR/$MANAGER_NAME" ]; then
        echo -e "${YELLOW}檢測到已安裝的版本${NC}"
        read -p "是否要覆蓋安裝？[y/N]: " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}安裝已取消${NC}"
            exit 0
        fi
    fi

    # 安裝主管理工具
    echo -e "${BLUE}正在安裝 Pterodactyl 管理工具...${NC}"
    echo ""

    # 如果 ptero-manager.sh 文件存在於當前目錄，則複製它
    if [ -f "./ptero-manager.sh" ]; then
        echo -e "${YELLOW}從當前目錄複製主管理工具...${NC}"
        sudo cp ./ptero-manager.sh "$INSTALL_DIR/$MANAGER_NAME"
    else
        echo -e "${YELLOW}從 GitHub 下載主管理工具...${NC}"
        sudo curl -fsSL https://raw.githubusercontent.com/phdassice/pterodactyl-manager/main/ptero-manager.sh -o "$INSTALL_DIR/$MANAGER_NAME" || {
            echo -e "${RED}下載失敗，請檢查網路連接或檔案路徑${NC}"
            exit 1
        }
    fi

    # 設置執行權限
    sudo chmod +x "$INSTALL_DIR/$MANAGER_NAME"
    echo -e "${GREEN}✓ 主工具已安裝: $MANAGER_NAME${NC}"


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
        echo -e "  ${YELLOW}1. 交互式菜單:${NC}"
        echo -e "     ${GREEN}ptero-manager${NC}"
        echo -e "     提供完整的圖形化菜單界面，包含 19 個功能選項"
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
