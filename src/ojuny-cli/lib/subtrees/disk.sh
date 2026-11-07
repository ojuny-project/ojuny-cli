disk_list() {
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
}

disk_mount() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny disk mount <device>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command udisksctl
    ojuny_exec udisksctl mount -b "$1"
}

disk_unmount() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny disk unmount <device>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command udisksctl
    ojuny_exec udisksctl unmount -b "$1"
}

disk_eject() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny disk eject <device>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command udisksctl
    ojuny_exec udisksctl power-off -b "$1"
}

disk_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) disk_list ;;
    mount) disk_mount "$@" ;;
    unmount) disk_unmount "$@" ;;
    eject) disk_eject "$@" ;;
    "")
        disk_list
        ;;
    *)
        ojuny_usage_error "usage: ojuny disk <list|mount|unmount|eject>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
