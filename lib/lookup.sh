#!/bin/bash

show_item_detail() {
    item="$1"

    while true
    do
        clear
        name=$(get_name_by_item "$item")
        unit=$(get_unit_by_item "$item")
        value=$(get_value_by_item "$item")

        echo "====================================="
        echo " $name 조회"
        echo "====================================="

        print_item_value "$name" "$value" "$unit"

        echo
        echo "[1] 최근 데이터 그래프 생성"
        echo "[0] 뒤로 가기"
        echo "[9] 메인 메뉴로 가기"
        echo
        read -p "메뉴를 선택하세요: " sub_menu

        case $sub_menu in
            1)
                create_graph "$item"
                if [ $? -eq 9 ]; then
                    return 9
                fi
                ;;
            0)
                break
                ;;
            9)
                return 9
                ;;
            *)
                echo "잘못된 입력입니다."
                sleep 1
                ;;
        esac
    done
}

show_all_items() {
    clear
    echo "====================================="
    echo " 전체 경제 지표 조회"
    echo "====================================="
    echo

    usd=$(get_usd_krw)
    btc=$(get_btc)
    kospi=$(get_kospi)
    sp500=$(get_sp500)
    gold=$(get_gold)

    print_item_value "달러 환율 USD/KRW" "$usd" "원"
    print_item_value "비트코인 가격" "$btc" "원"
    print_item_value "코스피 지수" "$kospi" ""
    print_item_value "S&P 500 지수" "$sp500" ""
    print_item_value "금 선물 가격" "$gold" "달러"

    echo
    read -p "Enter를 누르면 조회 메뉴로 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer

    if [ "$answer" = "9" ]; then
        return 9
    fi
}

lookup_menu() {
    while true
    do
        clear
        echo "====================================="
        echo " 경제 지표 조회"
        echo "====================================="
        echo "[1] 달러 환율 조회"
        echo "[2] 비트코인 가격 조회"
        echo "[3] 코스피 지수 조회"
        echo "[4] S&P 500 조회"
        echo "[5] 금 가격 조회"
        echo "[6] 전체 지표 조회"
        echo "[0] 뒤로 가기"
        echo "[9] 메인 메뉴로 가기"
        echo
        read -p "조회할 지표를 선택하세요: " item

        case $item in
            1|2|3|4|5)
                show_item_detail "$item"
                if [ $? -eq 9 ]; then
                    return
                fi
                ;;
            6)
                show_all_items
                if [ $? -eq 9 ]; then
                    return
                fi
                ;;
            0)
                break
                ;;
            9)
                return
                ;;
            *)
                echo "잘못된 입력입니다."
                sleep 1
                ;;
        esac
    done
}
