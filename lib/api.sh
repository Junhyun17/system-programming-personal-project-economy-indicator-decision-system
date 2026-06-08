#!/bin/bash

get_usd_krw() {
    curl -s --max-time 10 "https://api.frankfurter.dev/v1/latest?base=USD&symbols=KRW" \
    | jq '.rates.KRW'
}

get_btc() {
    for i in 1 2 3
    do
        result=$(curl -s --max-time 10 "https://api.upbit.com/v1/ticker?markets=KRW-BTC" \
        | jq '.[0].trade_price')

        if [ -n "$result" ] && [ "$result" != "null" ]; then
            echo "$result"
            return
        fi

        sleep 2
    done

    echo ""
}

get_kospi() {
    curl -s --max-time 10 -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/%5EKS11?range=5d&interval=1d" \
    | jq '.chart.result[0].meta.regularMarketPrice'
}

get_sp500() {
    curl -s --max-time 10 -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/%5EGSPC?range=5d&interval=1d" \
    | jq '.chart.result[0].meta.regularMarketPrice'
}

get_gold() {
    curl -s --max-time 10 -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/GC=F?range=5d&interval=1d" \
    | jq '.chart.result[0].meta.regularMarketPrice'
}

get_value_by_item() {
    item="$1"

    case $item in
        1) get_usd_krw ;;
        2) get_btc ;;
        3) get_kospi ;;
        4) get_sp500 ;;
        5) get_gold ;;
    esac
}

get_name_by_item() {
    item="$1"

    case $item in
        1) echo "달러 환율 USD/KRW" ;;
        2) echo "비트코인 가격" ;;
        3) echo "코스피 지수" ;;
        4) echo "S&P 500 지수" ;;
        5) echo "금 선물 가격" ;;
    esac
}

get_unit_by_item() {
    item="$1"

    case $item in
        1) echo "원" ;;
        2) echo "원" ;;
        3) echo "" ;;
        4) echo "" ;;
        5) echo "달러" ;;
    esac
}

get_yahoo_symbol_by_item() {
    item="$1"

    case $item in
        3) echo "%5EKS11" ;;
        4) echo "%5EGSPC" ;;
        5) echo "GC=F" ;;
    esac
}

get_yahoo_range_by_period() {
    period="$1"

    case $period in
        7) echo "5d" ;;
        30) echo "1mo" ;;
        90) echo "3mo" ;;
        *) echo "1mo" ;;
    esac
}

get_history_data() {
    item="$1"
    period="$2"

    case $item in
        1)
            end_date=$(date "+%Y-%m-%d")
            start_date=$(date -d "${period} days ago" "+%Y-%m-%d")

            curl -s --max-time 10 "https://api.frankfurter.dev/v1/${start_date}..${end_date}?base=USD&symbols=KRW" \
            | jq -r '.rates | to_entries[] | "\(.key) \(.value.KRW)"'
            ;;

        2)
            curl -s --max-time 10 "https://api.upbit.com/v1/candles/days?market=KRW-BTC&count=${period}" \
            | jq -r 'reverse[] | "\(.candle_date_time_kst[0:10]) \(.trade_price)"'
            ;;

        3|4|5)
            symbol=$(get_yahoo_symbol_by_item "$item")
            range=$(get_yahoo_range_by_period "$period")

            curl -s --max-time 10 -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?range=${range}&interval=1d" \
            | jq -r '.chart.result[0] | [ .timestamp, .indicators.quote[0].close ] | transpose[] | select(.[1] != null) | "\(.[0] | strftime("%Y-%m-%d")) \(.[1])"'
            ;;
    esac
}

get_average_by_item() {
    item="$1"
    period="$2"

    get_history_data "$item" "$period" \
    | awk '{sum += $2; count++} END { if (count > 0) printf "%.6f", sum / count; }'
}

print_item_value() {
    name="$1"
    value="$2"
    unit="$3"

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "[오류] 데이터를 가져오지 못했습니다."
        echo "인터넷 연결 또는 API 응답을 확인해주세요."
        return 1
    fi

    value_fmt=$(format_number "$value")
    echo "현재 $name: ${value_fmt}${unit}"
    save_log "$name 조회" "${value_fmt}${unit}"
    return 0
}