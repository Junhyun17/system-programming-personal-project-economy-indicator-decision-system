#!/bin/bash

create_graph() {
    item="$1"
    name=$(get_name_by_item "$item")
    unit=$(get_unit_by_item "$item")

    clear
    echo "====================================="
    echo " $name 그래프 생성"
    echo "====================================="
    echo
    echo "그래프 기간을 선택하세요."
    echo "[1] 최근 1주"
    echo "[2] 최근 1개월"
    echo "[3] 최근 3개월"
    echo "[0] 뒤로 가기"
    echo "[9] 메인 메뉴로 가기"
    echo
    read -p "선택: " period_menu

    case $period_menu in
        1) period=7 ;;
        2) period=30 ;;
        3) period=90 ;;
        0) return ;;
        9) return 9 ;;
        *)
            echo "잘못된 입력입니다."
            sleep 1
            return
            ;;
    esac

    safe_name=$(echo "$name" | tr ' /' '__')
    DATA_FILE="$BASE_DIR/data/${safe_name}_${period}.txt"
    GRAPH_FILE="$BASE_DIR/graph/${safe_name}_${period}.png"

    mkdir -p "$BASE_DIR/data"
    mkdir -p "$BASE_DIR/graph"

    echo
    echo "$name 최근 데이터 조회 중..."

    get_history_data "$item" "$period" > "$DATA_FILE"

    if [ ! -s "$DATA_FILE" ]; then
        echo "[오류] 그래프용 데이터를 가져오지 못했습니다."
        read -p "Enter를 누르면 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer
        if [ "$answer" = "9" ]; then
            return 9
        fi
        return
    fi

    if ! command -v gnuplot > /dev/null 2>&1; then
        echo "[오류] gnuplot이 설치되어 있지 않습니다."
        echo "설치 명령어: sudo apt install gnuplot -y"
        read -p "Enter를 누르면 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer
        if [ "$answer" = "9" ]; then
            return 9
        fi
        return
    fi

    gnuplot << EOF
set terminal png size 900,500
set output "$GRAPH_FILE"

set title "$name Recent Trend"
set xlabel "Date"
set ylabel "$unit"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m-%d"

plot "$DATA_FILE" using 1:2 with linespoints title "$name"
EOF

    if [ ! -f "$GRAPH_FILE" ]; then
        echo "[오류] 그래프 이미지 생성에 실패했습니다."
        read -p "Enter를 누르면 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer
        if [ "$answer" = "9" ]; then
            return 9
        fi
        return
    fi

    echo "그래프 생성 완료: $GRAPH_FILE"

    if command -v powershell.exe > /dev/null 2>&1 && command -v wslpath > /dev/null 2>&1; then
        echo
        read -p "그래프 파일을 여시겠습니까? (y/n, 9: 메인 메뉴): " open_answer

        if [ "$open_answer" = "y" ] || [ "$open_answer" = "Y" ]; then
            WIN_GRAPH_FILE=$(wslpath -w "$GRAPH_FILE")
            powershell.exe -NoProfile -Command "Start-Process '$WIN_GRAPH_FILE'" > /dev/null 2>&1
        elif [ "$open_answer" = "9" ]; then
            return 9
        fi
    else
        echo
        echo "현재 환경에서는 그래프 파일을 자동으로 열 수 없습니다."
        echo "아래 경로에서 직접 확인하세요."
        echo "$GRAPH_FILE"
    fi

    echo
    read -p "Enter를 누르면 돌아갑니다. 9를 입력하면 메인 메뉴로 갑니다: " answer

    if [ "$answer" = "9" ]; then
        return 9
    fi
}