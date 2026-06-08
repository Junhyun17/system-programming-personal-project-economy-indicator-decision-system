#!/bin/bash

add_alert_rule() {
    item="$1"
    name="$2"
    trade_type="$3"
    compare_type="$4"
    target="$5"
    period="$6"

    echo
    read -p "이 기준으로 자동 알림을 등록하시겠습니까? (y/n): " answer

    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        echo "자동 알림을 등록하지 않았습니다."
        return
    fi

    id=$(date "+%Y%m%d%H%M%S")

    echo "${id}|${item}|${name}|${trade_type}|${compare_type}|${target}|${period}|on|0" >> "$ALERT_FILE"

    echo "자동 알림 기준이 등록되었습니다."
    echo "알림 ID: $id"
    echo
    echo "프로그램 실행 시 자동 감시가 기본으로 시작됩니다."
}

show_alert_rules() {
    clear
    echo "====================================="
    echo " 등록된 자동 알림 기준"
    echo "====================================="
    echo

    if [ ! -s "$ALERT_FILE" ]; then
        echo "등록된 자동 알림 기준이 없습니다."
        echo
        read -p "Enter를 누르면 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer

        if [ "$answer" = "9" ]; then
            return 9
        fi

        return
    fi

    while IFS='|' read -r id item name trade_type compare_type target period enabled notified
    do
        case $trade_type in
            1) trade_text="구매/매수" ;;
            2) trade_text="판매/매도" ;;
            *) trade_text="알 수 없음" ;;
        esac

        case $compare_type in
            target) compare_text="기준값 직접 비교" ;;
            avgdiff) compare_text="평균 대비 차이 비교" ;;
            percent) compare_text="퍼센트 기준 비교" ;;
            *) compare_text="알 수 없음" ;;
        esac

        if [ "$notified" = "1" ]; then
            notified_text="알림 완료"
        else
            notified_text="대기 중"
        fi

        echo "ID: $id"
        echo "지표: $name"
        echo "거래 유형: $trade_text"
        echo "비교 방식: $compare_text"
        echo "기준값: $target"
        echo "기간: ${period}일"
        echo "상태: $enabled / $notified_text"
        echo "-------------------------------------"
    done < "$ALERT_FILE"

    echo
    read -p "Enter를 누르면 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer

    if [ "$answer" = "9" ]; then
        return 9
    fi
}

start_alert_watch() {
    if [ -f "$WATCH_PID_FILE" ]; then
        old_pid=$(cat "$WATCH_PID_FILE")

        if ps -p "$old_pid" > /dev/null 2>&1; then
            echo "자동 알림 감시가 이미 실행 중입니다. PID: $old_pid"
            sleep 1
            return
        else
            rm -f "$WATCH_PID_FILE"
        fi
    fi

    nohup "$BASE_DIR/alert_watch.sh" > "$BASE_DIR/alert_watch.log" 2>&1 &
    pid=$!
    echo "$pid" > "$WATCH_PID_FILE"

    echo "자동 알림 감시를 다시 시작했습니다. PID: $pid"
    sleep 2
}

stop_alert_watch() {
    if [ ! -f "$WATCH_PID_FILE" ]; then
        echo "실행 중인 자동 알림 감시가 없습니다."
        sleep 1
        return
    fi

    pid=$(cat "$WATCH_PID_FILE")

    if ps -p "$pid" > /dev/null 2>&1; then
        kill "$pid"
        rm -f "$WATCH_PID_FILE"
        echo "자동 알림 감시를 중지했습니다."
    else
        rm -f "$WATCH_PID_FILE"
        echo "이미 종료된 감시 프로세스입니다."
    fi

    sleep 1
}

reset_alert_notifications() {
    if [ ! -s "$ALERT_FILE" ]; then
        echo "등록된 알림 기준이 없습니다."
        sleep 1
        return
    fi

    tmp_file="${ALERT_FILE}.tmp"

    awk -F'|' 'BEGIN{OFS="|"} {$9=0; print}' "$ALERT_FILE" > "$tmp_file"
    mv "$tmp_file" "$ALERT_FILE"

    echo "알림 완료 상태를 초기화했습니다."
    echo "다시 기준에 도달하면 알림이 전송됩니다."
    sleep 1
}

clear_alert_rules() {
    if [ ! -s "$ALERT_FILE" ]; then
        echo "등록된 자동 알림 기준이 없습니다."
        sleep 1
        return
    fi

    echo "====================================="
    echo " 등록된 자동 알림 전체 삭제"
    echo "====================================="
    echo
    echo "이 기능은 alerts.txt에 저장된 자동 알림 기준을 모두 삭제합니다."
    echo "삭제하면 기존에 등록한 기준은 다시 복구할 수 없습니다."
    echo
    read -p "정말 삭제하려면 y를 입력하세요: " answer

    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        > "$ALERT_FILE"
        echo "등록된 자동 알림 기준을 모두 삭제했습니다."
    else
        echo "삭제를 취소했습니다."
    fi

    sleep 1
}
