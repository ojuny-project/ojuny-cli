nix_flake_update() {
    local flake="$1"
    local input="$2"
    (cd "$flake" && nix flake update "$input")
}

nix_flake_check() {
    local flake="$1"
    nix flake check "$flake"
}

nixos_dry_build() {
    local flake="$1"
    local host="$2"
    shift 2
    nixos-rebuild dry-build --flake "$flake#$host" "$@"
}

nixos_build() {
    local flake="$1"
    local host="$2"
    shift 2
    nixos-rebuild build --flake "$flake#$host" "$@"
}

nixos_activate_boot() {
    local flake="$1"
    local host="$2"
    nixos-rebuild boot --flake "$flake#$host"
}

nixos_activate_now() {
    local flake="$1"
    local host="$2"
    nixos-rebuild switch --flake "$flake#$host"
}

nixos_rollback() {
    local flake="$1"
    local host="$2"
    local generation="${3:-}"
    local profile="${OJUNY_SYSTEM_PROFILE:-/nix/var/nix/profiles/system}"
    if [ -z "$generation" ]; then
        ojuny_exec nixos-rebuild switch --rollback --flake "$flake#$host"
        return
    fi
    ojuny_exec nix-env --switch-generation "$generation" -p "$profile"
    ojuny_exec "$profile/bin/switch-to-configuration" switch
}

nixos_generation_current() {
    local link generation
    link="$(readlink "${OJUNY_SYSTEM_PROFILE:-/nix/var/nix/profiles/system}" 2>/dev/null)" || return 1
    case "$link" in
    system-*-link) ;;
    *) return 1 ;;
    esac
    generation="${link#system-}"
    printf '%s\n' "${generation%-link}"
}

nixos_generation_booted() {
    local booted link generation
    booted="$(readlink -f "${OJUNY_BOOTED_SYSTEM:-/run/booted-system}" 2>/dev/null)" || return 1
    [ -n "$booted" ] || return 1
    for link in "$(dirname "${OJUNY_SYSTEM_PROFILE:-/nix/var/nix/profiles/system}")"/system-*-link; do
        [ -e "$link" ] || continue
        [ "$(readlink -f "$link")" = "$booted" ] || continue
        generation="${link##*/system-}"
        printf '%s\n' "${generation%-link}"
        return 0
    done
    return 1
}

nixos_generation_back() {
    local back="$1" current target profile
    case "$back" in
    "" | *[!0-9]*) return 1 ;;
    esac
    [ "$back" -ge 1 ] || return 1
    profile="${OJUNY_SYSTEM_PROFILE:-/nix/var/nix/profiles/system}"
    current="$(nixos_generation_current)" || return 1
    target=$((current - back))
    [ "$target" -ge 1 ] || return 1
    [ -e "$(dirname "$profile")/system-$target-link" ] || return 1
    printf '%s\n' "$target"
}

nixos_generations() {
    nixos-rebuild list-generations
}

nixos_option() {
    local path="$1"
    nixos-option "$path"
}

nix_collect_garbage() {
    nix-collect-garbage "$@"
}
