ipc_runtime_dir() {
    printf '%s/ojuny\n' "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
}

ipc_socket_path() {
    printf '%s/ipc.sock\n' "$(ipc_runtime_dir)"
}

ipc_require_socat() {
    ojuny_require_command socat
}

ipc_path() {
    ipc_socket_path
}

ipc_status() {
    local socket state
    socket="$(ipc_socket_path)"
    state="stopped"
    [ -S "$socket" ] && state="listening"

    if ojuny_is_json; then
        jq -cn --arg socket "$socket" --arg state "$state" \
            '{socket:$socket,state:$state}'
        return 0
    fi

    printf 'socket\t%s\nstate\t%s\n' "$socket" "$state"
}

ipc_require_socket() {
    local socket
    socket="$(ipc_socket_path)"
    if [ ! -S "$socket" ]; then
        ojuny_err "IPC socket is not available: $socket"
        printf '  hint: systemctl --user start ojuny-ipc.service\n' >&2
        return "$OJUNY_EXIT_DEPENDENCY"
    fi
}

ipc_call() {
    local method="${1:-}"
    shift || true

    if [ -z "$method" ]; then
        ojuny_usage_error "usage: ojuny ipc call <method> [args...]"
        return "$OJUNY_EXIT_USAGE"
    fi

    ipc_require_socat
    ipc_require_socket || return

    local socket args_json request response
    socket="$(ipc_socket_path)"
    args_json="$(jq -cn --args '$ARGS.positional' "$@")"
    request="$(jq -cn --arg id "$(date +%s)-$$" --arg method "$method" --argjson args "$args_json" \
        '{schema:1,id:$id,method:$method,args:$args}')"

    if ! response="$(printf '%s\n' "$request" | socat -t 10 - "UNIX-CONNECT:$socket")"; then
        ojuny_err "IPC call failed"
        return "$OJUNY_EXIT_BACKEND"
    fi

    if [ -z "$response" ]; then
        ojuny_err "IPC call returned no response"
        return "$OJUNY_EXIT_BACKEND"
    fi

    if ojuny_is_json; then
        printf '%s\n' "$response"
        return 0
    fi

    if printf '%s' "$response" | jq -e '.ok == true' >/dev/null 2>&1; then
        printf '%s\n' "$response" | jq -r '.data | if type == "object" or type == "array" then tojson else . end'
        return 0
    fi

    local code message hint
    code="$(printf '%s' "$response" | jq -r '.error.code // 4')"
    message="$(printf '%s' "$response" | jq -r '.error.message // "IPC call failed"')"
    hint="$(printf '%s' "$response" | jq -r '.error.hint // empty')"
    ojuny_err "$message"
    [ -n "$hint" ] && printf '  hint: %s\n' "$hint" >&2
    return "$code"
}

ipc_watch() {
    local topic="${1:-}"
    if [ -z "$topic" ]; then
        ojuny_usage_error "usage: ojuny ipc watch <topic>"
        return "$OJUNY_EXIT_USAGE"
    fi

    ipc_require_socat
    ipc_require_socket || return

    local socket request
    socket="$(ipc_socket_path)"
    request="$(jq -cn --arg id "watch-$$" --arg topic "$topic" \
        '{schema:1,id:$id,method:"subscribe",params:{topic:$topic}}')"

    {
        printf '%s\n' "$request"
        while :; do sleep 3600; done
    } | socat - "UNIX-CONNECT:$socket" | while IFS= read -r line; do
        if ojuny_is_json; then
            printf '%s\n' "$line" | jq -c 'select(.event)'
        else
            printf '%s\n' "$line" | jq -r 'select(.event) | .topic + "\t" + (.data | tojson)'
        fi
    done
}

ipc_serve() {
    ipc_require_socat

    local socket dir self
    socket="$(ipc_socket_path)"
    dir="$(dirname "$socket")"
    mkdir -p "$dir"
    chmod 700 "$dir"

    self="$(command -v ojuny 2>/dev/null || printf '%s' "$0")"

    if ojuny_is_dry_run; then
        ojuny_exec socat "UNIX-LISTEN:$socket,fork,mode=0600,unlink-early" "EXEC:$self ipc session"
        return 0
    fi

    exec socat "UNIX-LISTEN:$socket,fork,mode=0600,unlink-early" "EXEC:$self ipc session"
}

ipc_add_id() {
    local id="$1"
    jq -c --arg id "$id" '. + {id:$id}'
}

ipc_method_is_destructive() {
    local method="$1"
    local kind path
    if [[ "$method" == *.* ]]; then
        kind="cmd"
        path="$method"
    else
        kind="top"
        path="$method"
    fi
    [ "$(ojuny_command_field "$kind" "$path" destructive)" = "1" ]
}

ipc_method_handler() {
    local method="$1"
    if [[ "$method" == *.* ]]; then
        ojuny_command_handler "${method%%.*}" "${method#*.}"
    else
        ojuny_top_handler "$method"
    fi
}

ipc_topic_method() {
    case "$1" in
    status) printf 'status\n' ;;
    network) printf 'network.status\n' ;;
    wifi) printf 'wifi.status\n' ;;
    bluetooth) printf 'bluetooth.status\n' ;;
    audio) printf 'sound.current\n' ;;
    media) printf 'media.status\n' ;;
    vpn) printf 'vpn.status\n' ;;
    battery) printf 'system.battery\n' ;;
    dnd | night) printf 'toggle.list\n' ;;
    esac
}

ipc_run_method() {
    local method="$1"
    shift
    local handler
    handler="$(ipc_method_handler "$method")"
    if [ -z "$handler" ]; then
        return "$OJUNY_EXIT_USAGE"
    fi
    "$handler" "$@"
}

ipc_session_response() {
    local id="$1"
    local status="$2"
    local output="$3"
    local errtext="$4"
    local message hint

    if [ "$status" -eq 0 ]; then
        if ojuny_json_has_schema "$output"; then
            printf '%s\n' "$output" | ipc_add_id "$id"
        elif ojuny_json_is_valid "$output"; then
            jq -cn --arg id "$id" --argjson data "$output" \
                '{schema:1,id:$id,ok:true,data:$data,meta:{}}'
        else
            jq -cn --arg id "$id" --arg output "$output" \
                '{schema:1,id:$id,ok:true,data:{output:$output},meta:{}}'
        fi
        return 0
    fi

    message="$(printf '%s' "$output" | head -n 1)"
    [ -n "$message" ] || message="$(printf '%s' "$errtext" | head -n 1)"
    [ -n "$message" ] || message="command failed"
    hint="$(printf '%s' "$errtext" | grep -E '^  hint:' | head -n 1 | sed 's/^  hint: //')" || hint=""
    jq -cn --arg id "$id" --argjson code "$status" --arg message "$message" --arg hint "$hint" \
        '{schema:1,id:$id,ok:false,error:{code:$code,message:$message,hint:$hint}}'
    return 0
}

ipc_session_call() {
    local request="$1"
    local id method confirm handler status output errfile errtext
    local -a args=()

    id="$(printf '%s' "$request" | jq -r '.id // empty')"
    [ -n "$id" ] || id="-"
    method="$(printf '%s' "$request" | jq -r '.method // empty')"
    confirm="$(printf '%s' "$request" | jq -r '.confirm // false')"

    if [ -z "$method" ]; then
        jq -cn --arg id "$id" --argjson code "$OJUNY_EXIT_USAGE" \
            '{schema:1,id:$id,ok:false,error:{code:$code,message:"missing method",hint:""}}'
        return 0
    fi

    case "$method" in
    ipc | ipc.*)
        jq -cn --arg id "$id" --argjson code "$OJUNY_EXIT_USAGE" \
            '{schema:1,id:$id,ok:false,error:{code:$code,message:"ipc methods cannot be called over ipc",hint:""}}'
        return 0
        ;;
    esac

    handler="$(ipc_method_handler "$method")"
    if [ -z "$handler" ]; then
        jq -cn --arg id "$id" --argjson code "$OJUNY_EXIT_USAGE" --arg method "$method" \
            '{schema:1,id:$id,ok:false,error:{code:$code,message:("unknown method: " + $method),hint:""}}'
        return 0
    fi

    if ipc_method_is_destructive "$method" && [ "$confirm" != "true" ]; then
        jq -cn --arg id "$id" --argjson code "$OJUNY_EXIT_VALIDATION" \
            '{schema:1,id:$id,ok:false,error:{code:$code,message:"destructive method requires confirm",hint:"send \"confirm\":true"}}'
        return 0
    fi

    while IFS= read -r arg; do
        args+=("$arg")
    done < <(printf '%s' "$request" | jq -r '.args[]? | tostring')

    errfile="$(mktemp "${TMPDIR:-/tmp}/ojuny-ipc.XXXXXX")"
    set +e
    output="$(ipc_run_method "$method" "${args[@]}" 2>"$errfile")"
    status=$?
    set -e
    errtext="$(cat "$errfile" 2>/dev/null || true)"
    rm -f "$errfile"

    ipc_session_response "$id" "$status" "$output" "$errtext"
}

ipc_session() {
    local line
    local -A topics=()
    local -A topic_last=()
    local -A topic_value=()
    local -A topic_interval=()

    OJUNY_JSON=1

    while true; do
        if IFS= read -r -t 1 line; then
            if [ -z "$line" ]; then
                continue
            fi

            local method
            method="$(printf '%s' "$line" | jq -r '.method // empty')"

            if [ "$method" = "subscribe" ]; then
                local id topic interval_ms interval
                id="$(printf '%s' "$line" | jq -r '.id // empty')"
                topic="$(printf '%s' "$line" | jq -r '.params.topic // empty')"
                interval_ms="$(printf '%s' "$line" | jq -r '.params.interval_ms // 2000')"
                if [ -z "$topic" ] || [ -z "$(ipc_topic_method "$topic")" ]; then
                    jq -cn --arg id "$id" --argjson code "$OJUNY_EXIT_USAGE" --arg topic "$topic" \
                        '{schema:1,id:$id,ok:false,error:{code:$code,message:("unknown topic: " + $topic),hint:""}}'
                    continue
                fi
                interval=$(((interval_ms + 999) / 1000))
                [ "$interval" -ge 1 ] || interval=1
                topics["$topic"]=1
                topic_interval["$topic"]="$interval"
                topic_last["$topic"]=0
                unset 'topic_value[$topic]'
                jq -cn --arg id "$id" --arg topic "$topic" \
                    '{schema:1,id:$id,ok:true,data:{subscribed:$topic},meta:{}}'
                continue
            fi

            if [ "$method" = "unsubscribe" ]; then
                local id topic
                id="$(printf '%s' "$line" | jq -r '.id // empty')"
                topic="$(printf '%s' "$line" | jq -r '.params.topic // empty')"
                unset 'topics[$topic]'
                unset 'topic_interval[$topic]'
                unset 'topic_last[$topic]'
                unset 'topic_value[$topic]'
                jq -cn --arg id "$id" --arg topic "$topic" \
                    '{schema:1,id:$id,ok:true,data:{unsubscribed:$topic},meta:{}}'
                continue
            fi

            ipc_session_call "$line"
            continue
        else
            local read_status=$?
            if [ "$read_status" -le 128 ]; then
                break
            fi
        fi

        local topic now interval data
        now="$(date +%s)"
        for topic in "${!topics[@]}"; do
            interval="${topic_interval[$topic]:-2}"
            if [ $((now - ${topic_last[$topic]:-0})) -lt "$interval" ]; then
                continue
            fi
            topic_last["$topic"]="$now"
            data="$(ipc_run_method "$(ipc_topic_method "$topic")" 2>/dev/null || true)"
            if [ -z "$data" ] || ! printf '%s' "$data" | jq -e . >/dev/null 2>&1; then
                data="$(jq -cn --arg output "$data" '{output:$output}')"
            fi
            if [ "$data" = "${topic_value[$topic]:-}" ]; then
                continue
            fi
            topic_value["$topic"]="$data"
            jq -cn --arg topic "$topic" --argjson data "$data" \
                '{event:$topic,topic:$topic,data:$data}'
        done
    done
}

ipc_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    path) ipc_path ;;
    status) ipc_status ;;
    call) ipc_call "$@" ;;
    watch) ipc_watch "$@" ;;
    serve) ipc_serve ;;
    session) ipc_session ;;
    "")
        ipc_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny ipc <path|status|call|watch|serve|session>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
