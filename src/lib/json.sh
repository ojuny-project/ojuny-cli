ojuny_json_is_valid() {
    jq -e . <<<"$1" >/dev/null 2>&1
}

ojuny_json_has_schema() {
    jq -e '.schema == 1' <<<"$1" >/dev/null 2>&1
}

ojuny_json_ok() {
    local command="$1"
    local data="${2:-}"

    if command -v jq >/dev/null 2>&1; then
        if [ -n "$data" ] && ojuny_json_is_valid "$data"; then
            jq -cn --arg command "$command" --argjson data "$data" \
                '{schema:1,command:$command,ok:true,data:$data,meta:{}}'
        else
            jq -cn --arg command "$command" --arg output "$data" \
                '{schema:1,command:$command,ok:true,data:{output:$output},meta:{}}'
        fi
        return 0
    fi

    printf '{"schema":1,"command":"%s","ok":true}\n' "$command"
}

ojuny_json_error() {
    local command="$1"
    local code="$2"
    local message="$3"
    local hint="${4:-}"

    if command -v jq >/dev/null 2>&1; then
        jq -cn --arg command "$command" --argjson code "$code" --arg message "$message" --arg hint "$hint" \
            '{schema:1,command:$command,ok:false,error:{code:$code,message:$message,hint:$hint}}'
        return 0
    fi

    printf '{"schema":1,"command":"%s","ok":false,"error":{"code":%s}}\n' "$command" "$code"
}

ojuny_json_action() {
    local command="$1"
    local target="$2"
    local changed="${3:-true}"

    if command -v jq >/dev/null 2>&1; then
        jq -cn --arg command "$command" --arg target "$target" --argjson changed "$changed" \
            '{schema:1,command:$command,ok:true,data:{changed:$changed,target:$target},meta:{}}'
        return 0
    fi

    printf '{"schema":1,"command":"%s","ok":true,"data":{"target":"%s"}}\n' "$command" "$target"
}
