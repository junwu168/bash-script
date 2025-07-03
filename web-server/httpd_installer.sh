#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
HTTPD_PACKAGE="httpd"
SERVICE_NAME="httpd"
TEST_URL="http://localhost"

# 彩色打印函数
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

menu() {
    clear
    echo -e "${BLUE}#####################${NC}"
    echo -e "${BLUE}Apache HTTP Server Management${NC}"
    echo -e "${BLUE}1. Install httpd${NC}"
    echo -e "${BLUE}2. Start httpd${NC}"
    echo -e "${BLUE}3. Check httpd status${NC}"
    echo -e "${BLUE}4. Test web server${NC}"
    echo -e "${BLUE}5. Exit${NC}"
    echo -e "${BLUE}####################${NC}"
    echo -n -e "${BLUE}Please enter your choice: ${NC}"
}

is_httpd_installed() {
    if rpm -q $HTTPD_PACKAGE &>/dev/null; then
        info "httpd is already installed."
        return 0
    else
        info "httpd is not installed."
        return 1
    fi
}

check_yum_availability() {
    info "Checking httpd availability in yum repositories..."
    if yum info $HTTPD_PACKAGE &>/dev/null; then
        success "httpd is available in yum repositories."
        yum info $HTTPD_PACKAGE
        return 0
    else
        error "httpd is NOT available in yum repositories."
        return 1
    fi
}

install_httpd() {
    info "Installing httpd..."
    if sudo yum install -y $HTTPD_PACKAGE; then
        success "httpd installed successfully."
        return 0
    else
        error "Failed to install httpd."
        return 1
    fi
}

start_httpd() {
    info "Starting httpd service..."
    if sudo systemctl start $SERVICE_NAME; then
        success "httpd started successfully."
        return 0
    else
        error "Failed to start httpd."
        return 1
    fi
}

check_httpd_status() {
    info "Checking httpd status..."
    sudo systemctl status $SERVICE_NAME
}

test_web_server() {
    info "Testing web server..."
    if curl -sI $TEST_URL &>/dev/null; then
        success "Web server is working properly!"
        echo -e "${GREEN}Server response:${NC}"
        curl -s $TEST_URL | head -n 10
    else
        error "Cannot connect to web server at $TEST_URL"
        warning "Possible reasons:"
        warning "1. httpd service is not running"
        warning "2. Firewall is blocking port 80"
        warning "3. httpd is not properly configured"
        return 1
    fi
}

# 主循环
while true; do
    menu
    read -r choice

    case $choice in
    1)
        if ! is_httpd_installed; then
            if check_yum_availability; then
                install_httpd || {
                    echo -e "${YELLOW}Press any key to return to menu...${NC}"
                    read -n 1 -s
                    continue
                }
            else
                echo -e "${YELLOW}Press any key to return to menu...${NC}"
                read -n 1 -s
                continue
            fi
        else
            info "httpd is already installed."
        fi
        ;;
    2)
        if is_httpd_installed; then
            start_httpd || {
                echo -e "${YELLOW}Press any key to return to menu...${NC}"
                read -n 1 -s
                continue
            }
        else
            error "httpd is not installed. Please install it first."
        fi
        ;;
    3)
        if is_httpd_installed; then
            check_httpd_status
        else
            error "httpd is not installed. Please install it first."
        fi
        ;;
    4)
        if is_httpd_installed; then
            test_web_server || {
                echo -e "${YELLOW}Press any key to return to menu...${NC}"
                read -n 1 -s
                continue
            }
        else
            error "httpd is not installed. Please install it first."
        fi
        ;;
    5)
        echo -e "${BLUE}Exiting...${NC}"
        exit 0
        ;;
    *)
        error "Invalid input. Please enter a number between 1-5."
        ;;
    esac

    echo -e "${YELLOW}Press any key to return to menu...${NC}"
    read -n 1 -s
done
