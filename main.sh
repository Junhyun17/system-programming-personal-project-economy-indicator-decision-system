#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/lib/util.sh"
source "$BASE_DIR/lib/api.sh"
source "$BASE_DIR/lib/graph.sh"
source "$BASE_DIR/lib/lookup.sh"
source "$BASE_DIR/lib/alert.sh"
source "$BASE_DIR/lib/compare.sh"
source "$BASE_DIR/lib/settings.sh"

init_config

auto_start_alert_watch() {
    if [ -f "$WATCH_PID_FILE" ]; then
        old_pid=$(cat "$WATCH_PID_FILE")

        if ps -p "$old_pid" > /dev/null 2>&1; then
            return
        else
            rm -f "$WATCH_PID_FILE"
        fi
    fi

    nohup "$BASE_DIR/alert_watch.sh" > "$BASE_DIR/alert_watch.log" 2>&1 &
    echo $! > "$WATCH_PID_FILE"
}

auto_start_alert_watch

while true
do
    clear
    echo "====================================="
    echo " 경제 지표 기반 소비·투자 판단 시스템"
    echo "====================================="
    echo
    echo "[1] 경제 지표 조회"
    echo "[2] 기준 비교 및 판단"
    echo "[3] 조회 기록 보기"
    echo "[4] 설정 관리"
    echo "[0] 종료"
    echo
    read -p "메뉴를 선택하세요: " menu

    case $menu in
        1) lookup_menu ;;
        2) compare_menu ;;
        3) show_log ;;
        4) settings_menu ;;
        0)
            echo "프로그램을 종료합니다."
            exit 0
            ;;
        *)
            echo "잘못된 입력입니다."
            sleep 1
            ;;
    esac
done