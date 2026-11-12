ojuny_status_audio() {
    local raw="$1"
    case "$raw" in
    "Volume: "*) ;;
    *)
        printf '\n\n'
        return 1
        ;;
    esac
    local volume muted=false
    volume="${raw#Volume: }"
    case "$volume" in
    *"[MUTED]"*)
        muted=true
        volume="${volume% \[MUTED\]}"
        ;;
    esac
    printf '%s %s\n' "$volume" "$muted"
}

cmd_status() {
    local host uptime_value load memory disk battery
    local network wifi bluetooth audio_volume audio_muted vpn flake
    local shell_state="unavailable" shell_version="" shell_reason="dms not on PATH"

    host="$(uname -n)"
    uptime_value="$(ojuny_probe uptime -p | sed 's/^up //')"
    if [ -z "$uptime_value" ]; then
        uptime_value="$(ojuny_probe uptime | sed 's/.*up //; s/, *[0-9]* users.*//')"
    fi
    load="$(cut -d' ' -f1-3 /proc/loadavg)"
    memory="$(free -h 2>/dev/null | awk '/^Mem:/{ print $3 " / " $2 }' || true)"
    disk="$(df -h / 2>/dev/null | awk 'NR==2 { print $3 " / " $2 " (" $5 ")" }' || true)"

    if command -v upower >/dev/null 2>&1; then
        battery="$(upower -e 2>/dev/null | grep -E '/battery_' | head -n 1 |
            xargs -r upower -i 2>/dev/null |
            awk -F: '/percentage|state/ { gsub(/^ +| +$/, "", $2); printf "%s%s", sep, $2; sep=", " }' || true)"
    fi
    [ -n "$battery" ] || battery="unknown"

    if command -v nmcli >/dev/null 2>&1; then
        network="$(ojuny_probe nmcli -t -f STATE general | head -n 1)"
        wifi="$(ojuny_probe nmcli radio wifi | head -n 1)"
    fi
    [ -n "$network" ] || network="unknown"
    [ -n "$wifi" ] || wifi="unknown"

    if command -v bluetoothctl >/dev/null 2>&1; then
        bluetooth="$(ojuny_probe bluetoothctl show | awk -F': ' '/Powered/ { print $2; exit }')"
    fi
    [ -n "$bluetooth" ] || bluetooth="unknown"

    if command -v wpctl >/dev/null 2>&1; then
        audio="$(ojuny_probe wpctl get-volume @DEFAULT_AUDIO_SINK@)"
        if [ -n "$audio" ]; then
            read -r audio_volume audio_muted <<<"$(ojuny_status_audio "$audio")"
        fi
    fi

    read -r vpn <<<"$(ojuny_probe vpn_status | head -n 1)"
    [ -n "$vpn" ] || vpn="none"

    flake="$(ojuny_probe ojuny_flake_root)"
    [ -n "$flake" ] || flake="unknown"
    if [ "$flake" != "unknown" ]; then
        flake="$flake ($(ojuny_git_branch "$flake") @ $(ojuny_git_revision "$flake"))"
    fi

    if command -v dms >/dev/null 2>&1; then
        shell_version="$(ojuny_probe dms version | head -n 1)"
        if [ -n "$shell_version" ]; then
            shell_state="running"
            shell_reason=""
        fi
    fi

    if ojuny_is_json; then
        local volume_json="null" muted_json="null"
        [ -z "$audio_volume" ] || volume_json="$audio_volume"
        [ -z "$audio_muted" ] || muted_json="$audio_muted"
        jq -cn --arg host "$host" --arg uptime "$uptime_value" --arg load "$load" \
            --arg memory "$memory" --arg disk "$disk" --arg battery "$battery" \
            --arg network "$network" --arg wifi "$wifi" --arg bluetooth "$bluetooth" \
            --argjson volume "$volume_json" --argjson muted "$muted_json" \
            --arg vpn "$vpn" --arg flake "$flake" \
            --arg shell_state "$shell_state" --arg shell_version "$shell_version" \
            --arg shell_reason "$shell_reason" \
            '{schema:2,command:"status",ok:true,data:{host:$host,uptime:$uptime,load:$load,memory:$memory,disk:$disk,battery:$battery,network:{state:$network,wifi:$wifi},bluetooth:$bluetooth,audio:{volume:$volume,muted:$muted},vpn:$vpn,flake:$flake,shell:({state:$shell_state,version:$shell_version} + (if $shell_reason == "" then {} else {reason:$shell_reason} end))},meta:{}}'
        return 0
    fi

    local audio_text="unknown" shell_text="unavailable (no Dux session)"
    if [ -n "$audio_volume" ]; then
        audio_text="$(awk -v volume="$audio_volume" -v muted="$audio_muted" 'BEGIN { printf "%.0f%% (%s)", volume * 100, (muted == "true" ? "muted" : "unmuted") }')"
    fi
    if [ "$shell_state" = "running" ]; then
        shell_text="$shell_version"
    fi

    printf 'host\t%s\nuptime\t%s\nload\t%s\nmemory\t%s\ndisk\t%s\nbattery\t%s\nnetwork\t%s\nwifi\t%s\nbluetooth\t%s\naudio\t%s\nvpn\t%s\nflake\t%s\nshell\t%s\n' \
        "$host" "$uptime_value" "$load" "$memory" "$disk" "$battery" \
        "$network" "$wifi" "$bluetooth" "$audio_text" "$vpn" "$flake" "$shell_text" | ojuny_kv_block
}
