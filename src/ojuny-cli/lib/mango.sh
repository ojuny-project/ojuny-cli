mdispatch() {
    local dispatcher="$1"
    shift

    if [ "$#" -eq 0 ]; then
        ojuny_exec_quiet mmsg dispatch "$dispatcher"
    else
        local IFS=,
        ojuny_exec_quiet mmsg dispatch "$dispatcher,$*"
    fi
}

mmsg_get() {
    mmsg get "$@"
}

mclientlist() {
    mmsg get all-clients
}

msetlayout() {
    mdispatch setlayout "$@"
}

msetworkspace() {
    mdispatch view "$1"
}

mtoggleworkspace() {
    mdispatch toggleview "$1"
}

mreloadconfig() {
    mdispatch reload_config
}

mspawn() {
    [ "$#" -ge 1 ] || return 2
    local command="$1"
    shift
    mdispatch spawn "$command" "$@"
}

mspawnshell() {
    [ "$#" -ge 1 ] || return 2
    local command="$*"
    mdispatch spawn_shell "$command"
}

moverview() {
    mdispatch toggleoverview
}

mjump() {
    mdispatch togglejump
}

mkeymode() {
    mdispatch setkeymode "$1"
}

mtrackpad() {
    mdispatch toggle_trackpad_enable
}

mtogglemon() {
    mdispatch togglemon
}

msleepmon() {
    mdispatch sleepmon
}

mkillclient() {
    mdispatch killclient
}

mfocusdir() {
    mdispatch focusdir "$1"
}

mmoveclient() {
    mdispatch move_client "$1"
}

mexchangeclient() {
    mdispatch exchange_client "$1"
}

msmartresize() {
    mdispatch smartresizewin "$1"
}

mfullscreen() {
    mdispatch togglefullscreen
}

mmaximize() {
    mdispatch togglemaximizescreen
}

mfloat() {
    mdispatch togglefloating
}

mfloatall() {
    mdispatch toggle_all_floating
}

mminimize() {
    mdispatch minimized
}

mrestore() {
    mdispatch restore_minimized
}

mtogglespecial() {
    mdispatch toggle_special_tag
}

mtagspecial() {
    mdispatch tag_special_tag
}

mgroupleave() {
    mdispatch groupleave
}

mcomboview() {
    mdispatch comboview "$1"
}

mtagsilent() {
    mdispatch tagsilent "$1"
}

mtoggleview() {
    mdispatch toggleview "$1"
}

mviewtoleft() {
    mdispatch viewtoleft "${1:-0}"
}

mviewtoright() {
    mdispatch viewtoright "${1:-0}"
}

mviewnextclient() {
    mdispatch viewnext_have_client
}

mviewprevclient() {
    mdispatch viewprev_have_client
}

mquit() {
    mdispatch quit
}

mcurrentlayout() {
    local monitor
    monitor="$(mmsg get all-monitors | jq -r '.monitors[] | select(.active == true) | .name' | head -n 1)"
    [ -n "$monitor" ] || return 1
    mmsg get monitor "$monitor" | jq -r '.tags[] | select(.is_active == true) | .layout'
}
