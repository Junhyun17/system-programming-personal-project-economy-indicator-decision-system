#!/bin/bash

choose_period() {
    echo "비교 기간을 선택하세요."
    echo "[1] 최근 1주"
    echo "[2] 최근 1개월"
    echo "[3] 최근 3개월"
    echo "[0] 뒤로 가기"
    echo "[9] 메인 메뉴로 가기"
    echo
    read -p "선택: " period_menu

    case $period_menu in
        1) PERIOD_RESULT=7 ;;
        2) PERIOD_RESULT=30 ;;
        3) PERIOD_RESULT=90 ;;
        0) PERIOD_RESULT=0 ;;
        9) PERIOD_RESULT=9 ;;
        *) PERIOD_RESULT=-1 ;;
    esac
}

compare_menu() {
    clear
    echo "====================================="
    echo " 기준 비교 및 판단"
    echo "====================================="
    echo "[1] 달러 환율"
    echo "[2] 비트코인 가격"
    echo "[3] 코스피 지수"
    echo "[4] S&P 500 지수"
    echo "[5] 금 가격"
    echo "[0] 뒤로 가기"
    echo "[9] 메인 메뉴로 가기"
    echo
    read -p "비교할 지표를 선택하세요: " item

    if [ "$item" = "0" ] || [ "$item" = "9" ]; then
        return
    fi

    if [[ ! "$item" =~ ^[1-5]$ ]]; then
        echo "잘못된 입력입니다."
        sleep 1
        return
    fi

    name=$(get_name_by_item "$item")
    unit=$(get_unit_by_item "$item")
    current=$(get_value_by_item "$item")

    if [ -z "$current" ] || [ "$current" = "null" ]; then
        echo "[오류] 데이터를 가져오지 못했습니다."
        read -p "Enter를 누르면 메뉴로 돌아갑니다."
        return
    fi

    current_fmt=$(format_number "$current")

    clear
    echo "====================================="
    echo " $name 기준 비교"
    echo "====================================="
    echo "현재 $name: ${current_fmt}${unit}"
    echo

    echo "거래 유형을 선택하세요."
    echo "[1] 구매 / 매수"
    echo "[2] 판매 / 매도"
    echo "[0] 뒤로 가기"
    echo "[9] 메인 메뉴로 가기"
    echo
    read -p "선택: " trade_type

    if [ "$trade_type" = "0" ] || [ "$trade_type" = "9" ]; then
        return
    fi

    if [[ ! "$trade_type" =~ ^[1-2]$ ]]; then
        echo "잘못된 거래 유형입니다."
        sleep 1
        return
    fi

    echo
    echo "비교 기준을 선택하세요."
    echo "[1] 기준값 직접 비교"
    echo "[2] 평균 대비 차이 비교"
    echo "[3] 퍼센트 기준 비교"
    echo "[0] 뒤로 가기"
    echo "[9] 메인 메뉴로 가기"
    echo
    read -p "선택: " compare_type

    case $compare_type in
        1)
            compare_by_target "$item" "$name" "$current" "$unit" "$trade_type"
            ;;
        2)
            compare_by_average_diff "$item" "$name" "$current" "$unit" "$trade_type"
            ;;
        3)
            compare_by_percent "$item" "$name" "$current" "$unit" "$trade_type"
            ;;
        0|9)
            return
            ;;
        *)
            echo "잘못된 비교 기준입니다."
            ;;
    esac

    echo
    read -p "Enter를 누르면 메뉴로 돌아갑니다."
}

compare_by_target() {
    item="$1"
    name="$2"
    current="$3"
    unit="$4"
    trade_type="$5"

    current_fmt=$(format_number "$current")

    echo
    read -p "기준값을 입력하세요: " target

    if ! is_number "$target"; then
        echo "기준값은 숫자로 입력해야 합니다."
        return
    fi

    target_fmt=$(format_number "$target")

    echo
    echo "====================================="
    echo " 판단 결과"
    echo "====================================="
    echo "현재값: ${current_fmt}${unit}"
    echo "기준값: ${target_fmt}${unit}"
    echo

    case $trade_type in
        1)
            if (( $(echo "$current <= $target" | bc -l) )); then
                echo "[알림] 현재값이 기준값 이하입니다."
                echo "판단: 구매 또는 매수를 고려할 수 있습니다."
            else
                echo "현재값이 아직 기준값 이하로 내려오지 않았습니다."
                echo "판단: 구매 또는 매수에는 신중할 필요가 있습니다."
            fi
            ;;
        2)
            if (( $(echo "$current >= $target" | bc -l) )); then
                echo "[알림] 현재값이 기준값 이상입니다."
                echo "판단: 판매 또는 매도를 고려할 수 있습니다."
            else
                echo "현재값이 아직 기준값 이상으로 올라오지 않았습니다."
                echo "판단: 판매 또는 매도에는 신중할 필요가 있습니다."
            fi
            ;;
    esac

    save_log "$name 기준값 비교" "현재값 ${current_fmt}${unit}, 기준값 ${target_fmt}${unit}"

    add_alert_rule "$item" "$name 기준값 비교" "$trade_type" "target" "$target" "0"
}

compare_by_average_diff() {
    item="$1"
    name="$2"
    current="$3"
    unit="$4"
    trade_type="$5"

    echo
    choose_period
    period="$PERIOD_RESULT"

    if [ "$period" = "0" ] || [ "$period" = "9" ]; then
        return
    fi

    if [ "$period" = "-1" ]; then
        echo "잘못된 기간 선택입니다."
        return
    fi

    echo
    echo "${period}일 평균을 계산하는 중입니다..."

    avg=$(get_average_by_item "$item" "$period")

    if [ -z "$avg" ] || [ "$avg" = "null" ]; then
        echo "[오류] 평균값을 계산하지 못했습니다."
        return
    fi

    echo
    read -p "평균 대비 차이 기준값을 입력하세요: " diff_value

    if ! is_number "$diff_value"; then
        echo "차이 기준값은 숫자로 입력해야 합니다."
        return
    fi

    current_fmt=$(format_number "$current")
    avg_fmt=$(format_number "$avg")
    diff_fmt=$(format_number "$diff_value")

    echo
    echo "====================================="
    echo " 판단 결과"
    echo "====================================="
    echo "현재값: ${current_fmt}${unit}"
    echo "${period}일 평균: ${avg_fmt}${unit}"
    echo "차이 기준: ${diff_fmt}${unit}"
    echo

    case $trade_type in
        1)
            target_line=$(echo "$avg - $diff_value" | bc -l)
            target_line_fmt=$(format_number "$target_line")

            if (( $(echo "$current <= $target_line" | bc -l) )); then
                echo "[알림] 현재값이 평균보다 충분히 낮습니다."
                echo "판단: 구매 또는 매수를 고려할 수 있습니다."
            else
                echo "현재값이 평균 대비 설정한 차이만큼 낮지 않습니다."
                echo "판단: 구매 또는 매수에는 신중할 필요가 있습니다."
            fi

            echo "구매 기준선: ${target_line_fmt}${unit}"
            ;;
        2)
            target_line=$(echo "$avg + $diff_value" | bc -l)
            target_line_fmt=$(format_number "$target_line")

            if (( $(echo "$current >= $target_line" | bc -l) )); then
                echo "[알림] 현재값이 평균보다 충분히 높습니다."
                echo "판단: 판매 또는 매도를 고려할 수 있습니다."
            else
                echo "현재값이 평균 대비 설정한 차이만큼 높지 않습니다."
                echo "판단: 판매 또는 매도에는 신중할 필요가 있습니다."
            fi

            echo "판매 기준선: ${target_line_fmt}${unit}"
            ;;
    esac

    save_log "$name 평균 대비 차이 비교" "현재값 ${current_fmt}${unit}, 평균 ${avg_fmt}${unit}, 차이 기준 ${diff_fmt}${unit}"

    add_alert_rule "$item" "$name 평균 대비 차이 비교" "$trade_type" "avgdiff" "$diff_value" "$period"
}

compare_by_percent() {
    item="$1"
    name="$2"
    current="$3"
    unit="$4"
    trade_type="$5"

    echo
    choose_period
    period="$PERIOD_RESULT"

    if [ "$period" = "0" ] || [ "$period" = "9" ]; then
        return
    fi

    if [ "$period" = "-1" ]; then
        echo "잘못된 기간 선택입니다."
        return
    fi

    echo
    echo "${period}일 평균을 계산하는 중입니다..."

    avg=$(get_average_by_item "$item" "$period")

    if [ -z "$avg" ] || [ "$avg" = "null" ]; then
        echo "[오류] 평균값을 계산하지 못했습니다."
        return
    fi

    echo
    read -p "평균 대비 퍼센트 기준값을 입력하세요: " percent_value

    if ! is_number "$percent_value"; then
        echo "퍼센트 기준값은 숫자로 입력해야 합니다."
        return
    fi

    percent_diff=$(echo "($current - $avg) / $avg * 100" | bc -l)

    current_fmt=$(format_number "$current")
    avg_fmt=$(format_number "$avg")
    percent_diff_fmt=$(format_percent "$percent_diff")

    echo
    echo "====================================="
    echo " 판단 결과"
    echo "====================================="
    echo "현재값: ${current_fmt}${unit}"
    echo "${period}일 평균: ${avg_fmt}${unit}"
    echo "평균 대비 변화율: ${percent_diff_fmt}%"
    echo "퍼센트 기준: ${percent_value}%"
    echo

    case $trade_type in
        1)
            target_percent=$(echo "-1 * $percent_value" | bc -l)

            if (( $(echo "$percent_diff <= $target_percent" | bc -l) )); then
                echo "[알림] 현재값이 평균 대비 설정한 퍼센트 이상 낮습니다."
                echo "판단: 구매 또는 매수를 고려할 수 있습니다."
            else
                echo "현재값이 평균 대비 설정한 퍼센트만큼 낮지 않습니다."
                echo "판단: 구매 또는 매수에는 신중할 필요가 있습니다."
            fi
            ;;
        2)
            if (( $(echo "$percent_diff >= $percent_value" | bc -l) )); then
                echo "[알림] 현재값이 평균 대비 설정한 퍼센트 이상 높습니다."
                echo "판단: 판매 또는 매도를 고려할 수 있습니다."
            else
                echo "현재값이 평균 대비 설정한 퍼센트만큼 높지 않습니다."
                echo "판단: 판매 또는 매도에는 신중할 필요가 있습니다."
            fi
            ;;
    esac

    save_log "$name 퍼센트 기준 비교" "현재값 ${current_fmt}${unit}, 평균 ${avg_fmt}${unit}, 변화율 ${percent_diff_fmt}%"

    add_alert_rule "$item" "$name 퍼센트 기준 비교" "$trade_type" "percent" "$percent_value" "$period"
}
