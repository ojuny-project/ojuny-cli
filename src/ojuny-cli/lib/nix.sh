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
    nixos-rebuild switch --rollback
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
