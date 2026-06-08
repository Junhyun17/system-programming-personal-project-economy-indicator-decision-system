#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/lib/util.sh"
source "$BASE_DIR/lib/api.sh"

init_config

check_target_condition() {
    current="$1"
    trade_type="$2"
    target="$3"

    case $trade_type in
        1)
            if (( $(echo "$current <= $target" | bc -l) )); then
                return 0
            fi
            ;;
        2)
            if (( $(echo "$current >= $target" | bc -l) )); then
                return 0
            fi
            ;;
    esac

    return 1
}

check_avgdiff_condition() {
    item="$1"
    current="$2"
    trade_type="$3"
    diff_value="$4"
    period="$5"

    avg=$(get_average_by_item "$item" "$period")

    if [ -z "$avg" ]; then
        return 1
    fi

    case $trade_type in
        1)
            target_line=$(echo "$avg - $diff_value" | bc -l)
            if (( $(echo "$current <= $target_line" | bc -l) )); then
                return 0
            fi
            ;;
        2)
            target_line=$(echo "$avg + $diff_value" | bc -l)
            if (( $(echo "$current >= $target_line" | bc -l) )); then
                return 0
            fi
            ;;
    esac

    return 1
}

check_percent_condition() {
    item="$1"
    current="$2"
    trade_type="$3"
    percent_value="$4"
    period="$5"

    avg=$(get_average_by_item "$item" "$period")

    if [ -z "$avg" ]; then
        return 1
    fi

    percent_diff=$(echo "($current - $avg) / $avg * 100" | bc -l)

    case $trade_type in
        1)
            target_percent=$(echo "-1 * $percent_value" | bc -l)
            if (( $(echo "$percent_diff <= $target_percent" | bc -l) )); then
                return 0
            fi
            ;;
        2)
            if (( $(echo "$percent_diff >= $percent_value" | bc -l) )); then
                return 0
            fi
            ;;
    esac

    return 1
}

mark_notified() {
    target_id="$1"
    tmp_file="${ALERT_FILE}.tmp"

    awk -F'|' -v id="$target_id" 'BEGIN{OFS="|"} {
        if ($1 == id) {
            $9 = 1
        }
        print
    }' "$ALERT_FILE" > "$tmp_file"

    mv "$tmp_file" "$ALERT_FILE"
}

while true
do
    CHECK_INTERVAL=$(get_config_value "CHECK_INTERVAL")

    if [ -z "$CHECK_INTERVAL" ]; then
        CHECK_INTERVAL=60
    fi

    if [ -s "$ALERT_FILE" ]; then
        while IFS='|' read -r id item name trade_type compare_type target period enabled notified
        do
            if [ "$enabled" != "on" ]; then
                continue
            fi

            if [ "$notified" = "1" ]; then
                continue
            fi

            current=$(get_value_by_item "$item")

            if [ -z "$current" ] || [ "$current" = "null" ]; then
                continue
            fi

            triggered="no"

            case $compare_type in
                target)
                    if check_target_condition "$current" "$trade_type" "$target"; then
                        triggered="yes"
                    fi
                    ;;
                avgdiff)
                    if check_avgdiff_condition "$item" "$current" "$trade_type" "$target" "$period"; then
                        triggered="yes"
                    fi
                    ;;
                percent)
                    if check_percent_condition "$item" "$current" "$trade_type" "$target" "$period"; then
                        triggered="yes"
                    fi
                    ;;
            esac

            if [ "$triggered" = "yes" ]; then
                unit=$(get_unit_by_item "$item")
                current_fmt=$(format_number "$current")
                target_fmt=$(format_number "$target")

                title="경제 지표 알림"
                message="${name} 기준 도달
현재값: ${current_fmt}${unit}
기준값: ${target_fmt}${unit}"

                send_alert_by_mode "$title" "$message" "$name"
                save_log "자동 알림 발생" "$name 현재값 ${current_fmt}${unit}, 기준값 ${target_fmt}${unit}"

                mark_notified "$id"
            fi

        done < "$ALERT_FILE"
    fi

    sleep "$CHECK_INTERVAL"
done
