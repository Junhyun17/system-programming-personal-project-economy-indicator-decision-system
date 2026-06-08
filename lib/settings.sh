#!/bin/bash

get_alert_mode_text() {
    mode=$(get_config_value "ALERT_MODE")

    case $mode in
        1) echo "PowerShell 화면 알림만" ;;
        2) echo "이메일 알림만" ;;
        3) echo "PowerShell + 이메일 알림" ;;
        *) echo "PowerShell + 이메일 알림" ;;
    esac
}

set_alert_mode_menu() {
    clear
    echo "====================================="
    echo " 알림 방식 설정"
    echo "====================================="
    echo "[1] PowerShell 화면 알림만"
    echo "[2] 이메일 알림만"
    echo "[3] PowerShell + 이메일 알림"
    echo "[0] 뒤로 가기"
    echo "[9] 메인 메뉴로 가기"
    echo
    read -p "알림 방식을 선택하세요: " mode

    case $mode in
        1)
            set_config_value "ALERT_MODE" "1"
            echo "알림 방식이 PowerShell 화면 알림만으로 설정되었습니다."
            ;;
        2)
            set_config_value "ALERT_MODE" "2"
            echo "알림 방식이 이메일 알림만으로 설정되었습니다."
            ;;
        3)
            set_config_value "ALERT_MODE" "3"
            echo "알림 방식이 PowerShell + 이메일 알림으로 설정되었습니다."
            ;;
        0)
            return
            ;;
        9)
            return 9
            ;;
        *)
            echo "잘못된 입력입니다."
            ;;
    esac

    sleep 1
}

settings_menu() {
    while true
    do
        clear
        sender_email=$(get_sender_email)
        receiver_email=$(get_config_value "RECEIVER_EMAIL")
        alert_mode_text=$(get_alert_mode_text)
        check_interval=$(get_config_value "CHECK_INTERVAL")

        echo "====================================="
        echo " 설정 관리"
        echo "====================================="

        if [ -n "$sender_email" ]; then
            echo "발신 이메일 주소: $sender_email (SMTP 설정에서 자동 인식)"
        else
            echo "발신 이메일 주소: 설정 필요"
        fi

        echo "수신 이메일 주소: ${receiver_email:-설정 안 됨}"
        echo "알림 방식: $alert_mode_text"
        echo "자동 감시 주기: ${check_interval}초"
        echo
        echo "[1] SMTP 메일 설정"
        echo "[2] 수신 이메일 주소 설정"
        echo "[3] 알림 방식 설정"
        echo "[4] 자동 감시 주기 설정"
        echo "[5] 등록된 자동 알림 기준 보기"
        echo "[6] 자동 알림 감시 다시 시작"
        echo "[7] 자동 알림 감시 중지"
        echo "[8] 알림 완료 상태 초기화"
        echo "[10] 등록된 자동 알림 전체 삭제"
        echo "[9] 메인 메뉴로 가기"
        echo "[0] 뒤로 가기"
        echo
        read -p "메뉴를 선택하세요: " menu

        case $menu in
            1)
                setup_smtp_config
                ;;
            2)
                read -p "수신 이메일 주소를 입력하세요: " new_receiver
                set_config_value "RECEIVER_EMAIL" "$new_receiver"
                echo "수신 이메일 주소가 저장되었습니다."
                sleep 1
                ;;
            3)
                set_alert_mode_menu
                if [ $? -eq 9 ]; then
                    return
                fi
                ;;
            4)
                read -p "자동 감시 주기를 초 단위로 입력하세요: " new_interval

                if is_number "$new_interval"; then
                    set_config_value "CHECK_INTERVAL" "$new_interval"
                    echo "자동 감시 주기가 ${new_interval}초로 저장되었습니다."
                else
                    echo "숫자로 입력해야 합니다."
                fi
                sleep 1
                ;;
            5)
                show_alert_rules
                if [ $? -eq 9 ]; then
                    return
                fi
                ;;
            6)
                start_alert_watch
                ;;
            7)
                stop_alert_watch
                ;;
            8)
                reset_alert_notifications
                ;;
            10)
                clear_alert_rules
                ;;
            9)
                return
                ;;
            0)
                break
                ;;
            *)
                echo "잘못된 입력입니다."
                sleep 1
                ;;
        esac
    done
}