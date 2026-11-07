cmd_status() {
    local host uptime_value load memory disk battery
    local network wifi bluetooth audio vpn flake shell

    host="$(uname -n)"
    uptime_value="$(uptime -p 2>/dev/null | sed 's/^up //')"
    if [ -z "$uptime_value" ]; then
        uptime_value="$(uptime | sed 's/.*up //; s/, *[0-9]* users.*//')"
    fi
    load="$(cut -d' ' -f1-3 /proc/loadavg)"
    memory="$(free -h | awk '/^Mem:/{ print $3 " / " $2 }')"
    disk="$(df -h / | awk 'NR==2 { print $3 " / " $2 " (" $5 ")" }')"

    if command -v upower >/dev/null 2>&1; then
        battery="$(upower -e | grep -E '/battery_' | head -n 1 | xargs -r upower -i 2>/dev/null |
            awk -F: '/percentage|state/ { gsub(/^ +| +$/, "", $2); printf "%s%s", sep, $2; sep=", " }')"
    fi
    [ -n "$battery" ] || battery="unknown"

    if command -v nmcli >/dev/null 2>&1; then
        network="$(nmcli -t -f GENERAL.STATE general 2>/dev/null | cut -d: -f2-)"
        wifi="$(nmcli radio wifi 2>/dev/null)"
    fi
    [ -n "$network" ] || network="unknown"
    [ -n "$wifi" ] || wifi="unknown"

    if command -v bluetoothctl >/dev/null 2>&1; then
        bluetooth="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ { print $2; exit }')"
    fi
    [ -n "$bluetooth" ] || bluetooth="unknown"

    if command -v wpctl >/dev/null 2>&1; then
        audio="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
    fi
    [ -n "$audio" ] || audio="unknown"

    vpn="$(vpn_status 2>/dev/null | head -n 1)"
    [ -n "$vpn" ] || vpn="none"

    flake="$(ojuny_flake_root 2>/dev/null || printf 'unknown')"
    if [ "$flake" != "unknown" ]; then
        flake="$flake ($(ojuny_git_branch "$flake") @ $(ojuny_git_revision "$flake"))"
    fi

    shell="unknown"
    if command -v dms >/dev/null 2>&1; then
        shell="$(dms version 2>/dev/null | head -n 1)"
    fi

    if ojuny_is_json; then
        jq -cn --arg host "$host" --arg uptime "$uptime_value" --arg load "$load" \
            --arg memory "$memory" --arg disk "$disk" --arg battery "$battery" \
            --arg network "$network" --arg wifi "$wifi" --arg bluetooth "$bluetooth" \
            --arg audio "$audio" --arg vpn "$vpn" --arg flake "$flake" --arg shell "$shell" \
            '{host:$host,uptime:$uptime,load:$load,memory:$memory,disk:$disk,battery:$battery,network:$network,wifi:$wifi,bluetooth:$bluetooth,audio:$audio,vpn:$vpn,flake:$flake,shell:$shell}'
        return 0
    fi

    printf 'host\t%s\nuptime\t%s\nload\t%s\nmemory\t%s\ndisk\t%s\nbattery\t%s\nnetwork\t%s\nwifi\t%s\nbluetooth\t%s\naudio\t%s\nvpn\t%s\nflake\t%s\nshell\t%s\n' \
        "$host" "$uptime_value" "$load" "$memory" "$disk" "$battery" \
        "$network" "$wifi" "$bluetooth" "$audio" "$vpn" "$flake" "$shell" | ojuny_kv_block
}
