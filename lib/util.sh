#!/bin/bash

CONFIG_FILE="$BASE_DIR/config.txt"
LOG_FILE="$BASE_DIR/log.txt"
ALERT_FILE="$BASE_DIR/alerts.txt"
WATCH_PID_FILE="$BASE_DIR/alert_watch.pid"

init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "RECEIVER_EMAIL=" > "$CONFIG_FILE"
        echo "ALERT_MODE=3" >> "$CONFIG_FILE"
        echo "CHECK_INTERVAL=60" >> "$CONFIG_FILE"
    fi

    if ! grep -q "^RECEIVER_EMAIL=" "$CONFIG_FILE"; then
        echo "RECEIVER_EMAIL=" >> "$CONFIG_FILE"
    fi

    if ! grep -q "^ALERT_MODE=" "$CONFIG_FILE"; then
        echo "ALERT_MODE=3" >> "$CONFIG_FILE"
    fi

    if ! grep -q "^CHECK_INTERVAL=" "$CONFIG_FILE"; then
        echo "CHECK_INTERVAL=60" >> "$CONFIG_FILE"
    fi

    if [ ! -f "$ALERT_FILE" ]; then
        touch "$ALERT_FILE"
    fi

    mkdir -p "$BASE_DIR/data"
    mkdir -p "$BASE_DIR/graph"
}

get_config_value() {
    key="$1"

    if [ ! -f "$CONFIG_FILE" ]; then
        init_config
    fi

    grep "^${key}=" "$CONFIG_FILE" | cut -d '=' -f2-
}

set_config_value() {
    key="$1"
    value="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        init_config
    fi

    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
}

get_sender_email() {
    if [ -f "$HOME/.msmtprc" ]; then
        sender=$(grep "^from " "$HOME/.msmtprc" | head -n 1 | awk '{print $2}')

        if [ -n "$sender" ]; then
            echo "$sender"
            return
        fi
    fi

    echo ""
}

setup_smtp_config() {
    clear
    echo "====================================="
    echo " SMTP 메일 설정"
    echo "====================================="
    echo
    echo "SMTP를 지원하는 메일 서비스를 사용할 수 있습니다."
    echo "예시:"
    echo "네이버: smtp.naver.com / 587"
    echo "Gmail: smtp.gmail.com / 587"
    echo
    echo "비밀번호는 일반 로그인 비밀번호가 아니라,"
    echo "메일 서비스에서 발급한 앱 비밀번호 사용을 권장합니다."
    echo

    read -p "SMTP 서버 주소를 입력하세요: " smtp_host
    read -p "SMTP 포트 번호를 입력하세요: " smtp_port
    read -p "발신 이메일 주소를 입력하세요: " smtp_from
    read -p "SMTP 사용자 ID를 입력하세요: " smtp_user
    read -s -p "SMTP 비밀번호 또는 앱 비밀번호를 입력하세요: " smtp_password
    echo
    echo

    if [ -z "$smtp_host" ] || [ -z "$smtp_port" ] || [ -z "$smtp_from" ] || [ -z "$smtp_user" ] || [ -z "$smtp_password" ]; then
        echo "모든 항목을 입력해야 합니다."
        sleep 2
        return
    fi

    cat > "$HOME/.msmtprc" << EOF
defaults
auth on
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account default
host $smtp_host
port $smtp_port
from $smtp_from
user $smtp_user
password $smtp_password
EOF

    chmod 600 "$HOME/.msmtprc"

    echo "SMTP 메일 설정이 저장되었습니다."
    echo "발신 이메일: $smtp_from"
    echo
    echo "이제 이메일 알림을 사용할 수 있습니다."
    sleep 2
}

is_number() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

format_number() {
    printf "%.2f" "$1" | awk '{
        split($0, a, ".")
        intpart = a[1]
        decpart = a[2]

        result = ""
        while (length(intpart) > 3) {
            result = "," substr(intpart, length(intpart)-2, 3) result
            intpart = substr(intpart, 1, length(intpart)-3)
        }

        result = intpart result
        print result "." decpart
    }'
}

format_percent() {
    printf "%.2f" "$1"
}

save_log() {
    name="$1"
    value="$2"
    now=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$now | $name | $value" >> "$LOG_FILE"
}

show_log() {
    clear
    echo "====================================="
    echo " 조회 기록"
    echo "====================================="
    echo

    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo "아직 조회 기록이 없습니다."
    fi

    echo
    read -p "Enter를 누르면 메인 메뉴로 돌아갑니다."
}

send_desktop_alert() {
    title="$1"
    message="$2"

    if command -v powershell.exe > /dev/null 2>&1; then
        powershell.exe -NoProfile -Command "
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
\$n = New-Object System.Windows.Forms.NotifyIcon;
\$n.Icon = [System.Drawing.SystemIcons]::Information;
\$n.Visible = \$true;
\$n.ShowBalloonTip(5000, '$title', '$message', [System.Windows.Forms.ToolTipIcon]::Info);
Start-Sleep -Seconds 6;
\$n.Dispose();
" > /dev/null 2>&1
    elif command -v notify-send > /dev/null 2>&1; then
        notify-send "$title" "$message" 2>/dev/null
    else
        echo "[화면 알림] 현재 환경에서는 화면 알림을 띄울 수 없습니다."
    fi
}

send_email_alert() {
    subject="$1"
    message="$2"

    sender_email=$(get_sender_email)
    receiver_email=$(get_config_value "RECEIVER_EMAIL")

    if [ -z "$sender_email" ]; then
        echo "[메일 알림] 발신 이메일 주소를 찾을 수 없습니다."
        echo "설정 관리에서 SMTP 메일 설정을 먼저 진행하세요."
        return
    fi

    if [ -z "$receiver_email" ]; then
        echo "[메일 알림] 수신 이메일 주소가 설정되어 있지 않습니다."
        return
    fi

    if ! command -v msmtp > /dev/null 2>&1; then
        echo "[메일 알림] msmtp가 설치되어 있지 않습니다."
        echo "설치 명령어: sudo apt install msmtp msmtp-mta -y"
        return
    fi

    {
        echo "From: $sender_email"
        echo "To: $receiver_email"
        echo "Subject: $subject"
        echo
        echo "$message"
    } | msmtp "$receiver_email"

    if [ $? -eq 0 ]; then
        echo "[메일 알림] 메일 전송 명령을 실행했습니다."
    else
        echo "[메일 알림] 메일 전송에 실패했습니다."
        echo "로그 확인: cat ~/.msmtp.log"
    fi
}

send_alert_by_mode() {
    title="$1"
    message="$2"
    name="$3"

    alert_mode=$(get_config_value "ALERT_MODE")

    if [ -z "$alert_mode" ]; then
        alert_mode=3
    fi

    case $alert_mode in
        1)
            send_desktop_alert "$title" "$message"
            ;;
        2)
            send_email_alert "$title - $name" "$message"
            ;;
        3)
            send_desktop_alert "$title" "$message"
            send_email_alert "$title - $name" "$message"
            ;;
        *)
            send_desktop_alert "$title" "$message"
            send_email_alert "$title - $name" "$message"
            ;;
    esac
}
