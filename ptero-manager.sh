#!/bin/bash

# Pterodactyl 面板快速管理工具
# Author: Beach
# Description: 快速管理Pterodactyl面板的各種操作

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 面板路徑（默認）
PANEL_PATH="/var/www/pterodactyl"

# 顯示標題
show_header() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}    Pterodactyl 面板快速管理工具${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""
}

# 檢查是否為root用戶
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}錯誤: 請使用root權限運行此腳本${NC}"
        echo -e "${YELLOW}使用命令: sudo $0${NC}"
        exit 1
    fi
}

# 檢查面板路徑
check_panel_path() {
    if [ ! -d "$PANEL_PATH" ]; then
        echo -e "${RED}錯誤: 找不到面板目錄 $PANEL_PATH${NC}"
        echo -n "請輸入正確的面板路徑: "
        read PANEL_PATH
        if [ ! -d "$PANEL_PATH" ]; then
            echo -e "${RED}路徑仍然無效，退出...${NC}"
            exit 1
        fi
    fi
}

# 清除快取
clear_cache() {
    echo -e "${BLUE}[1/4] 清除視圖快取...${NC}"
    cd $PANEL_PATH
    php artisan view:clear
    
    echo -e "${BLUE}[2/4] 清除配置快取...${NC}"
    php artisan config:clear
    
    echo -e "${BLUE}[3/4] 清除路由快取...${NC}"
    php artisan route:clear
    
    echo -e "${BLUE}[4/4] 清除應用快取...${NC}"
    php artisan cache:clear
    
    echo -e "${GREEN}✓ 快取清除完成！${NC}"
}

# 優化面板
optimize_panel() {
    echo -e "${BLUE}[1/4] 優化配置...${NC}"
    cd $PANEL_PATH
    php artisan config:cache
    
    echo -e "${BLUE}[2/4] 優化路由...${NC}"
    php artisan route:cache
    
    echo -e "${BLUE}[3/4] 優化視圖...${NC}"
    php artisan view:cache
    
    echo -e "${BLUE}[4/4] 優化自動加載...${NC}"
    composer dump-autoload -o
    
    echo -e "${GREEN}✓ 面板優化完成！${NC}"
}

# 進入維護模式
enter_maintenance() {
    echo -e "${YELLOW}正在進入維護模式...${NC}"
    cd $PANEL_PATH
    php artisan down
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 已進入維護模式${NC}"
        echo -e "${YELLOW}提示: 用戶將看到維護頁面${NC}"
    else
        echo -e "${RED}✗ 進入維護模式失敗${NC}"
    fi
}

# 退出維護模式
exit_maintenance() {
    echo -e "${YELLOW}正在退出維護模式...${NC}"
    cd $PANEL_PATH
    php artisan up
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 已退出維護模式${NC}"
        echo -e "${GREEN}面板已恢復正常訪問${NC}"
    else
        echo -e "${RED}✗ 退出維護模式失敗${NC}"
    fi
}

# 重啟Wings
restart_wings() {
    echo -e "${BLUE}正在重啟 Wings...${NC}"
    systemctl restart wings
    
    sleep 2
    
    if systemctl is-active --quiet wings; then
        echo -e "${GREEN}✓ Wings 已成功重啟${NC}"
        systemctl status wings --no-pager -l | head -n 10
    else
        echo -e "${RED}✗ Wings 重啟失敗${NC}"
        echo -e "${YELLOW}查看日誌: journalctl -u wings -n 50${NC}"
    fi
}

# 查看Wings狀態
check_wings_status() {
    echo -e "${CYAN}Wings 服務狀態:${NC}"
    systemctl status wings --no-pager -l
}

# 重啟面板服務
restart_panel_services() {
    echo -e "${BLUE}[1/3] 重啟 Nginx...${NC}"
    systemctl restart nginx
    
    echo -e "${BLUE}[2/3] 重啟 PHP-FPM...${NC}"
    # 嘗試檢測PHP版本
    for version in 8.3 8.2 8.1 8.0 7.4; do
        if systemctl list-unit-files | grep -q "php${version}-fpm"; then
            systemctl restart php${version}-fpm
            echo -e "${GREEN}✓ PHP ${version} FPM 已重啟${NC}"
            break
        fi
    done
    
    echo -e "${BLUE}[3/3] 重啟 Redis (如果有)...${NC}"
    if systemctl list-unit-files | grep -q "redis"; then
        systemctl restart redis
        echo -e "${GREEN}✓ Redis 已重啟${NC}"
    else
        echo -e "${YELLOW}! Redis 未安裝或未啟用${NC}"
    fi
    
    echo -e "${GREEN}✓ 面板服務重啟完成！${NC}"
}

# 更新面板
update_panel() {
    echo -e "${YELLOW}開始更新 Pterodactyl 面板...${NC}"
    cd $PANEL_PATH
    
    echo -e "${BLUE}[1/6] 進入維護模式...${NC}"
    php artisan down
    
    echo -e "${BLUE}[2/6] 下載最新版本...${NC}"
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    
    echo -e "${BLUE}[3/6] 設置權限...${NC}"
    chmod -R 755 storage/* bootstrap/cache
    
    echo -e "${BLUE}[4/6] 更新依賴...${NC}"
    composer install --no-dev --optimize-autoloader
    
    echo -e "${BLUE}[5/6] 執行數據庫遷移...${NC}"
    php artisan migrate --force --seed
    
    echo -e "${BLUE}[6/6] 清除快取並退出維護模式...${NC}"
    php artisan view:clear
    php artisan config:clear
    php artisan up
    
    echo -e "${GREEN}✓ 面板更新完成！${NC}"
}

# 修復面板權限
fix_permissions() {
    echo -e "${BLUE}正在修復面板權限...${NC}"
    cd $PANEL_PATH
    
    # 獲取web服務器用戶
    WEB_USER="www-data"
    if [ -f /etc/redhat-release ]; then
        WEB_USER="nginx"
    fi
    
    echo -e "${BLUE}設置所有者為: $WEB_USER${NC}"
    chown -R $WEB_USER:$WEB_USER $PANEL_PATH/*
    
    echo -e "${BLUE}設置目錄權限...${NC}"
    chmod -R 755 $PANEL_PATH/storage/* $PANEL_PATH/bootstrap/cache
    
    echo -e "${GREEN}✓ 權限修復完成！${NC}"
}

# 查看面板日誌
view_logs() {
    echo -e "${CYAN}選擇要查看的日誌:${NC}"
    echo "1. Laravel 日誌"
    echo "2. Nginx 錯誤日誌"
    echo "3. Wings 日誌"
    echo "4. 返回主菜單"
    echo ""
    read -p "請選擇 [1-4]: " log_choice
    
    case $log_choice in
        1)
            if [ -f "$PANEL_PATH/storage/logs/laravel.log" ]; then
                tail -f $PANEL_PATH/storage/logs/laravel.log
            else
                echo -e "${RED}找不到 Laravel 日誌文件${NC}"
            fi
            ;;
        2)
            if [ -f "/var/log/nginx/error.log" ]; then
                tail -f /var/log/nginx/error.log
            else
                echo -e "${RED}找不到 Nginx 錯誤日誌${NC}"
            fi
            ;;
        3)
            journalctl -u wings -f
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}無效的選擇${NC}"
            ;;
    esac
}

# 備份面板
backup_panel() {
    echo -e "${BLUE}正在備份 Pterodactyl 面板...${NC}"
    BACKUP_DIR="/root/pterodactyl-backups"
    BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p $BACKUP_DIR
    
    echo -e "${BLUE}[1/3] 備份面板文件...${NC}"
    tar -czf $BACKUP_DIR/panel_files_$BACKUP_DATE.tar.gz -C /var/www pterodactyl
    
    echo -e "${BLUE}[2/3] 備份數據庫...${NC}"
    read -p "請輸入數據庫名稱 [panel]: " DB_NAME
    DB_NAME=${DB_NAME:-panel}
    read -p "請輸入數據庫用戶名 [pterodactyl]: " DB_USER
    DB_USER=${DB_USER:-pterodactyl}
    read -sp "請輸入數據庫密碼: " DB_PASS
    echo ""
    
    mysqldump -u$DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/database_$BACKUP_DATE.sql
    
    echo -e "${BLUE}[3/3] 壓縮備份...${NC}"
    cd $BACKUP_DIR
    tar -czf pterodactyl_backup_$BACKUP_DATE.tar.gz panel_files_$BACKUP_DATE.tar.gz database_$BACKUP_DATE.sql
    rm panel_files_$BACKUP_DATE.tar.gz database_$BACKUP_DATE.sql
    
    echo -e "${GREEN}✓ 備份完成！${NC}"
    echo -e "${CYAN}備份位置: $BACKUP_DIR/pterodactyl_backup_$BACKUP_DATE.tar.gz${NC}"
}

# 查看面板版本信息
check_panel_version() {
    echo -e "${CYAN}=== Pterodactyl 版本信息 ===${NC}"
    cd $PANEL_PATH
    
    echo -e "\n${BLUE}面板版本:${NC}"
    if [ -f "config/app.php" ]; then
        grep "version" config/app.php | head -1
    fi
    
    echo -e "\n${BLUE}PHP 版本:${NC}"
    php -v | head -1
    
    echo -e "\n${BLUE}Composer 版本:${NC}"
    composer --version
    
    echo -e "\n${BLUE}Node.js 版本:${NC}"
    node -v 2>/dev/null || echo "未安裝"
    
    echo -e "\n${BLUE}數據庫版本:${NC}"
    mysql --version
    
    echo -e "\n${BLUE}Wings 版本:${NC}"
    if command -v wings &> /dev/null; then
        wings --version
    else
        echo "未安裝或不在 PATH 中"
    fi
}

# 清理舊日誌
clean_old_logs() {
    echo -e "${YELLOW}正在清理舊日誌...${NC}"
    
    echo -e "${BLUE}[1/3] 清理 Laravel 日誌 (保留最近7天)...${NC}"
    find $PANEL_PATH/storage/logs -name "*.log" -mtime +7 -delete
    
    echo -e "${BLUE}[2/3] 清理 Nginx 日誌 (保留最近7天)...${NC}"
    find /var/log/nginx -name "*.log.*" -mtime +7 -delete
    
    echo -e "${BLUE}[3/3] 清理系統日誌...${NC}"
    journalctl --vacuum-time=7d
    
    echo -e "${GREEN}✓ 日誌清理完成！${NC}"
}

# Docker 清理
clean_docker() {
    # 檢查 Docker 是否安裝
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}錯誤: Docker 未安裝${NC}"
        return
    fi
    
    echo -e "${CYAN}=== Docker 清理 ===${NC}"
    echo ""
    echo "1. 清除 Dangling Images (懸空映像)"
    echo "2. 清除所有未使用的映像"
    echo "3. 清除停止的容器"
    echo "4. 清除未使用的網絡"
    echo "5. 清除未使用的卷"
    echo "6. 完整清理 (所有未使用的資源)"
    echo "7. 返回主菜單"
    echo ""
    read -p "請選擇 [1-7]: " docker_choice
    
    case $docker_choice in
        1)
            echo -e "${BLUE}正在清除 dangling images...${NC}"
            docker image prune -f
            echo -e "${GREEN}✓ Dangling images 清除完成${NC}"
            ;;
        2)
            echo -e "${YELLOW}警告: 這將刪除所有未被容器使用的映像${NC}"
            read -p "確定繼續? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                echo -e "${BLUE}正在清除未使用的映像...${NC}"
                docker image prune -a -f
                echo -e "${GREEN}✓ 未使用的映像清除完成${NC}"
            else
                echo -e "${YELLOW}已取消${NC}"
            fi
            ;;
        3)
            echo -e "${BLUE}正在清除停止的容器...${NC}"
            docker container prune -f
            echo -e "${GREEN}✓ 停止的容器清除完成${NC}"
            ;;
        4)
            echo -e "${BLUE}正在清除未使用的網絡...${NC}"
            docker network prune -f
            echo -e "${GREEN}✓ 未使用的網絡清除完成${NC}"
            ;;
        5)
            echo -e "${YELLOW}警告: 這將刪除所有未被容器使用的卷${NC}"
            read -p "確定繼續? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                echo -e "${BLUE}正在清除未使用的卷...${NC}"
                docker volume prune -f
                echo -e "${GREEN}✓ 未使用的卷清除完成${NC}"
            else
                echo -e "${YELLOW}已取消${NC}"
            fi
            ;;
        6)
            echo -e "${YELLOW}警告: 這將執行完整的 Docker 清理${NC}"
            echo -e "${YELLOW}包括: 停止的容器、未使用的網絡、dangling images${NC}"
            read -p "確定繼續? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                echo -e "${BLUE}正在執行完整清理...${NC}"
                docker system prune -f
                echo -e "${GREEN}✓ Docker 完整清理完成${NC}"
                
                # 顯示清理後的空間
                echo ""
                echo -e "${CYAN}Docker 磁碟使用情況:${NC}"
                docker system df
            else
                echo -e "${YELLOW}已取消${NC}"
            fi
            ;;
        7)
            return
            ;;
        *)
            echo -e "${RED}無效的選擇${NC}"
            ;;
    esac
}

# 查看系統資源
check_system_resources() {
    echo -e "${CYAN}=== 系統資源使用情況 ===${NC}"
    
    echo -e "\n${BLUE}CPU 使用率:${NC}"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "使用: " 100 - $1"%"}'
    
    echo -e "\n${BLUE}內存使用:${NC}"
    free -h
    
    echo -e "\n${BLUE}磁碟使用:${NC}"
    df -h | grep -E "^/dev/"
    
    echo -e "\n${BLUE}系統負載:${NC}"
    uptime
    
    echo -e "\n${BLUE}活躍的服務進程:${NC}"
    ps aux | grep -E "nginx|php-fpm|wings|mysql|redis" | grep -v grep | awk '{print $11, $2, $3, $4}'
}

# 數據庫優化
optimize_database() {
    echo -e "${YELLOW}正在優化數據庫...${NC}"
    
    read -p "請輸入數據庫名稱 [panel]: " DB_NAME
    DB_NAME=${DB_NAME:-panel}
    read -p "請輸入數據庫用戶名 [pterodactyl]: " DB_USER
    DB_USER=${DB_USER:-pterodactyl}
    read -sp "請輸入數據庫密碼: " DB_PASS
    echo ""
    
    echo -e "${BLUE}正在優化所有表...${NC}"
    mysql -u$DB_USER -p$DB_PASS $DB_NAME -e "SHOW TABLES" | grep -v Tables_in | while read table; do
        echo -e "${CYAN}優化表: $table${NC}"
        mysql -u$DB_USER -p$DB_PASS $DB_NAME -e "OPTIMIZE TABLE $table;"
    done
    
    echo -e "${GREEN}✓ 數據庫優化完成！${NC}"
}

# 快速診斷
quick_diagnosis() {
    echo -e "${CYAN}=== 快速診斷 ===${NC}"
    
    echo -e "\n${BLUE}檢查面板目錄權限...${NC}"
    if [ -w "$PANEL_PATH/storage" ]; then
        echo -e "${GREEN}✓ storage 目錄可寫${NC}"
    else
        echo -e "${RED}✗ storage 目錄不可寫${NC}"
    fi
    
    echo -e "\n${BLUE}檢查關鍵服務狀態...${NC}"
    # 檢查 Nginx
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${GREEN}✓ nginx 運行中${NC}"
    else
        echo -e "${RED}✗ nginx 未運行${NC}"
    fi
    
    # 檢查 Wings
    if systemctl is-active --quiet wings 2>/dev/null; then
        echo -e "${GREEN}✓ wings 運行中${NC}"
    else
        echo -e "${RED}✗ wings 未運行${NC}"
    fi
    
    # 檢查 MySQL/MariaDB
    if systemctl is-active --quiet mysql 2>/dev/null; then
        echo -e "${GREEN}✓ mysql 運行中${NC}"
    elif systemctl is-active --quiet mariadb 2>/dev/null; then
        echo -e "${GREEN}✓ mariadb 運行中${NC}"
    else
        echo -e "${RED}✗ mysql/mariadb 未運行${NC}"
    fi
    
    # 檢查 Redis
    if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
        echo -e "${GREEN}✓ redis 運行中${NC}"
    else
        echo -e "${RED}✗ redis 未運行${NC}"
    fi
    
    echo -e "\n${BLUE}檢查 PHP 模塊...${NC}"
    required_modules=("gd" "mbstring" "xml" "curl" "zip")
    for module in "${required_modules[@]}"; do
        if php -m | grep -q "^$module$"; then
            echo -e "${GREEN}✓ $module${NC}"
        else
            echo -e "${RED}✗ $module 缺失${NC}"
        fi
    done
    
    # 檢查 MySQL 相關模組 (mysqli 或 mysqlnd)
    if php -m | grep -qE "^(mysqli|mysqlnd|pdo_mysql)$"; then
        echo -e "${GREEN}✓ mysql (mysqli/mysqlnd/pdo_mysql)${NC}"
    else
        echo -e "${RED}✗ mysql 模組缺失${NC}"
    fi
    
    echo -e "\n${BLUE}檢查磁碟空間...${NC}"
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $disk_usage -lt 80 ]; then
        echo -e "${GREEN}✓ 磁碟空間充足 ($disk_usage%)${NC}"
    else
        echo -e "${YELLOW}! 磁碟空間不足 ($disk_usage%)${NC}"
    fi
}

# 快速維護（進入維護、清除快取、優化）
quick_maintenance() {
    echo -e "${YELLOW}=== 快速維護模式 ===${NC}"
    echo -e "${BLUE}將執行: 進入維護 -> 清除快取 -> 優化面板 -> 重啟服務${NC}"
    read -p "確定繼續? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    echo -e "\n${BLUE}[1/5] 進入維護模式...${NC}"
    cd $PANEL_PATH
    php artisan down
    
    echo -e "\n${BLUE}[2/5] 清除快取...${NC}"
    php artisan view:clear
    php artisan config:clear
    php artisan route:clear
    php artisan cache:clear
    
    echo -e "\n${BLUE}[3/5] 優化面板...${NC}"
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    composer dump-autoload -o
    
    echo -e "\n${BLUE}[4/5] 重啟服務...${NC}"
    systemctl restart nginx
    for v in 8.3 8.2 8.1 8.0; do
        if systemctl list-unit-files | grep -q "php${v}-fpm"; then
            systemctl restart php${v}-fpm
            break
        fi
    done
    
    echo -e "\n${BLUE}[5/5] 退出維護模式...${NC}"
    php artisan up
    
    echo -e "\n${GREEN}✓ 快速維護完成！${NC}"
}

# Wings 管理子菜單
wings_management() {
    while true; do
        clear
        echo -e "${CYAN}=== Wings 管理 ===${NC}"
        echo ""
        echo "1. 重啟 Wings"
        echo "2. 查看 Wings 狀態"
        echo "3. 查看 Wings 日誌"
        echo "4. 停止 Wings"
        echo "5. 啟動 Wings"
        echo "6. 重新加載 Wings 配置"
        echo "7. Wings 診斷"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-7]: " wing_choice
        
        case $wing_choice in
            1)
                systemctl restart wings
                echo -e "${GREEN}✓ Wings 已重啟${NC}"
                ;;
            2)
                systemctl status wings --no-pager -l
                ;;
            3)
                journalctl -u wings -n 50 --no-pager
                ;;
            4)
                systemctl stop wings
                echo -e "${YELLOW}Wings 已停止${NC}"
                ;;
            5)
                systemctl start wings
                echo -e "${GREEN}✓ Wings 已啟動${NC}"
                ;;
            6)
                systemctl reload wings
                echo -e "${GREEN}✓ 配置已重新加載${NC}"
                ;;
            7)
                echo -e "${CYAN}Wings 診斷信息:${NC}"
                echo -e "\n${BLUE}服務狀態:${NC}"
                systemctl is-active wings && echo -e "${GREEN}運行中${NC}" || echo -e "${RED}已停止${NC}"
                echo -e "\n${BLUE}配置文件:${NC}"
                [ -f /etc/pterodactyl/config.yml ] && echo -e "${GREEN}✓ 存在${NC}" || echo -e "${RED}✗ 缺失${NC}"
                echo -e "\n${BLUE}最近的錯誤:${NC}"
                journalctl -u wings --since "1 hour ago" | grep -i error | tail -5
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}無效的選擇${NC}"
                ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 快速構建面板 (安裝)
quick_install() {
    echo -e "${YELLOW}此功能將引導你安裝 Pterodactyl 面板${NC}"
    echo -e "${RED}警告: 這將執行完整的安裝流程${NC}"
    read -p "確定要繼續嗎? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    echo -e "${BLUE}開始安裝依賴...${NC}"
    
    # 檢測系統
    if [ -f /etc/debian_version ]; then
        apt update
        apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        apt update
        apt install -y php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} nginx mariadb-server redis-server
    elif [ -f /etc/redhat-release ]; then
        dnf install -y epel-release
        dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
        dnf module enable -y php:remi-8.1
        dnf install -y php php-{common,fpm,cli,json,mysqlnd,gd,mbstring,pdo,zip,bcmath,dom,opcache} nginx mariadb-server redis
    fi
    
    echo -e "${GREEN}✓ 依賴安裝完成${NC}"
    echo -e "${YELLOW}請參考官方文檔完成後續配置: https://pterodactyl.io/panel/1.0/getting_started.html${NC}"
}

# 卸載工具
uninstall_tool() {
    echo -e "${RED}=== 卸載 Pterodactyl 管理工具 ===${NC}"
    echo -e "${YELLOW}警告: 此操作將移除已安裝的管理工具${NC}"
    echo -e "${YELLOW}這不會影響 Pterodactyl 面板本身${NC}"
    echo ""
    read -p "確定要卸載嗎? (輸入 YES 確認): " confirm
    
    if [ "$confirm" != "YES" ]; then
        echo -e "${GREEN}已取消卸載${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}正在卸載...${NC}"
    
    # 檢查並移除主工具
    if [ -f "/usr/local/bin/ptero-manager" ]; then
        sudo rm /usr/local/bin/ptero-manager
        echo -e "${GREEN}✓ 已移除 ptero-manager${NC}"
    else
        echo -e "${YELLOW}! ptero-manager 未找到${NC}"
    fi
    
    # 檢查並移除快速命令工具（如果存在）
    if [ -f "/usr/local/bin/ptero-quick" ]; then
        sudo rm /usr/local/bin/ptero-quick
        echo -e "${GREEN}✓ 已移除 ptero-quick${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✓ 卸載完成！${NC}"
    echo -e "${CYAN}感謝使用 Pterodactyl 管理工具${NC}"
    echo ""
    read -p "按Enter鍵退出..."
    exit 0
}

# 安裝 Arix 主題
install_arix_theme() {
    echo -e "${YELLOW}=== 安裝 Arix 主題 ===${NC}"
    
    cd $PANEL_PATH
    
    echo -e "${BLUE}正在安裝 Arix 主題...${NC}"
    php artisan arix install
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Arix 主題安裝完成！${NC}"
        echo -e "${CYAN}請重新整理瀏覽器以查看變更${NC}"
    else
        echo -e "${RED}✗ 安裝失敗${NC}"
    fi
}

# 更新 Arix 主題
update_arix_theme() {
    echo -e "${YELLOW}=== 更新 Arix 主題 ===${NC}"
    
    cd $PANEL_PATH
    
    echo -e "${BLUE}正在更新 Arix 主題到最新版本...${NC}"
    php artisan arix update
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Arix 主題更新完成！${NC}"
        echo -e "${CYAN}請重新整理瀏覽器以查看變更${NC}"
    else
        echo -e "${RED}✗ 更新失敗${NC}"
    fi
}

# 卸載 Arix 主題
uninstall_arix_theme() {
    echo -e "${RED}=== 卸載 Arix 主題 ===${NC}"
    echo -e "${YELLOW}這將還原為預設主題${NC}"
    read -p "確定要卸載 Arix 主題嗎? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        return
    fi
    
    cd $PANEL_PATH
    
    echo -e "${BLUE}正在卸載 Arix 主題...${NC}"
    php artisan arix uninstall
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 已還原為預設主題${NC}"
        echo -e "${CYAN}請重新整理瀏覽器以查看變更${NC}"
    else
        echo -e "${RED}✗ 卸載失敗${NC}"
    fi
}

# 修復 Arix 主題
repair_arix_theme() {
    echo -e "${YELLOW}=== 修復 Arix 主題 ===${NC}"
    
    cd $PANEL_PATH
    
    echo -e "${BLUE}[1/3] 清除所有快取...${NC}"
    php artisan view:clear
    php artisan config:clear
    php artisan route:clear
    php artisan cache:clear
    
    echo -e "${BLUE}[2/3] 修復權限...${NC}"
    # 獲取web服務器用戶
    WEB_USER="www-data"
    if [ -f /etc/redhat-release ]; then
        WEB_USER="nginx"
    fi
    chown -R $WEB_USER:$WEB_USER resources/views
    chmod -R 755 resources/views
    
    echo -e "${BLUE}[3/3] 重新編譯視圖...${NC}"
    php artisan view:cache
    
    echo -e "${GREEN}✓ Arix 主題修復完成！${NC}"
}

# Arix 主題管理子菜單
arix_theme_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Arix 主題管理 ===${NC}"
        echo ""
        echo "1. 安裝 Arix 主題"
        echo "2. 更新 Arix 主題"
        echo "3. 卸載 Arix 主題"
        echo "4. 修復 Arix 主題"
        echo "5. 清除主題快取"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-5]: " choice
        
        case $choice in
            1) install_arix_theme ;;
            2) update_arix_theme ;;
            3) uninstall_arix_theme ;;
            4) repair_arix_theme ;;
            5)
                cd $PANEL_PATH
                php artisan view:clear
                php artisan config:clear
                echo -e "${GREEN}✓ 主題快取已清除${NC}"
                ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 快取與優化子菜單
cache_optimization_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== 快取與優化 ===${NC}"
        echo ""
        echo "1. 清除快取"
        echo "2. 優化面板"
        echo "3. 快速維護 (一鍵維護+優化+重啟)"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-3]: " choice
        
        case $choice in
            1) clear_cache ;;
            2) optimize_panel ;;
            3) quick_maintenance ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 維護模式子菜單
maintenance_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== 維護模式 ===${NC}"
        echo ""
        echo "1. 進入維護模式"
        echo "2. 退出維護模式"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-2]: " choice
        
        case $choice in
            1) enter_maintenance ;;
            2) exit_maintenance ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 服務管理子菜單
service_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== 服務管理 ===${NC}"
        echo ""
        echo "1. 重啟面板服務 (Nginx/PHP-FPM/Redis)"
        echo "2. 查看服務狀態"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-2]: " choice
        
        case $choice in
            1) restart_panel_services ;;
            2)
                echo -e "${CYAN}=== 服務狀態 ===${NC}"
                check_wings_status
                echo ""
                echo -e "${BLUE}Nginx:${NC} $(systemctl is-active nginx)"
                echo -e "${BLUE}Redis:${NC} $(systemctl is-active redis 2>/dev/null || echo 'inactive')"
                for v in 8.3 8.2 8.1 8.0; do
                    if systemctl list-unit-files | grep -q "php${v}-fpm"; then
                        echo -e "${BLUE}PHP-FPM:${NC} $(systemctl is-active php${v}-fpm)"
                        break
                    fi
                done
                ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 系統維護子菜單
system_maintenance_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== 系統維護 ===${NC}"
        echo ""
        echo "1. 更新面板"
        echo "2. 修復權限"
        echo "3. 備份面板"
        echo "4. 數據庫優化"
        echo "5. Docker 清理"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-5]: " choice
        
        case $choice in
            1) update_panel ;;
            2) fix_permissions ;;
            3) backup_panel ;;
            4) optimize_database ;;
            5) clean_docker ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 診斷與日誌子菜單
diagnostics_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== 診斷與日誌 ===${NC}"
        echo ""
        echo "1. 快速診斷"
        echo "2. 查看日誌"
        echo "3. 清理舊日誌"
        echo "4. 查看系統資源"
        echo "5. 查看版本信息"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-5]: " choice
        
        case $choice in
            1) quick_diagnosis ;;
            2) view_logs ;;
            3) clean_old_logs ;;
            4) check_system_resources ;;
            5) check_panel_version ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 安裝與卸載子菜單
install_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== 安裝與卸載 ===${NC}"
        echo ""
        echo "1. 快速安裝面板"
        echo "2. 卸載此管理工具"
        echo "0. 返回主菜單"
        echo ""
        read -p "請選擇 [0-2]: " choice
        
        case $choice in
            1) quick_install ;;
            2) uninstall_tool ;;
            0) return ;;
            *) echo -e "${RED}無效的選擇${NC}" ;;
        esac
        echo ""
        read -p "按Enter鍵繼續..."
    done
}

# 主菜單
show_menu() {
    show_header
    echo -e "${GREEN}請選擇功能類別:${NC}"
    echo ""
    echo "  1. 快取與優化"
    echo "  2. 維護模式"
    echo "  3. Wings 管理"
    echo "  4. 服務管理"
    echo "  5. 系統維護"
    echo "  6. 診斷與日誌"
    echo "  7. Arix 主題管理"
    echo "  8. 安裝與卸載"
    echo ""
    echo -e "  ${RED}0. 退出${NC}"
    echo ""
    echo -e "${CYAN}================================================${NC}"
    read -p "請輸入選項 [0-8]: " choice
    echo ""
    
    case $choice in
        1)
            cache_optimization_menu
            ;;
        2)
            maintenance_menu
            ;;
        3)
            wings_management
            ;;
        4)
            service_menu
            ;;
        5)
            system_maintenance_menu
            ;;
        6)
            diagnostics_menu
            ;;
        7)
            arix_theme_menu
            ;;
        8)
            install_menu
            ;;
        0)
            echo -e "${GREEN}感謝使用！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}無效的選項，請重新選擇${NC}"
            ;;
    esac
    
    echo ""
    read -p "按Enter鍵繼續..."
}

# 主程序
main() {
    check_root
    check_panel_path
    
    while true; do
        show_menu
    done
}

# 執行主程序
main
