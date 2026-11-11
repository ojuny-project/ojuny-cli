OJUNY_DEFAULT_PATCH_REPO="https://github.com/ojuny-project/ojuny-patches"

ojuny_flake_root() {
    local cfg root

    if [ -n "${OJUNY_FLAKE:-}" ]; then
        if [ ! -f "$OJUNY_FLAKE/flake.nix" ]; then
            ojuny_err "not a flake: $OJUNY_FLAKE"
            return "$OJUNY_EXIT_VALIDATION"
        fi
        printf '%s\n' "$OJUNY_FLAKE"
        return 0
    fi

    if [ -r /etc/ojuny/flake-path ]; then
        root="$(sed -n '1p' /etc/ojuny/flake-path)"
        if [ -n "$root" ] && [ -f "$root/flake.nix" ]; then
            printf '%s\n' "$root"
            return 0
        fi
    fi

    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/nix-settings-gui/config.json"
    if [ -r "$cfg" ] && command -v jq >/dev/null 2>&1; then
        root="$(jq -r '.flake_path // empty' "$cfg" 2>/dev/null || true)"
        if [ -n "$root" ] && [ -f "$root/flake.nix" ]; then
            printf '%s\n' "$root"
            return 0
        fi
    fi

    root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$root" ] && [ -f "$root/flake.nix" ]; then
        printf '%s\n' "$root"
        return 0
    fi

    root="$HOME/repos/nix-flake"
    if [ -f "$root/flake.nix" ]; then
        printf '%s\n' "$root"
        return 0
    fi

    ojuny_err "cannot find flake; use --flake or set OJUNY_FLAKE"
    return "$OJUNY_EXIT_VALIDATION"
}

ojuny_host_name() {
    local flake hosts count self

    if [ -n "${OJUNY_HOST:-}" ]; then
        printf '%s\n' "$OJUNY_HOST"
        return 0
    fi

    ojuny_require_command nix
    ojuny_require_command jq

    flake="$(ojuny_flake_root)" || return
    hosts="$(nix eval --json "$flake#nixosConfigurations" --apply 'builtins.attrNames' 2>/dev/null)" || {
        ojuny_err "cannot evaluate nixosConfigurations in $flake"
        return "$OJUNY_EXIT_VALIDATION"
    }

    count="$(printf '%s' "$hosts" | jq 'length')"
    if [ "$count" -eq 1 ]; then
        printf '%s' "$hosts" | jq -r '.[0]'
        return 0
    fi

    self="$(uname -n)"
    if printf '%s' "$hosts" | jq -e --arg host "$self" 'index($host) != null' >/dev/null; then
        printf '%s\n' "$self"
        return 0
    fi

    ojuny_err "cannot choose host; use --host (available: $(printf '%s' "$hosts" | jq -r 'join(", ")'))"
    return "$OJUNY_EXIT_VALIDATION"
}

ojuny_patches_config_dir() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/ojuny"
}

ojuny_patches_cache_dir() {
    printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/ojuny/patches"
}

ojuny_patches_config_file() {
    printf '%s/patches.conf\n' "$(ojuny_patches_config_dir)"
}

ojuny_patches_repos_file() {
    printf '%s/repos.list\n' "$(ojuny_patches_config_dir)"
}

ojuny_config_get() {
    local file="$1"
    local key="$2"

    [ -r "$file" ] || return 0
    awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$file"
}

ojuny_config_set() {
    local file="$1"
    local key="$2"
    local value="$3"
    local tmp

    mkdir -p "$(dirname "$file")"
    tmp="$(mktemp)"

    if [ -r "$file" ]; then
        awk -F= -v key="$key" '$1 != key' "$file" >"$tmp"
    fi

    printf '%s=%s\n' "$key" "$value" >>"$tmp"
    mv "$tmp" "$file"
}

ojuny_patch_local_repository() {
    local value

    if [ -n "${OJUNY_FLAKE:-}" ]; then
        printf '%s\n' "$OJUNY_FLAKE"
        return 0
    fi

    value="$(ojuny_config_get "$(ojuny_patches_config_file)" local_repository)"
    if [ -n "$value" ]; then
        printf '%s\n' "$value"
        return 0
    fi
    value="$(ojuny_flake_root 2>/dev/null || true)"
    printf '%s\n' "${value:-$HOME/repos/nix-flake}"
}

ojuny_patch_directory() {
    local value

    value="$(ojuny_config_get "$(ojuny_patches_config_file)" patch_directory)"
    printf '%s\n' "${value:-modules/patches}"
}

ojuny_patch_dir() {
    printf '%s/%s\n' "$(ojuny_patch_local_repository)" "$(ojuny_patch_directory)"
}

ojuny_repo_name_from_url() {
    local url="${1%/}"
    url="${url##*/}"
    printf '%s\n' "${url%.git}"
}

ojuny_git_branch() {
    git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown\n'
}

ojuny_git_revision() {
    git -C "$1" rev-parse --short HEAD 2>/dev/null || printf 'unknown\n'
}

ojuny_git_dirty() {
    if [ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]; then
        printf 'dirty\n'
    else
        printf 'clean\n'
    fi
}
