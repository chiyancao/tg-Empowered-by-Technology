#!/bin/bash

# ============================================================================
# SSH登录通知配置脚本
# 作者: Auto Generated
# 版本: 1.0
# 修复: 确保系统状态、登录历史和在线用户列表正确显示
# ============================================================================

# 颜色和样式定义
COLOR_RESET="\033[0m"
COLOR_BLACK="\033[30m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[37m"
COLOR_BOLD="\033[1m"
COLOR_DIM="\033[2m"
COLOR_ITALIC="\033[3m"
COLOR_UNDERLINE="\033[4m"
COLOR_BLINK="\033[5m"
COLOR_REVERSE="\033[7m"

# 配置文件路径
CONFIG_DIR="/etc/ssh-notify"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_FILE="/var/log/ssh-notify.log"
NOTIFY_SCRIPT="$CONFIG_DIR/notify.sh"
LOCK_DIR="/tmp/ssh-notify-locks"

# 创建必要的目录
create_directories() {
    echo -e "${COLOR_CYAN}正在创建必要的目录...${COLOR_RESET}"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$LOCK_DIR"
    echo -e "${COLOR_GREEN}✓ 目录创建完成${COLOR_RESET}"
}

# 打印横幅
print_banner() {
    clear
    echo -e "${COLOR_BLUE}${COLOR_BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║  ███████╗███████╗██╗  ██╗     ███████╗ ██████╗ ████████╗██╗███████╗██╗   ██╗ ║"
    echo "║  ██╔════╝██╔════╝██║  ██║     ██╔════╝██╔═══██╗╚══██╔══╝██║██╔════╝╚██╗ ██╔╝ ║"
    echo "║  ███████╗███████╗███████║     █████╗  ██║   ██║   ██║   ██║█████╗   ╚████╔╝  ║"
    echo "║  ╚════██║╚════██║██╔══██║     ██╔══╝  ██║   ██║   ██║   ██║██╔══╝    ╚██╔╝   ║"
    echo "║  ███████║███████║██║  ██║     ██║     ╚██████╔╝   ██║   ██║███████╗   ██║    ║"
    echo "║  ╚══════╝╚══════╝╚═╝  ╚═╝     ╚═╝      ╚═════╝    ╚═╝   ╚═╝╚══════╝   ╚═╝    ║"
    echo "║                                                                              ║"
    echo "║                   SSH登录通知系统配置工具 v2.6                              ║"
    echo "║          修复系统状态、登录历史和在线用户列表正确显示的问题                 ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${COLOR_RESET}"
}

# 打印菜单
print_menu() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}主菜单${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    echo -e "  ${COLOR_GREEN}1${COLOR_RESET}.  ${COLOR_BOLD}配置Gotify服务器${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}2${COLOR_RESET}.  ${COLOR_BOLD}启用SSH登录通知${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}3${COLOR_RESET}.  ${COLOR_BOLD}禁用SSH登录通知${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}4${COLOR_RESET}.  ${COLOR_BOLD}测试通知发送${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}5${COLOR_RESET}.  ${COLOR_BOLD}查看当前配置${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}6${COLOR_RESET}.  ${COLOR_BOLD}查看日志文件${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}7${COLOR_RESET}.  ${COLOR_BOLD}手动触发测试登录${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}8${COLOR_RESET}.  ${COLOR_BOLD}系统状态检查${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}9${COLOR_RESET}.  ${COLOR_BOLD}卸载配置${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}0${COLOR_RESET}.  ${COLOR_BOLD}退出${COLOR_RESET}"
    echo -e ""
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
}

# 检查依赖
check_dependencies() {
    echo -e "${COLOR_CYAN}正在检查依赖...${COLOR_RESET}"
    
    local missing_deps=()
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # 检查jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    # 检查geoip-bin
    if ! command -v geoiplookup &> /dev/null; then
        missing_deps+=("geoip-bin")
    fi
    
    # 检查bc（用于计算）
    if ! command -v bc &> /dev/null; then
        missing_deps+=("bc")
    fi
    
    # 检查who和last
    if ! command -v who &> /dev/null; then
        missing_deps+=("util-linux")
    fi
    
    if ! command -v last &> /dev/null; then
        missing_deps+=("util-linux")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${COLOR_YELLOW}⚠ 缺少以下依赖包: ${missing_deps[*]}${COLOR_RESET}"
        read -p "是否自动安装? (y/n): " install_choice
        
        if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
            if command -v apt-get &> /dev/null; then
                echo -e "${COLOR_CYAN}使用APT包管理器安装依赖...${COLOR_RESET}"
                apt-get update
                apt-get install -y curl jq geoip-bin bc util-linux
            elif command -v yum &> /dev/null; then
                echo -e "${COLOR_CYAN}使用YUM包管理器安装依赖...${COLOR_RESET}"
                yum install -y curl jq GeoIP bc util-linux
            elif command -v dnf &> /dev/null; then
                echo -e "${COLOR_CYAN}使用DNF包管理器安装依赖...${COLOR_RESET}"
                dnf install -y curl jq GeoIP bc util-linux
            else
                echo -e "${COLOR_RED}✗ 无法识别包管理器，请手动安装依赖:${COLOR_RESET}"
                echo -e "  ${missing_deps[*]}"
                return 1
            fi
            
            # 验证安装
            for dep in "${missing_deps[@]}"; do
                if command -v "${dep}" &> /dev/null; then
                    echo -e "${COLOR_GREEN}✓ 已安装: $dep${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}✗ 安装失败: $dep${COLOR_RESET}"
                    return 1
                fi
            done
        else
            echo -e "${COLOR_RED}✗ 请手动安装依赖后再运行脚本${COLOR_RESET}"
            return 1
        fi
    fi
    
    echo -e "${COLOR_GREEN}✓ 所有依赖已满足${COLOR_RESET}"
    return 0
}

# 初始化配置
init_config() {
    echo -e "${COLOR_CYAN}正在初始化配置...${COLOR_RESET}"
    
    # 获取系统信息
    local hostname=$(hostname)
    local public_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "未知")
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$CONFIG_FILE" << EOF
# SSH登录通知配置文件
# 生成时间: $current_time
# 主机名: $hostname

# ========== Gotify服务器配置 ==========
GOTIFY_SERVER=""
GOTIFY_TOKEN=""

# ========== 通知设置 ==========
# 成功登录通知
ENABLE_LOGIN_SUCCESS=true
# 失败登录通知 (谨慎启用，可能产生大量通知)
ENABLE_LOGIN_FAILURE=false
# 地理位置信息
ENABLE_GEO_IP=true
# 系统状态信息
ENABLE_SYSTEM_INFO=true
# 详细登录历史
ENABLE_DETAILED_INFO=true
# 在线用户信息 (新增功能)
ENABLE_ONLINE_USERS=true

# ========== 高级设置 ==========
# 通知优先级 (0-10, 10为最高)
NORMAL_PRIORITY=5
ROOT_PRIORITY=10
FAILURE_PRIORITY=9
# 重试次数
RETRY_COUNT=3
# 超时时间(秒)
TIMEOUT_SECONDS=10
# 日志级别: DEBUG, INFO, WARN, ERROR
LOG_LEVEL="INFO"

# ========== 系统信息 ==========
HOSTNAME="$hostname"
PUBLIC_IP="$public_ip"
LAST_CONFIG="$current_time"
EOF
    
    echo -e "${COLOR_GREEN}✓ 配置初始化完成${COLOR_RESET}"
}

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        if source "$CONFIG_FILE" 2>/dev/null; then
            return 0
        else
            echo -e "${COLOR_RED}✗ 配置文件格式错误${COLOR_RESET}"
            return 1
        fi
    else
        echo -e "${COLOR_YELLOW}⚠ 配置文件不存在，正在初始化...${COLOR_RESET}"
        init_config
        return $?
    fi
}

# 配置Gotify服务器
configure_gotify() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}配置Gotify服务器${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    echo -e "${COLOR_YELLOW}📝 步骤1: 输入Gotify服务器信息${COLOR_RESET}"
    echo -e ""
    
    # 显示当前配置
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null
        if [ -n "$GOTIFY_SERVER" ] && [ -n "$GOTIFY_TOKEN" ]; then
            echo -e "${COLOR_GREEN}当前已配置:${COLOR_RESET}"
            echo -e "  服务器: ${COLOR_CYAN}$GOTIFY_SERVER${COLOR_RESET}"
            echo -e "  Token: ${COLOR_CYAN}${GOTIFY_TOKEN:0:10}...${COLOR_RESET}"
            echo -e ""
            read -p "是否重新配置? (y/n): " reconfigure
            if [[ $reconfigure != "y" && $reconfigure != "Y" ]]; then
                return 0
            fi
        fi
    fi
    
    # 输入服务器地址
    echo -e "${COLOR_BLUE}请输入Gotify服务器地址:${COLOR_RESET}"
    echo -e "格式示例: ${COLOR_DIM}https://gotify.example.com${COLOR_RESET} 或 ${COLOR_DIM}http://192.168.1.100:8080${COLOR_RESET}"
    read -p "> " gotify_server
    
    # 移除末尾的斜杠
    gotify_server=$(echo "$gotify_server" | sed 's#/$##')
    
    # 验证URL格式
    if [[ ! $gotify_server =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$ ]]; then
        echo -e "${COLOR_RED}✗ 无效的服务器地址格式${COLOR_RESET}"
        return 1
    fi
    
    # 输入Token
    echo -e ""
    echo -e "${COLOR_BLUE}请输入Application Token:${COLOR_RESET}"
    echo -e "提示: 在Gotify Web界面中创建应用后获取"
    read -p "> " gotify_token
    
    if [ -z "$gotify_token" ]; then
        echo -e "${COLOR_RED}✗ Token不能为空${COLOR_RESET}"
        return 1
    fi
    
    # 测试连接
    echo -e ""
    echo -e "${COLOR_YELLOW}正在测试连接...${COLOR_RESET}"
    
    if curl -s -X GET "$gotify_server/version" --connect-timeout 10 -H "X-Gotify-Key: $gotify_token" &>/dev/null; then
        echo -e "${COLOR_GREEN}✓ 服务器连接成功${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}⚠ 无法连接到服务器，但仍将继续配置${COLOR_RESET}"
        read -p "是否继续? (y/n): " continue_choice
        if [[ $continue_choice != "y" && $continue_choice != "Y" ]]; then
            return 1
        fi
    fi
    
    # 保存配置
    sed -i "s|GOTIFY_SERVER=.*|GOTIFY_SERVER=\"$gotify_server\"|" "$CONFIG_FILE"
    sed -i "s|GOTIFY_TOKEN=.*|GOTIFY_TOKEN=\"$gotify_token\"|" "$CONFIG_FILE"
    sed -i "s|LAST_CONFIG=.*|LAST_CONFIG=\"$(date '+%Y-%m-%d %H:%M:%S')\"|" "$CONFIG_FILE"
    
    load_config
    
    # 发送测试通知
    echo -e ""
    echo -e "${COLOR_YELLOW}发送测试通知...${COLOR_RESET}"
    send_test_notification
    
    echo -e ""
    echo -e "${COLOR_GREEN}✅ Gotify配置完成！${COLOR_RESET}"
    echo -e ""
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 发送测试通知
send_test_notification() {
    if [ -z "$GOTIFY_SERVER" ] || [ -z "$GOTIFY_TOKEN" ]; then
        echo -e "${COLOR_RED}✗ Gotify未配置，无法发送测试通知${COLOR_RESET}"
        return 1
    fi
    
    local hostname=$(hostname)
    local public_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo '未知')
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 使用数组构建测试消息
    local test_parts=()
    test_parts+=("🚀 **SSH通知系统测试成功！**")
    test_parts+=("")
    test_parts+=("✅ **配置验证**")
    test_parts+=("   - 服务器连接: 成功")
    test_parts+=("   - 时间: $current_time")
    test_parts+=("   - 主机: $hostname")
    test_parts+=("   - IP: $public_ip")
    test_parts+=("")
    test_parts+=("📊 **系统信息**")
    test_parts+=("   - 内存: $(free -m | awk 'NR==2 {if ($2>0) printf "%.1f%%", $3*100/$2; else print "未知"}' 2>/dev/null || echo "未知")")
    test_parts+=("   - 磁盘: $(df -h / | awk 'NR==2 {print $5}' 2>/dev/null || echo "未知")")
    test_parts+=("   - 负载: $(uptime | awk -F'load average:' '{print $2}' | xargs 2>/dev/null || echo "未知")")
    test_parts+=("   - 在线用户: $(who | wc -l 2>/dev/null || echo "0") 人")
    test_parts+=("")
    test_parts+=("🔧 **下一步**")
    test_parts+=("   1. 启用SSH登录通知")
    test_parts+=("   2. 测试实际登录")
    test_parts+=("   3. 查看日志文件")
    test_parts+=("")
    test_parts+=("---")
    test_parts+=("*系统自动发送 - SSH通知系统 v2.6*")
    
    # 将数组转换为字符串
    local test_message=""
    for part in "${test_parts[@]}"; do
        test_message+="$part"$'\n'
    done
    
    # 修复：使用临时变量存储响应
    local response
    local http_code
    
    # 使用curl的-o选项输出到文件，-w选项获取HTTP状态码
    local temp_file=$(mktemp)
    http_code=$(curl -s -o "$temp_file" -w "%{http_code}" -X POST "$GOTIFY_SERVER/message?token=$GOTIFY_TOKEN" \
        -F "title=🎉 SSH通知系统测试" \
        -F "message=$test_message" \
        -F "priority=5" \
        -F "extras={\"client::display\":{\"contentType\":\"text/markdown\"}}" \
        --connect-timeout 10 \
        --max-time 10)
    
    # 读取响应内容
    if [ -f "$temp_file" ]; then
        response=$(cat "$temp_file")
        rm -f "$temp_file"
    else
        response=""
    fi
    
    if [[ $http_code == "200" ]]; then
        echo -e "${COLOR_GREEN}✓ 测试通知发送成功！${COLOR_RESET}"
        echo -e "${COLOR_CYAN}消息已发送到: $GOTIFY_SERVER${COLOR_RESET}"
        echo -e "${COLOR_DIM}响应: $response${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}✗ 测试通知发送失败 (HTTP: $http_code)${COLOR_RESET}"
        if [ -n "$response" ]; then
            echo -e "${COLOR_YELLOW}错误信息: $response${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}请检查网络连接和Gotify配置${COLOR_RESET}"
        fi
        return 1
    fi
}

# 创建通知脚本 (完全修复版本)
create_notify_script() {
    echo -e "${COLOR_CYAN}正在创建通知脚本...${COLOR_RESET}"
    
    cat > "$NOTIFY_SCRIPT" << 'EOF'
#!/bin/bash

# ============================================================================
# SSH登录通知脚本 v2.6
# 由PAM在SSH登录时调用
# 修复：确保系统状态、登录历史和在线用户列表正确显示
# ============================================================================

# ============================================================================
# 配置加载
# ============================================================================
CONFIG_FILE="/etc/ssh-notify/config.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE" 2>/dev/null || exit 0
else
    exit 0
fi

# ============================================================================
# 常量定义
# ============================================================================
LOCK_DIR="/tmp/ssh-notify-locks"
mkdir -p "$LOCK_DIR"

# ============================================================================
# 日志函数
# ============================================================================
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="/var/log/ssh-notify.log"
    
    # 根据日志级别过滤
    case "$LOG_LEVEL" in
        "DEBUG")
            echo "[$timestamp] [$level] $message" >> "$log_file"
            ;;
        "INFO")
            if [[ "$level" != "DEBUG" ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file"
            fi
            ;;
        "WARN")
            if [[ "$level" != "DEBUG" && "$level" != "INFO" ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file"
            fi
            ;;
        "ERROR")
            if [[ "$level" == "ERROR" ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file"
            fi
            ;;
        *)
            # 默认记录INFO及以上
            if [[ "$level" != "DEBUG" ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file"
            fi
            ;;
    esac
}

# ============================================================================
# 工具函数
# ============================================================================

# 去重检查函数
check_duplicate_notification() {
    local username="$1"
    local client_ip="$2"
    local login_type="$3"
    
    # 创建锁文件名称（基于用户、IP和类型）
    local lock_file="$LOCK_DIR/${username}_${client_ip}_${login_type}.lock"
    
    # 检查锁文件是否存在且未过期（10秒内）
    if [ -f "$lock_file" ]; then
        local lock_time=$(stat -c %Y "$lock_file" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local time_diff=$((current_time - lock_time))
        
        # 如果10秒内已有相同通知，则跳过
        if [ $time_diff -lt 10 ]; then
            log "DEBUG" "检测到重复通知，跳过：用户=$username, IP=$client_ip, 类型=$login_type"
            return 1
        fi
    fi
    
    # 创建/更新锁文件
    touch "$lock_file"
    
    # 清理旧锁文件（超过60秒）
    find "$LOCK_DIR" -name "*.lock" -type f -mmin +1 -delete 2>/dev/null
    
    return 0
}

# 获取地理位置信息
get_geo_info() {
    local ip="$1"
    local geo_info=""
    
    # 跳过本地和私有IP
    if [[ "$ip" == "127.0.0.1" ]] || [[ "$ip" == "localhost" ]] || \
       [[ "$ip" =~ ^10\. ]] || [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || \
       [[ "$ip" =~ ^192\.168\. ]]; then
        echo "内网地址"
        return
    fi
    
    # 尝试使用geoip
    if command -v geoiplookup &> /dev/null; then
        geo_info=$(geoiplookup "$ip" 2>/dev/null | grep -v "GeoIP Country Edition" | head -1)
        if [ -n "$geo_info" ]; then
            echo "$geo_info" | sed 's/GeoIP City Edition, Rev [0-9]*: //'
            return
        fi
    fi
    
    # 备用API（ip-api.com）- 增加重试机制
    if command -v curl &> /dev/null; then
        for i in {1..3}; do
            geo_info=$(curl -s "http://ip-api.com/json/$ip?lang=zh-CN&fields=status,message,country,regionName,city,isp" \
                --connect-timeout 5 --max-time 10 2>/dev/null || echo "")
            
            if [ -n "$geo_info" ] && echo "$geo_info" | grep -q '"status":"success"'; then
                local country=$(echo "$geo_info" | jq -r '.country // "未知"' 2>/dev/null || echo "未知")
                local region=$(echo "$geo_info" | jq -r '.regionName // "未知"' 2>/dev/null || echo "未知")
                local city=$(echo "$geo_info" | jq -r '.city // "未知"' 2>/dev/null || echo "未知")
                local isp=$(echo "$geo_info" | jq -r '.isp // "未知"' 2>/dev/null || echo "未知")
                echo "$country, $region, $city ($isp)"
                return
            fi
            sleep 1
        done
    fi
    
    echo "未知位置"
}

# 获取系统信息（修复：简化且确保能执行）
get_system_info() {
    local info_lines=()
    
    # 系统负载
    local load="未知"
    if [ -f /proc/loadavg ]; then
        load=$(cat /proc/loadavg 2>/dev/null | awk '{printf "%.2f, %.2f, %.2f", $1, $2, $3}' || echo "未知")
    else
        load=$(uptime 2>/dev/null | grep -o "load average:.*" | cut -d: -f2 | xargs || echo "未知")
    fi
    info_lines+=("   - 负载: $load")
    
    # 内存使用
    local mem_usage="未知"
    if command -v free &> /dev/null; then
        mem_usage=$(free -m 2>/dev/null | awk 'NR==2 {if ($2>0) printf "%.1f%%", $3*100/$2; else print "未知"}' || echo "未知")
    fi
    info_lines+=("   - 内存: $mem_usage")
    
    # 磁盘使用
    local disk_usage="未知"
    if command -v df &> /dev/null; then
        disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' || echo "未知")
    fi
    info_lines+=("   - 根分区: $disk_usage")
    
    # 在线用户数
    local users="0"
    if command -v who &> /dev/null; then
        users=$(who 2>/dev/null | wc -l 2>/dev/null || echo "0")
    fi
    info_lines+=("   - 在线用户: $users")
    
    # 运行时间 - 简化方法
    local uptime_str="未知"
    if [ -f /proc/uptime ]; then
        local uptime_seconds=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
        if [ -n "$uptime_seconds" ]; then
            local days=$((uptime_seconds / 86400))
            local hours=$((uptime_seconds % 86400 / 3600))
            if [ $days -gt 0 ]; then
                uptime_str="${days}天${hours}小时"
            else
                uptime_str="${hours}小时"
            fi
        fi
    fi
    info_lines+=("   - 运行时间: $uptime_str")
    
    # SSH连接数 - 简化方法
    local ssh_connections="0"
    if command -v ss &> /dev/null; then
        ssh_connections=$(ss -tn 2>/dev/null | grep -E ':(22|ssh)' | grep ESTAB | wc -l 2>/dev/null || echo "0")
    fi
    info_lines+=("   - SSH连接: $ssh_connections")
    
    # 将数组转换为字符串，用换行符连接
    local info=""
    for line in "${info_lines[@]}"; do
        info+="$line"$'\n'
    done
    
    echo "$info"
}

# 获取在线用户信息（修复：确保返回格式正确）
get_online_users() {
    local online_users=""
    
    # 使用who命令获取在线用户
    if command -v who &> /dev/null; then
        # 获取在线用户总数
        local total_users=0
        total_users=$(who 2>/dev/null | wc -l 2>/dev/null || echo "0")
        
        log "INFO" "在线用户总数: $total_users"
        
        if [ "$total_users" -eq 0 ]; then
            echo "   无在线用户"
            return
        fi
        
        # 详细在线用户列表（最多显示5个）
        online_users=$(who 2>/dev/null | head -5 | while IFS= read -r line; do
            # 解析who命令输出
            local user=$(echo "$line" | awk '{print $1}')
            local terminal=$(echo "$line" | awk '{print $2}')
            local login_time=$(echo "$line" | awk '{print $3 " " $4}')
            
            # 提取IP地址（可能在括号中）
            local ip_address="本地"
            if [[ "$line" =~ \([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\) ]]; then
                ip_address=$(echo "$line" | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | head -1 | tr -d '()')
            elif [[ "$line" =~ \([a-zA-Z0-9.-]+\) ]]; then
                ip_address=$(echo "$line" | grep -oE '\([a-zA-Z0-9.-]+\)' | head -1 | tr -d '()')
            fi
            
            echo "   - $user ($ip_address) - $terminal - $login_time"
        done)
        
        # 如果用户数超过5，添加统计信息
        if [ "$total_users" -gt 5 ]; then
            online_users+=$'\n'"    ... 还有 $((total_users - 5)) 个用户未显示"
        fi
        
        echo "$online_users"
    else
        echo "   who命令不可用"
    fi
}

# 获取登录历史（修复：简化且确保能执行）
get_login_history() {
    local username="$1"
    local history=""
    
    # 尝试使用last命令获取登录历史
    if command -v last &> /dev/null; then
        # 获取最近5次登录记录，简化输出
        history=$(last -5 "$username" 2>/dev/null | head -5 | while IFS= read -r line; do
            if [[ "$line" =~ ^$username ]]; then
                local ip=$(echo "$line" | awk '{print $3}')
                local date_time=$(echo "$line" | awk '{print $4 " " $5 " " $6 " " $7}')
                if [ "$ip" != "" ] && [ "$date_time" != "" ]; then
                    echo "   - $ip - $date_time"
                fi
            fi
        done)
    fi
    
    if [ -z "$history" ] || [ "$history" = "" ]; then
        echo "   无历史记录"
    else
        echo "$history"
    fi
}

# 构造Markdown消息（修复：确保所有部分都能正确添加）
construct_message() {
    local login_type="$1"
    local username="$2"
    local client_ip="$3"
    
    # 记录调试信息
    log "INFO" "开始构造消息: 类型=$login_type, 用户=$username, IP=$client_ip"
    
    # 获取地理位置
    local geo_info=""
    if [ "$ENABLE_GEO_IP" = "true" ] && [ -n "$client_ip" ] && [ "$client_ip" != "unknown" ]; then
        log "INFO" "获取地理位置信息..."
        geo_info=$(get_geo_info "$client_ip")
        log "INFO" "地理位置: $geo_info"
    fi
    
    # 获取系统信息
    local system_info=""
    if [ "$ENABLE_SYSTEM_INFO" = "true" ]; then
        log "INFO" "获取系统信息..."
        system_info=$(get_system_info)
        log "INFO" "系统信息获取完成，长度: ${#system_info}"
    fi
    
    # 获取在线用户信息
    local online_users_info=""
    if [ "$ENABLE_ONLINE_USERS" = "true" ]; then
        log "INFO" "获取在线用户信息..."
        online_users_info=$(get_online_users)
        log "INFO" "在线用户信息获取完成，长度: ${#online_users_info}"
    fi
    
    # 获取登录历史
    local login_history=""
    if [ "$ENABLE_DETAILED_INFO" = "true" ]; then
        log "INFO" "获取登录历史..."
        login_history=$(get_login_history "$username")
        log "INFO" "登录历史获取完成，长度: ${#login_history}"
    fi
    
    # 获取当前会话
    local current_sessions=0
    if command -v who &> /dev/null; then
        current_sessions=$(who 2>/dev/null | grep -c "^$username" 2>/dev/null || echo "0")
    fi
    log "INFO" "当前会话数: $current_sessions"
    
    # 构造标题和图标
    local icon=""
    local title=""
    local priority="$NORMAL_PRIORITY"
    
    case "$login_type" in
        "success")
            icon="✅"
            title="SSH登录成功 - $HOSTNAME"
            priority="$NORMAL_PRIORITY"
            ;;
        "success_root")
            icon="👑"
            title="ROOT用户登录 - $HOSTNAME"
            priority="$ROOT_PRIORITY"
            ;;
        "failure")
            icon="❌"
            title="SSH登录失败 - $HOSTNAME"
            priority="$FAILURE_PRIORITY"
            ;;
        *)
            icon="🔔"
            title="SSH登录事件 - $HOSTNAME"
            priority="$NORMAL_PRIORITY"
            ;;
    esac
    
    # 用户组信息
    local user_group="未知"
    if command -v id &> /dev/null; then
        user_group=$(id -gn "$username" 2>/dev/null || echo "未知")
    fi
    
    # 使用数组和字符串拼接构建消息
    local message_parts=()
    
    # 标题部分
    message_parts+=("$icon **$title**")
    message_parts+=("")  # 空行
    
    # 用户信息部分
    message_parts+=("👤 **用户信息**")
    message_parts+=("   - 用户名: \`$username\`")
    message_parts+=("   - 用户组: \`$user_group\`")
    message_parts+=("   - 当前会话: $current_sessions 个")
    message_parts+=("   - 登录时间: $(date '+%Y-%m-%d %H:%M:%S')")
    message_parts+=("")  # 空行
    
    # 连接信息部分
    message_parts+=("🌐 **连接信息**")
    message_parts+=("   - 客户端IP: \`$client_ip\`")
    
    if [ -n "$geo_info" ]; then
        message_parts+=("   - 地理位置: $geo_info")
    fi
    
    message_parts+=("   - 服务器IP: \`${PUBLIC_IP:-未知}\`")
    message_parts+=("   - 主机名: \`${HOSTNAME:-未知}\`")
    message_parts+=("")  # 空行
    
    # 在线用户部分
    if [ "$ENABLE_ONLINE_USERS" = "true" ]; then
        # 获取在线用户总数
        local total_online=0
        if command -v who &> /dev/null; then
            total_online=$(who 2>/dev/null | wc -l 2>/dev/null || echo "0")
        fi
        
        message_parts+=("👥 **当前在线用户 (共 $total_online 人)**")
        
        # 添加在线用户信息
        if [ -n "$online_users_info" ]; then
            # 使用while循环读取每一行
            while IFS= read -r line || [ -n "$line" ]; do
                if [ -n "$line" ]; then
                    message_parts+=("$line")
                fi
            done <<< "$online_users_info"
        else
            message_parts+=("   无在线用户")
        fi
        message_parts+=("")  # 空行
    fi
    
    # 登录历史部分
    if [ "$ENABLE_DETAILED_INFO" = "true" ]; then
        message_parts+=("📋 **登录历史（最近5次）**")
        
        if [ -n "$login_history" ] && [ "$login_history" != "   无历史记录" ]; then
            # 使用while循环读取每一行
            while IFS= read -r line || [ -n "$line" ]; do
                if [ -n "$line" ]; then
                    message_parts+=("$line")
                fi
            done <<< "$login_history"
        else
            message_parts+=("   无历史记录")
        fi
        message_parts+=("")  # 空行
    fi
    
    # 系统状态部分
    if [ "$ENABLE_SYSTEM_INFO" = "true" ]; then
        message_parts+=("📊 **系统状态**")
        
        if [ -n "$system_info" ]; then
            # 使用while循环读取每一行
            while IFS= read -r line || [ -n "$line" ]; do
                if [ -n "$line" ]; then
                    message_parts+=("$line")
                fi
            done <<< "$system_info"
        else
            message_parts+=("   系统信息获取失败")
        fi
        message_parts+=("")  # 空行
    fi
    
    # 针对root登录添加警告
    if [ "$login_type" = "success_root" ]; then
        message_parts+=("🚨 **安全警告**")
        message_parts+=("   - 检测到ROOT用户直接登录")
        message_parts+=("   - 建议禁用root直接SSH登录")
        message_parts+=("   - 建议使用普通用户+sudo")
        message_parts+=("   - 建议启用密钥认证")
        message_parts+=("")  # 空行
    fi
    
    # 针对失败登录添加建议
    if [ "$login_type" = "failure" ]; then
        message_parts+=("⚠️ **安全建议**")
        message_parts+=("   - 检查是否存在暴力破解尝试")
        message_parts+=("   - 考虑使用Fail2ban进行防护")
        message_parts+=("   - 查看详细日志: \`sudo journalctl -u sshd --since \"5 minutes ago\"\`")
        message_parts+=("")  # 空行
    fi
    
    # 分隔线和脚注
    message_parts+=("---")
    message_parts+=("*🔔 SSH通知系统 v2.6 • $(date '+%Y-%m-%d %H:%M:%S')*")
    
    # 将数组转换为字符串，用换行符连接
    local message=""
    for part in "${message_parts[@]}"; do
        message+="$part"$'\n'
    done
    
    log "INFO" "消息构造完成，总长度: ${#message}"
    echo "$message"
}

# 发送通知到Gotify
send_to_gotify() {
    local title="$1"
    local message="$2"
    local priority="${3:-5}"
    
    if [ -z "$GOTIFY_SERVER" ] || [ -z "$GOTIFY_TOKEN" ]; then
        log "ERROR" "Gotify配置不完整，无法发送通知"
        return 1
    fi
    
    local response=""
    local http_code=""
    
    # 重试逻辑
    for ((i=1; i<=RETRY_COUNT; i++)); do
        log "INFO" "尝试发送通知 (第 $i 次重试)"
        
        # 记录发送前的消息长度
        log "INFO" "发送消息长度: ${#message}"
        
        response=$(curl -s -X POST "$GOTIFY_SERVER/message?token=$GOTIFY_TOKEN" \
            -F "title=$title" \
            -F "message=$message" \
            -F "priority=$priority" \
            -F "extras={\"client::display\":{\"contentType\":\"text/markdown\"}}" \
            -w "%{http_code}" \
            --connect-timeout "$TIMEOUT_SECONDS" \
            --max-time "$TIMEOUT_SECONDS")
        
        http_code="${response: -3}"
        
        if [[ $http_code == "200" ]]; then
            log "INFO" "通知发送成功: $title"
            return 0
        else
            log "WARN" "通知发送失败 (HTTP: $http_code)"
            if [ $i -lt $RETRY_COUNT ]; then
                sleep 2
            fi
        fi
    done
    
    log "ERROR" "通知发送失败，已达到最大重试次数 ($RETRY_COUNT)"
    return 1
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    # 记录开始
    log "INFO" "=== SSH通知脚本启动 ==="
    log "INFO" "用户: ${PAM_USER:-未知}, 类型: ${PAM_TYPE:-未知}, 远程主机: ${PAM_RHOST:-未知}, 服务: ${PAM_SERVICE:-未知}"
    
    # 只处理SSH登录，忽略其他服务
    if [[ ! "${PAM_SERVICE}" =~ ^(sshd|ssh)$ ]]; then
        log "DEBUG" "非SSH服务[${PAM_SERVICE}]，退出处理"
        exit 0
    fi
    
    # 只处理open_session和authfail事件
    if [[ "${PAM_TYPE}" != "open_session" ]] && [[ "${PAM_TYPE}" != "authfail" ]]; then
        log "DEBUG" "忽略非登录事件: ${PAM_TYPE}"
        exit 0
    fi
    
    # 获取用户名和IP
    local username="${PAM_USER:-$(whoami)}"
    local client_ip="${PAM_RHOST:-unknown}"
    
    # 确定登录类型
    local login_type=""
    if [ "${PAM_TYPE}" = "open_session" ]; then
        # 检查是否启用成功登录通知
        if [ "$ENABLE_LOGIN_SUCCESS" != "true" ]; then
            log "DEBUG" "成功登录通知已禁用，退出"
            exit 0
        fi
        
        if [ "$username" = "root" ]; then
            login_type="success_root"
        else
            login_type="success"
        fi
    elif [ "${PAM_TYPE}" = "authfail" ]; then
        # 检查是否启用失败登录通知
        if [ "$ENABLE_LOGIN_FAILURE" != "true" ]; then
            log "DEBUG" "失败登录通知已禁用，退出"
            exit 0
        fi
        login_type="failure"
    else
        log "DEBUG" "未知的PAM类型: ${PAM_TYPE}"
        exit 0
    fi
    
    # 去重检查
    if ! check_duplicate_notification "$username" "$client_ip" "$login_type"; then
        exit 0
    fi
    
    log "INFO" "处理登录通知: 用户=$username, IP=$client_ip, 类型=$login_type"
    
    # 构造并发送消息
    local message=$(construct_message "$login_type" "$username" "$client_ip")
    
    case "$login_type" in
        "success")
            local title="✅ SSH登录成功 - $HOSTNAME"
            send_to_gotify "$title" "$message" "$NORMAL_PRIORITY"
            ;;
        "success_root")
            local title="👑 ROOT用户登录 - $HOSTNAME"
            send_to_gotify "$title" "$message" "$ROOT_PRIORITY"
            ;;
        "failure")
            local title="❌ SSH登录失败 - $HOSTNAME"
            send_to_gotify "$title" "$message" "$FAILURE_PRIORITY"
            ;;
    esac
    
    log "INFO" "脚本执行完成"
}

# ============================================================================
# 执行入口
# ============================================================================
main "$@"
EOF
    
    # 设置正确的权限
    chmod 755 "$NOTIFY_SCRIPT"
    chown root:root "$NOTIFY_SCRIPT"
    
    echo -e "${COLOR_GREEN}✓ 通知脚本创建完成${COLOR_RESET}"
    echo -e "${COLOR_CYAN}脚本路径: $NOTIFY_SCRIPT${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}版本: v2.6 (修复系统状态、登录历史和在线用户列表显示问题)${COLOR_RESET}"
}

# 配置PAM
configure_pam() {
    echo -e "${COLOR_CYAN}正在配置PAM...${COLOR_RESET}"
    
    # 备份原始配置
    local pam_file="/etc/pam.d/sshd"
    if [ -f "$pam_file" ]; then
        local backup_file="${pam_file}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$pam_file" "$backup_file"
        echo -e "${COLOR_GREEN}✓ 已备份原始PAM配置到: $backup_file${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}✗ PAM配置文件不存在: $pam_file${COLOR_RESET}"
        return 1
    fi
    
    # 移除已存在的配置（避免重复）
    if grep -q "ssh-notify/notify.sh" "$pam_file"; then
        echo -e "${COLOR_YELLOW}⚠ 发现已存在的配置，正在清理...${COLOR_RESET}"
        sed -i '\|ssh-notify/notify.sh|d' "$pam_file"
        echo -e "${COLOR_GREEN}✓ 已清理旧配置${COLOR_RESET}"
    fi
    
    # 添加配置到PAM的适当位置
    echo -e "\n# SSH登录通知 (由ssh-notify配置工具添加)" >> "$pam_file"
    echo "session    required     pam_exec.so /etc/ssh-notify/notify.sh" >> "$pam_file"
    
    echo -e "${COLOR_GREEN}✓ PAM配置完成${COLOR_RESET}"
    
    # 验证PAM配置
    echo -e "${COLOR_CYAN}验证PAM配置...${COLOR_RESET}"
    if grep -q "ssh-notify/notify.sh" "$pam_file"; then
        echo -e "${COLOR_GREEN}✓ PAM配置验证成功${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}✗ PAM配置验证失败${COLOR_RESET}"
        return 1
    fi
    
    # 重启SSH服务
    echo -e "${COLOR_CYAN}重启SSH服务...${COLOR_RESET}"
    if systemctl restart sshd 2>/dev/null; then
        echo -e "${COLOR_GREEN}✓ SSH服务重启成功 (systemctl)${COLOR_RESET}"
    elif service ssh restart 2>/dev/null; then
        echo -e "${COLOR_GREEN}✓ SSH服务重启成功 (service)${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}⚠ 无法自动重启SSH服务，请手动执行:${COLOR_RESET}"
        echo -e "  systemctl restart sshd 或 service ssh restart"
    fi
    
    return 0
}

# 启用SSH登录通知
enable_ssh_notify() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}启用SSH登录通知${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    # 检查Gotify配置
    if [ -z "$GOTIFY_SERVER" ] || [ -z "$GOTIFY_TOKEN" ]; then
        echo -e "${COLOR_RED}✗ 请先配置Gotify服务器${COLOR_RESET}"
        echo -e ""
        read -n 1 -s -r -p "按任意键返回主菜单..."
        return 1
    fi
    
    echo -e "${COLOR_BLUE}步骤1: 创建通知脚本${COLOR_RESET}"
    create_notify_script
    
    echo -e ""
    echo -e "${COLOR_BLUE}步骤2: 配置PAM${COLOR_RESET}"
    if ! configure_pam; then
        echo -e "${COLOR_RED}✗ PAM配置失败${COLOR_RESET}"
        return 1
    fi
    
    echo -e ""
    echo -e "${COLOR_BLUE}步骤3: 配置通知选项${COLOR_RESET}"
    echo -e ""
    
    # 配置通知选项
    read -p "是否启用登录成功通知? (y/n, 默认y): " enable_success
    if [[ $enable_success == "n" || $enable_success == "N" ]]; then
        sed -i 's/ENABLE_LOGIN_SUCCESS=.*/ENABLE_LOGIN_SUCCESS=false/' "$CONFIG_FILE"
        echo -e "  ${COLOR_YELLOW}⚠ 成功登录通知已禁用${COLOR_RESET}"
    else
        sed -i 's/ENABLE_LOGIN_SUCCESS=.*/ENABLE_LOGIN_SUCCESS=true/' "$CONFIG_FILE"
        echo -e "  ${COLOR_GREEN}✓ 成功登录通知已启用${COLOR_RESET}"
    fi
    read -p "是否启用登录失败通知? (y/n, 默认n): " enable_failure
    if [[ $enable_failure == "y" || $enable_failure == "Y" ]]; then
        sed -i 's/ENABLE_LOGIN_FAILURE=.*/ENABLE_LOGIN_FAILURE=true/' "$CONFIG_FILE"
        echo -e "  ${COLOR_YELLOW}⚠ 失败登录通知已启用（注意：可能产生大量通知）${COLOR_RESET}"
    else
        sed -i 's/ENABLE_LOGIN_FAILURE=.*/ENABLE_LOGIN_FAILURE=false/' "$CONFIG_FILE"
        echo -e "  ${COLOR_GREEN}✓ 失败登录通知已禁用${COLOR_RESET}"
    fi
    read -p "是否启用地理位置信息? (y/n, 默认y): " enable_geo
    if [[ $enable_geo == "n" || $enable_geo == "N" ]]; then
        sed -i 's/ENABLE_GEO_IP=.*/ENABLE_GEO_IP=false/' "$CONFIG_FILE"
        echo -e "  ${COLOR_YELLOW}⚠ 地理位置信息已禁用${COLOR_RESET}"
    else
        sed -i 's/ENABLE_GEO_IP=.*/ENABLE_GEO_IP=true/' "$CONFIG_FILE"
        echo -e "  ${COLOR_GREEN}✓ 地理位置信息已启用${COLOR_RESET}"
    fi
    
    read -p "是否启用系统状态信息? (y/n, 默认y): " enable_sysinfo
    if [[ $enable_sysinfo == "n" || $enable_sysinfo == "N" ]]; then
        sed -i 's/ENABLE_SYSTEM_INFO=.*/ENABLE_SYSTEM_INFO=false/' "$CONFIG_FILE"
        echo -e "  ${COLOR_YELLOW}⚠ 系统状态信息已禁用${COLOR_RESET}"
    else
        sed -i 's/ENABLE_SYSTEM_INFO=.*/ENABLE_SYSTEM_INFO=true/' "$CONFIG_FILE"
        echo -e "  ${COLOR_GREEN}✓ 系统状态信息已启用${COLOR_RESET}"
    fi
    
    read -p "是否启用详细登录历史? (y/n, 默认y): " enable_history
    if [[ $enable_history == "n" || $enable_history == "N" ]]; then
        sed -i 's/ENABLE_DETAILED_INFO=.*/ENABLE_DETAILED_INFO=false/' "$CONFIG_FILE"
        echo -e "  ${COLOR_YELLOW}⚠ 详细登录历史已禁用${COLOR_RESET}"
    else
        sed -i 's/ENABLE_DETAILED_INFO=.*/ENABLE_DETAILED_INFO=true/' "$CONFIG_FILE"
        echo -e "  ${COLOR_GREEN}✓ 详细登录历史已启用${COLOR_RESET}"
    fi
    
    # 新增：是否启用在线用户信息
    read -p "是否启用在线用户及IP推送? (y/n, 默认y): " enable_online
    if [[ $enable_online == "n" || $enable_online == "N" ]]; then
        sed -i 's/ENABLE_ONLINE_USERS=.*/ENABLE_ONLINE_USERS=false/' "$CONFIG_FILE"
        echo -e "  ${COLOR_YELLOW}⚠ 在线用户信息已禁用${COLOR_RESET}"
    else
        sed -i 's/ENABLE_ONLINE_USERS=.*/ENABLE_ONLINE_USERS=true/' "$CONFIG_FILE"
        echo -e "  ${COLOR_GREEN}✓ 在线用户信息已启用${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}（新功能：推送当前在线用户及IP）${COLOR_RESET}"
    fi
    
    # 重新加载配置
    load_config
    
    echo -e ""
    echo -e "${COLOR_GREEN}✅ SSH登录通知已启用！${COLOR_RESET}"
    echo -e ""
    echo -e "${COLOR_YELLOW}📋 配置摘要：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"

    # 确保变量存在且有值
    ENABLE_LOGIN_SUCCESS="${ENABLE_LOGIN_SUCCESS:-true}"
    ENABLE_LOGIN_FAILURE="${ENABLE_LOGIN_FAILURE:-false}"
    ENABLE_GEO_IP="${ENABLE_GEO_IP:-true}"
    ENABLE_SYSTEM_INFO="${ENABLE_SYSTEM_INFO:-true}"
    ENABLE_DETAILED_INFO="${ENABLE_DETAILED_INFO:-true}"
    ENABLE_ONLINE_USERS="${ENABLE_ONLINE_USERS:-true}"

    echo -e "  ✓ 成功登录通知: ${COLOR_GREEN}$ENABLE_LOGIN_SUCCESS${COLOR_RESET}"
    echo -e "  ✓ 失败登录通知: ${COLOR_GREEN}$ENABLE_LOGIN_FAILURE${COLOR_RESET}"
    echo -e "  ✓ 地理位置信息: ${COLOR_GREEN}$ENABLE_GEO_IP${COLOR_RESET}"
    echo -e "  ✓ 系统状态信息: ${COLOR_GREEN}$ENABLE_SYSTEM_INFO${COLOR_RESET}"
    echo -e "  ✓ 详细登录历史: ${COLOR_GREEN}$ENABLE_DETAILED_INFO${COLOR_RESET}"
    echo -e "  ✓ 在线用户信息: ${COLOR_GREEN}$ENABLE_ONLINE_USERS${COLOR_RESET}"

    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    echo -e ""
    echo -e "${COLOR_YELLOW}🔧 测试方法：${COLOR_RESET}"
    echo -e "  1. 从另一台机器SSH登录到此服务器"
    echo -e "  2. 查看Gotify是否收到通知"
    echo -e "  3. 检查通知中是否包含在线用户信息"
    echo -e "  4. 检查日志文件: ${COLOR_CYAN}$LOG_FILE${COLOR_RESET}"
    echo -e "  5. 使用本工具的手动测试功能"
    echo -e ""
    
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 禁用SSH登录通知
disable_ssh_notify() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}禁用SSH登录通知${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    echo -e "${COLOR_RED}⚠ 警告：这将从PAM配置中移除通知设置${COLOR_RESET}"
    echo -e ""
    
    read -p "确定要禁用SSH登录通知吗? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${COLOR_YELLOW}操作已取消${COLOR_RESET}"
        return
    fi
    
    # 从PAM配置中移除
    local pam_file="/etc/pam.d/sshd"
    if [ -f "$pam_file" ]; then
        if grep -q "ssh-notify/notify.sh" "$pam_file"; then
            sed -i '\|ssh-notify/notify.sh|d' "$pam_file"
            echo -e "${COLOR_GREEN}✓ 已从PAM配置中移除${COLOR_RESET}"
            
            # 重启SSH服务
            echo -e "${COLOR_CYAN}重启SSH服务...${COLOR_RESET}"
            if systemctl restart sshd 2>/dev/null; then
                echo -e "${COLOR_GREEN}✓ SSH服务已重启${COLOR_RESET}"
            elif service ssh restart 2>/dev/null; then
                echo -e "${COLOR_GREEN}✓ SSH服务已重启${COLOR_RESET}"
            else
                echo -e "${COLOR_YELLOW}⚠ 无法自动重启SSH服务，请手动重启${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_YELLOW}⚠ PAM配置中未找到通知设置${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_RED}✗ PAM配置文件不存在${COLOR_RESET}"
    fi
    
    echo -e ""
    echo -e "${COLOR_GREEN}✅ SSH登录通知已禁用${COLOR_RESET}"
    echo -e ""
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 查看当前配置
view_config() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}当前配置${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${COLOR_RED}✗ 配置文件不存在${COLOR_RESET}"
        return
    fi
    
    # 重新加载配置以确保获取最新值
    source "$CONFIG_FILE" 2>/dev/null
    
    echo -e "${COLOR_BLUE}📋 配置概览：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 显示关键配置
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${COLOR_BOLD}Gotify服务器${COLOR_RESET}: ${COLOR_CYAN}${GOTIFY_SERVER:-未配置}${COLOR_RESET}"
    if [ -n "$GOTIFY_TOKEN" ]; then
        masked_token="${GOTIFY_TOKEN:0:8}****${GOTIFY_TOKEN: -8}"
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${COLOR_BOLD}Token${COLOR_RESET}: ${COLOR_CYAN}$masked_token${COLOR_RESET}"
    else
        echo -e "  ${COLOR_RED}✗${COLOR_RESET} ${COLOR_BOLD}Token${COLOR_RESET}: ${COLOR_RED}未配置${COLOR_RESET}"
    fi
    
    # 显示通知开关
    echo -e ""
    echo -e "  ${COLOR_BOLD}通知设置${COLOR_RESET}:"
    
    # 使用变量直接显示
    local status_success=""
    if [ "$ENABLE_LOGIN_SUCCESS" = "true" ]; then
        status_success="${COLOR_GREEN}启用${COLOR_RESET}"
    else
        status_success="${COLOR_RED}禁用${COLOR_RESET}"
    fi
    echo -e "    - 成功登录通知: $status_success"
    
    local status_failure=""
    if [ "$ENABLE_LOGIN_FAILURE" = "true" ]; then
        status_failure="${COLOR_GREEN}启用${COLOR_RESET}"
    else
        status_failure="${COLOR_RED}禁用${COLOR_RESET}"
    fi
    echo -e "    - 失败登录通知: $status_failure"
    
    local status_geo=""
    if [ "$ENABLE_GEO_IP" = "true" ]; then
        status_geo="${COLOR_GREEN}启用${COLOR_RESET}"
    else
        status_geo="${COLOR_RED}禁用${COLOR_RESET}"
    fi
    echo -e "    - 地理位置信息: $status_geo"
    
    local status_sysinfo=""
    if [ "$ENABLE_SYSTEM_INFO" = "true" ]; then
        status_sysinfo="${COLOR_GREEN}启用${COLOR_RESET}"
    else
        status_sysinfo="${COLOR_RED}禁用${COLOR_RESET}"
    fi
    echo -e "    - 系统状态信息: $status_sysinfo"
    
    local status_history=""
    if [ "$ENABLE_DETAILED_INFO" = "true" ]; then
        status_history="${COLOR_GREEN}启用${COLOR_RESET}"
    else
        status_history="${COLOR_RED}禁用${COLOR_RESET}"
    fi
    echo -e "    - 详细登录历史: $status_history"
    
    local status_online=""
    if [ "$ENABLE_ONLINE_USERS" = "true" ]; then
        status_online="${COLOR_GREEN}启用${COLOR_RESET}"
    else
        status_online="${COLOR_RED}禁用${COLOR_RESET}"
    fi
    echo -e "    - 在线用户信息: $status_online"
    
    echo -e ""
    echo -e "  ${COLOR_BOLD}系统信息${COLOR_RESET}:"
    echo -e "    - 主机名: ${COLOR_CYAN}${HOSTNAME:-未知}${COLOR_RESET}"
    echo -e "    - 公网IP: ${COLOR_CYAN}${PUBLIC_IP:-未知}${COLOR_RESET}"
    echo -e "    - 最后配置: ${COLOR_CYAN}${LAST_CONFIG:-未知}${COLOR_RESET}"
    
    echo -e ""
    echo -e "${COLOR_BLUE}🔧 脚本状态：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 检查PAM配置
    local pam_file="/etc/pam.d/sshd"
    if [ -f "$pam_file" ] && grep -q "ssh-notify/notify.sh" "$pam_file" 2>/dev/null; then
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} PAM配置: ${COLOR_GREEN}已安装${COLOR_RESET}"
    else
        echo -e "  ${COLOR_RED}✗${COLOR_RESET} PAM配置: ${COLOR_RED}未安装${COLOR_RESET}"
    fi
    
    # 检查通知脚本
    if [ -f "$NOTIFY_SCRIPT" ]; then
        if [ -x "$NOTIFY_SCRIPT" ]; then
            local script_size=$(du -h "$NOTIFY_SCRIPT" | cut -f1)
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} 通知脚本: ${COLOR_GREEN}存在且可执行${COLOR_RESET} ($script_size)"
        else
            echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} 通知脚本: ${COLOR_YELLOW}存在但不可执行${COLOR_RESET}"
        fi
    else
        echo -e "  ${COLOR_RED}✗${COLOR_RESET} 通知脚本: ${COLOR_RED}不存在${COLOR_RESET}"
    fi
    
    # 检查日志文件
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(du -h "$LOG_FILE" | cut -f1)
        local log_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} 日志文件: ${COLOR_CYAN}$LOG_FILE${COLOR_RESET} ($log_size, $log_lines 行)"
    else
        echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} 日志文件: ${COLOR_YELLOW}不存在${COLOR_RESET}"
    fi
    
    echo -e ""
    echo -e "${COLOR_BLUE}📊 SSH登录统计：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 显示SSH登录统计
    local today_success=0
    local today_fails=0
    local auth_log_files=("/var/log/auth.log" "/var/log/secure")
    local date_str=$(date +%Y-%m-%d)
    
    for auth_log in "${auth_log_files[@]}"; do
        if [ -f "$auth_log" ]; then
            if grep -q "$date_str" "$auth_log" 2>/dev/null; then
                local success_count=$(grep "$date_str" "$auth_log" 2>/dev/null | grep -E "Accepted password|Accepted publickey" | wc -l 2>/dev/null || echo "0")
                local fail_count=$(grep "$date_str" "$auth_log" 2>/dev/null | grep -E "Failed password|Failed publickey" | wc -l 2>/dev/null || echo "0")
                today_success=$((today_success + success_count))
                today_fails=$((today_fails + fail_count))
            fi
        fi
    done
    
    echo -e "  今日成功登录: ${COLOR_GREEN}$today_success${COLOR_RESET} 次"
    echo -e "  今日失败尝试: ${COLOR_RED}$today_fails${COLOR_RESET} 次"
    
    # 获取当前在线用户
    if command -v who &> /dev/null; then
        local online_users=$(who 2>/dev/null | wc -l 2>/dev/null || echo "0")
        echo -e "  当前在线用户: ${COLOR_CYAN}$online_users${COLOR_RESET} 人"
    else
        echo -e "  当前在线用户: ${COLOR_YELLOW}who命令不可用${COLOR_RESET}"
    fi
    
    echo -e ""
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 查看日志
view_log() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}日志文件查看器${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${COLOR_YELLOW}⚠ 日志文件不存在${COLOR_RESET}"
        echo -e ""
        read -n 1 -s -r -p "按任意键返回主菜单..."
        return
    fi
    
    local log_size=$(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo "未知")
    local log_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo -e "${COLOR_BLUE}日志信息：${COLOR_RESET}"
    echo -e "  文件: ${COLOR_CYAN}$LOG_FILE${COLOR_RESET}"
    echo -e "  大小: ${COLOR_CYAN}$log_size${COLOR_RESET}"
    echo -e "  行数: ${COLOR_CYAN}$log_lines${COLOR_RESET}"
    echo -e ""
    
    echo -e "${COLOR_CYAN}最近20条日志：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    echo -e ""
    
    # 显示彩色日志
    tail -20 "$LOG_FILE" 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q "ERROR"; then
            echo -e "${COLOR_RED}$line${COLOR_RESET}"
        elif echo "$line" | grep -q "WARN"; then
            echo -e "${COLOR_YELLOW}$line${COLOR_RESET}"
        elif echo "$line" | grep -q "INFO" && echo "$line" | grep -q "成功\|发送成功\|执行完成"; then
            echo -e "${COLOR_GREEN}$line${COLOR_RESET}"
        elif echo "$line" | grep -q "INFO"; then
            echo -e "${COLOR_CYAN}$line${COLOR_RESET}"
        elif echo "$line" | grep -q "DEBUG"; then
            echo -e "${COLOR_DIM}$line${COLOR_RESET}"
        else
            echo -e "$line"
        fi
    done
    
    echo -e ""
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    echo -e "${COLOR_YELLOW}操作：${COLOR_RESET}"
    echo -e "  1. 查看更多日志 (显示全部)"
    echo -e "  2. 清空日志文件"
    echo -e "  3. 实时监控日志"
    echo -e "  4. 搜索日志内容"
    echo -e "  0. 返回主菜单"
    echo -e ""
    read -p "请选择 [0-4]: " log_choice
    
    case $log_choice in
        1)
            echo -e ""
            echo -e "${COLOR_CYAN}完整日志：${COLOR_RESET}"
            echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
            cat "$LOG_FILE" 2>/dev/null || echo -e "${COLOR_RED}无法读取日志文件${COLOR_RESET}"
            ;;
        2)
            read -p "确定要清空日志文件吗? (y/n): " confirm
            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                > "$LOG_FILE"
                echo -e "${COLOR_GREEN}✓ 日志已清空${COLOR_RESET}"
            else
                echo -e "${COLOR_YELLOW}操作已取消${COLOR_RESET}"
            fi
            ;;
        3)
            echo -e "${COLOR_CYAN}开始实时监控日志 (Ctrl+C 退出)...${COLOR_RESET}"
            echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
            tail -f "$LOG_FILE" 2>/dev/null || echo -e "${COLOR_RED}无法监控日志文件${COLOR_RESET}"
            ;;
        4)
            read -p "请输入搜索关键词: " search_term
            if [ -n "$search_term" ]; then
                echo -e ""
                echo -e "${COLOR_CYAN}搜索结果：${COLOR_RESET}"
                echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
                grep -i "$search_term" "$LOG_FILE" 2>/dev/null | head -50 || echo -e "${COLOR_YELLOW}未找到匹配结果${COLOR_RESET}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${COLOR_RED}无效的选择${COLOR_RESET}"
            ;;
    esac
    
    echo -e ""
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 手动触发测试
manual_test() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}手动触发测试${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    echo -e "${COLOR_YELLOW}🔧 选择测试类型：${COLOR_RESET}"
    echo -e ""
    echo -e "  ${COLOR_GREEN}1${COLOR_RESET}. 测试成功登录通知（普通用户）"
    echo -e "  ${COLOR_GREEN}2${COLOR_RESET}. 测试成功登录通知（Root用户）"
    echo -e "  ${COLOR_GREEN}3${COLOR_RESET}. 测试失败登录通知"
    echo -e "  ${COLOR_GREEN}4${COLOR_RESET}. 测试自定义IP登录"
    echo -e "  ${COLOR_GREEN}5${COLOR_RESET}. 测试命令执行"
    echo -e "  ${COLOR_GREEN}0${COLOR_RESET}. 返回主菜单"
    echo -e ""
    read -p "请选择 [0-5]: " test_choice
    
    case $test_choice in
        1)
            echo -e ""
            echo -e "${COLOR_CYAN}模拟普通用户成功登录...${COLOR_RESET}"
            export PAM_SERVICE="sshd"
            export PAM_TYPE="open_session"
            export PAM_USER="${SUDO_USER:-$USER}"
            export PAM_RHOST="203.0.113.100"
            
            # 检查通知脚本
            if [ -f "$NOTIFY_SCRIPT" ]; then
                if [ -x "$NOTIFY_SCRIPT" ]; then
                    echo -e "${COLOR_CYAN}正在执行通知脚本...${COLOR_RESET}"
                    "$NOTIFY_SCRIPT"
                    echo -e "${COLOR_GREEN}✓ 测试成功登录通知已发送${COLOR_RESET}"
                    echo -e "${COLOR_CYAN}请检查Gotify消息和日志文件${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}✗ 通知脚本不可执行${COLOR_RESET}"
                fi
            else
                echo -e "${COLOR_RED}✗ 通知脚本不存在${COLOR_RESET}"
            fi
            ;;
        2)
            echo -e ""
            echo -e "${COLOR_CYAN}模拟Root用户成功登录...${COLOR_RESET}"
            export PAM_SERVICE="sshd"
            export PAM_TYPE="open_session"
            export PAM_USER="root"
            export PAM_RHOST="198.51.100.50"
            
            if [ -f "$NOTIFY_SCRIPT" ] && [ -x "$NOTIFY_SCRIPT" ]; then
                "$NOTIFY_SCRIPT"
                echo -e "${COLOR_GREEN}✓ 测试Root登录通知已发送${COLOR_RESET}"
                echo -e "${COLOR_YELLOW}注意：Root登录会触发高优先级警告${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}✗ 通知脚本不存在或不可执行${COLOR_RESET}"
            fi
            ;;
        3)
            echo -e ""
            echo -e "${COLOR_CYAN}模拟失败登录...${COLOR_RESET}"
            export PAM_SERVICE="sshd"
            export PAM_TYPE="authfail"
            export PAM_USER="hacker"
            export PAM_RHOST="192.0.2.100"
            
            if [ -f "$NOTIFY_SCRIPT" ] && [ -x "$NOTIFY_SCRIPT" ]; then
                # 需要先启用失败通知
                local temp_backup=""
                if [ -f "$CONFIG_FILE" ]; then
                    temp_backup=$(mktemp)
                    cp "$CONFIG_FILE" "$temp_backup"
                    sed -i 's/ENABLE_LOGIN_FAILURE=.*/ENABLE_LOGIN_FAILURE=true/' "$CONFIG_FILE"
                fi
                
                "$NOTIFY_SCRIPT"
                
                # 恢复配置
                if [ -n "$temp_backup" ] && [ -f "$temp_backup" ]; then
                    mv "$temp_backup" "$CONFIG_FILE"
                fi
                
                echo -e "${COLOR_GREEN}✓ 测试失败登录通知已发送${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}✗ 通知脚本不存在或不可执行${COLOR_RESET}"
            fi
            ;;
        4)
            echo -e ""
            read -p "请输入测试IP地址: " test_ip
            if [[ ! $test_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "${COLOR_RED}✗ 无效的IP地址格式${COLOR_RESET}"
                return
            fi
            
            echo -e "${COLOR_CYAN}模拟来自 $test_ip 的登录...${COLOR_RESET}"
            export PAM_SERVICE="sshd"
            export PAM_TYPE="open_session"
            export PAM_USER="${SUDO_USER:-$USER}"
            export PAM_RHOST="$test_ip"
            
            if [ -f "$NOTIFY_SCRIPT" ] && [ -x "$NOTIFY_SCRIPT" ]; then
                "$NOTIFY_SCRIPT"
                echo -e "${COLOR_GREEN}✓ 测试通知已发送${COLOR_RESET}"
                echo -e "${COLOR_CYAN}IP地址: $test_ip${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}✗ 通知脚本不存在或不可执行${COLOR_RESET}"
            fi
            ;;
        5)
            echo -e ""
            echo -e "${COLOR_CYAN}测试命令执行...${COLOR_RESET}"
            echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
            echo -e ""
            
            # 测试系统信息命令
            echo -e "${COLOR_BLUE}测试系统信息命令：${COLOR_RESET}"
            echo -e "  1. who命令: $(who 2>/dev/null | wc -l 2>/dev/null || echo "失败") 个用户"
            echo -e "  2. uptime命令: $(uptime 2>/dev/null | grep -o "load average:.*" 2>/dev/null || echo "失败")"
            echo -e "  3. free命令: $(free -m 2>/dev/null | awk 'NR==2 {if ($2>0) printf "%.1f%%", $3*100/$2; else print "失败"}' 2>/dev/null || echo "失败")"
            echo -e "  4. df命令: $(df -h / 2>/dev/null | awk 'NR==2 {print $5}' 2>/dev/null || echo "失败")"
            echo -e "  5. last命令: $(last -5 "$USER" 2>/dev/null | grep -c "^$USER" 2>/dev/null || echo "0") 条记录"
            echo -e ""
            
            # 测试在线用户显示
            echo -e "${COLOR_BLUE}测试在线用户显示：${COLOR_RESET}"
            if command -v who &> /dev/null; then
                local total_users=$(who 2>/dev/null | wc -l 2>/dev/null || echo "0")
                echo -e "  在线用户总数: $total_users"
                if [ "$total_users" -gt 0 ]; then
                    echo -e "  在线用户列表："
                    who 2>/dev/null | head -5 | while IFS= read -r line; do
                        local user=$(echo "$line" | awk '{print $1}')
                        local ip=$(echo "$line" | grep -oE '\([^)]+\)' | head -1 | tr -d '()' || echo "本地")
                        echo -e "    $user ($ip)"
                    done
                fi
            else
                echo -e "  who命令不可用"
            fi
            echo -e ""
            echo -e "${COLOR_GREEN}✓ 命令测试完成${COLOR_RESET}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${COLOR_RED}✗ 无效的选择${COLOR_RESET}"
            ;;
    esac
    
    echo -e ""
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 系统状态检查
system_check() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}系统状态检查${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    echo -e "${COLOR_BLUE}📊 系统信息：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 主机名
    local hostname=$(hostname 2>/dev/null || echo "未知")
    echo -e "  主机名: ${COLOR_CYAN}$hostname${COLOR_RESET}"
    
    # 系统版本
    local os_info=""
    if [ -f /etc/os-release ]; then
        os_info=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"' 2>/dev/null)
    elif command -v lsb_release &> /dev/null; then
        os_info=$(lsb_release -ds 2>/dev/null)
    fi
    echo -e "  系统版本: ${COLOR_CYAN}${os_info:-未知}${COLOR_RESET}"
    
    # 内核版本
    echo -e "  内核版本: ${COLOR_CYAN}$(uname -r)${COLOR_RESET}"
    
    # CPU信息
    local cpu_cores=$(nproc 2>/dev/null || echo "未知")
    echo -e "  CPU核心: ${COLOR_CYAN}$cpu_cores${COLOR_RESET}"
    
    # 内存信息
    local total_mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "未知")
    echo -e "  内存总量: ${COLOR_CYAN}$total_mem${COLOR_RESET}"
    
    # 运行时间
    local uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "未知")
    echo -e "  运行时间: ${COLOR_CYAN}$uptime_str${COLOR_RESET}"
    
    echo -e ""
    echo -e "${COLOR_BLUE}🔧 SSH服务状态：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 检查SSH服务状态
    local ssh_status="未知"
    if systemctl is-active sshd &>/dev/null; then
        ssh_status="${COLOR_GREEN}运行中${COLOR_RESET}"
    elif service ssh status &>/dev/null; then
        ssh_status="${COLOR_GREEN}运行中${COLOR_RESET}"
    else
        ssh_status="${COLOR_RED}未运行${COLOR_RESET}"
    fi
    
    echo -e "  SSH服务状态: $ssh_status"
    
    echo -e ""
    echo -e "${COLOR_BLUE}📈 资源使用：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # CPU使用率
    local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "未知")
    echo -e "  CPU使用率: ${COLOR_CYAN}${cpu_usage}%${COLOR_RESET}"
    
    # 内存使用率
    local mem_usage=$(free 2>/dev/null | awk '/Mem:/ {if ($2 > 0) printf "%.1f", $3/$2 * 100; else print "未知"}' || echo "未知")
    echo -e "  内存使用率: ${COLOR_CYAN}${mem_usage}%${COLOR_RESET}"
    
    # 磁盘使用率
    local disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' || echo "未知")
    echo -e "  根分区使用: ${COLOR_CYAN}${disk_usage}${COLOR_RESET}"
    
    # 系统负载
    local load_avg=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | xargs || echo "未知")
    echo -e "  系统负载: ${COLOR_CYAN}${load_avg}${COLOR_RESET}"
    
    echo -e ""
    echo -e "${COLOR_BLUE}👥 在线用户信息：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 获取在线用户信息
    if command -v who &> /dev/null; then
        local total_online=$(who 2>/dev/null | wc -l 2>/dev/null || echo "0")
        echo -e "  总在线用户: ${COLOR_CYAN}$total_online${COLOR_RESET}"
        
        if [ "$total_online" -gt 0 ]; then
            echo -e "  在线用户详情:"
            who 2>/dev/null | head -5 | while IFS= read -r line; do
                local user=$(echo "$line" | awk '{print $1}')
                local terminal=$(echo "$line" | awk '{print $2}')
                local login_time=$(echo "$line" | awk '{print $3 " " $4}')
                local ip_address=$(echo "$line" | grep -oE '\([^)]+\)' | head -1 | tr -d '()' || echo "本地")
                echo -e "    ${COLOR_CYAN}$user${COLOR_RESET} ($ip_address) - $terminal - $login_time"
            done
            
            if [ "$total_online" -gt 5 ]; then
                echo -e "    ... 还有 $((total_online - 5)) 个用户未显示"
            fi
        else
            echo -e "   无在线用户"
        fi
    else
        echo -e "  who命令不可用"
    fi
    
    echo -e ""
    echo -e "${COLOR_BLUE}🔔 SSH登录统计：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 今日登录统计
    local today_success=0
    local today_fails=0
    local auth_log_files=("/var/log/auth.log" "/var/log/secure")
    local date_str=$(date +%Y-%m-%d)
    
    for auth_log in "${auth_log_files[@]}"; do
        if [ -f "$auth_log" ]; then
            if grep -q "$date_str" "$auth_log" 2>/dev/null; then
                local success_count=$(grep "$date_str" "$auth_log" 2>/dev/null | grep -E "Accepted password|Accepted publickey" | wc -l 2>/dev/null || echo "0")
                local fail_count=$(grep "$date_str" "$auth_log" 2>/dev/null | grep -E "Failed password|Failed publickey" | wc -l 2>/dev/null || echo "0")
                today_success=$((today_success + success_count))
                today_fails=$((today_fails + fail_count))
            fi
        fi
    done
    
    echo -e "  今日成功登录: ${COLOR_GREEN}$today_success${COLOR_RESET} 次"
    echo -e "  今日失败尝试: ${COLOR_RED}$today_fails${COLOR_RESET} 次"
    
    echo -e ""
    echo -e "${COLOR_BLUE}📋 通知系统状态：${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────────${COLOR_RESET}"
    
    # 检查PAM配置
    local pam_file="/etc/pam.d/sshd"
    if [ -f "$pam_file" ] && grep -q "ssh-notify/notify.sh" "$pam_file" 2>/dev/null; then
        echo -e "  PAM配置: ${COLOR_GREEN}正常${COLOR_RESET}"
    else
        echo -e "  PAM配置: ${COLOR_RED}未配置${COLOR_RESET}"
    fi
    
    # 检查脚本
    if [ -f "$NOTIFY_SCRIPT" ]; then
        if [ -x "$NOTIFY_SCRIPT" ]; then
            echo -e "  通知脚本: ${COLOR_GREEN}存在且可执行${COLOR_RESET}"
        else
            echo -e "  通知脚本: ${COLOR_YELLOW}存在但不可执行${COLOR_RESET}"
        fi
    else
        echo -e "  通知脚本: ${COLOR_RED}不存在${COLOR_RESET}"
    fi
    
    # 检查Gotify连接
    if [ -n "$GOTIFY_SERVER" ] && [ -n "$GOTIFY_TOKEN" ]; then
        echo -e "  Gotify配置: ${COLOR_GREEN}已配置${COLOR_RESET}"
        if curl -s "$GOTIFY_SERVER/version" --connect-timeout 5 &>/dev/null; then
            echo -e "  Gotify连接: ${COLOR_GREEN}正常${COLOR_RESET}"
        else
            echo -e "  Gotify连接: ${COLOR_RED}失败${COLOR_RESET}"
        fi
    else
        echo -e "  Gotify配置: ${COLOR_YELLOW}未配置${COLOR_RESET}"
    fi
    
    echo -e ""
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 卸载配置
uninstall() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}卸载配置${COLOR_RESET}"
    echo -e "${COLOR_CYAN}══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e ""
    
    echo -e "${COLOR_RED}⚠ 警告：这将移除所有SSH通知配置${COLOR_RESET}"
    echo -e ""
    echo -e "将要执行的操作："
    echo -e "  1. 从PAM配置中移除通知设置"
    echo -e "  2. 删除配置文件（可选）"
    echo -e "  3. 删除通知脚本（可选）"
    echo -e "  4. 删除日志文件（可选）"
    echo -e "  5. 删除锁文件和目录（可选）"
    echo -e ""
    
    read -p "确定要卸载吗? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${COLOR_YELLOW}操作已取消${COLOR_RESET}"
        return
    fi
    
    # 1. 从PAM配置中移除
    local pam_file="/etc/pam.d/sshd"
    if [ -f "$pam_file" ]; then
        if grep -q "ssh-notify/notify.sh" "$pam_file"; then
            sed -i '\|ssh-notify/notify.sh|d' "$pam_file"
            echo -e "${COLOR_GREEN}✓ 已从PAM配置中移除${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ PAM配置中未找到通知设置${COLOR_RESET}"
        fi
    fi
    
    # 2. 询问是否删除配置文件
    read -p "是否删除配置文件? (y/n): " delete_config
    if [[ $delete_config == "y" || $delete_config == "Y" ]]; then
        if [ -f "$CONFIG_FILE" ]; then
            rm -f "$CONFIG_FILE"
            echo -e "${COLOR_GREEN}✓ 配置文件已删除${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ 配置文件不存在${COLOR_RESET}"
        fi
    fi
    
    # 3. 询问是否删除脚本
    read -p "是否删除通知脚本? (y/n): " delete_script
    if [[ $delete_script == "y" || $delete_script == "Y" ]]; then
        if [ -f "$NOTIFY_SCRIPT" ]; then
            rm -f "$NOTIFY_SCRIPT"
            echo -e "${COLOR_GREEN}✓ 通知脚本已删除${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ 通知脚本不存在${COLOR_RESET}"
        fi
    fi
    
    # 4. 询问是否删除日志
    read -p "是否删除日志文件? (y/n): " delete_log
    if [[ $delete_log == "y" || $delete_log == "Y" ]]; then
        if [ -f "$LOG_FILE" ]; then
            rm -f "$LOG_FILE"
            echo -e "${COLOR_GREEN}✓ 日志文件已删除${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ 日志文件不存在${COLOR_RESET}"
        fi
    fi
    
    # 5. 询问是否删除锁目录
    read -p "是否删除锁文件和目录? (y/n): " delete_lock
    if [[ $delete_lock == "y" || $delete_lock == "Y" ]]; then
        if [ -d "$LOCK_DIR" ]; then
            rm -rf "$LOCK_DIR"
            echo -e "${COLOR_GREEN}✓ 锁文件和目录已删除${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ 锁目录不存在${COLOR_RESET}"
        fi
    fi
    
    # 重启SSH服务
    echo -e ""
    echo -e "${COLOR_CYAN}重启SSH服务...${COLOR_RESET}"
    if systemctl restart sshd 2>/dev/null; then
        echo -e "${COLOR_GREEN}✓ SSH服务已重启${COLOR_RESET}"
    elif service ssh restart 2>/dev/null; then
        echo -e "${COLOR_GREEN}✓ SSH服务已重启${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}⚠ 无法自动重启SSH服务${COLOR_RESET}"
    fi
    
    echo -e ""
    echo -e "${COLOR_GREEN}✅ 卸载完成！${COLOR_RESET}"
    echo -e ""
    read -n 1 -s -r -p "按任意键退出..."
    exit 0
}

# 主函数
main() {
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        echo -e "${COLOR_RED}请使用root用户运行此脚本${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}尝试使用sudo重新运行...${COLOR_RESET}"
        exec sudo "$0" "$@"
        exit 1
    fi
    
    # 初始化
    create_directories
    if ! check_dependencies; then
        echo -e "${COLOR_RED}依赖检查失败，请安装必要依赖${COLOR_RESET}"
        exit 1
    fi
    
    if ! load_config; then
        echo -e "${COLOR_YELLOW}配置加载失败，使用默认配置${COLOR_RESET}"
    fi
    
    # 主循环
    while true; do
        print_banner
        print_menu
        
        read -p "请选择操作 [0-9]: " choice
        
        case $choice in
            1)
                configure_gotify
                ;;
            2)
                enable_ssh_notify
                ;;
            3)
                disable_ssh_notify
                ;;
            4)
                send_test_notification
                echo -e ""
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
            5)
                view_config
                ;;
            6)
                view_log
                ;;
            7)
                manual_test
                ;;
            8)
                system_check
                ;;
            9)
                uninstall
                ;;
            0)
                print_banner
                echo -e "${COLOR_GREEN}感谢使用SSH通知系统 v2.6！${COLOR_RESET}"
                echo -e ""
                exit 0
                ;;
            *)
                echo -e "${COLOR_RED}无效的选择，请重新输入${COLOR_RESET}"
                sleep 2
                ;;
        esac
    done
}

# 运行主函数
main "$@"