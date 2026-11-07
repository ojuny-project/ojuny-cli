patches_installed_name() {
    local id="$1"
    local repos repo

    if repos="$(patches_find_repos "$id")"; then
        repo="$(printf '%s\n' "$repos" | head -n 1)"
        patches_metadata_get "$(patches_metadata_file "$repo" "$id")" name
    else
        printf 'unknown\n'
    fi
}

patches_list_available() {
    local url dir patch id meta name

    patches_ensure_repos_file

    while IFS= read -r url; do
        [ -n "$url" ] || continue
        dir="$(patches_cache_repo_dir "$url")"
        [ -d "$dir" ] || continue
        for patch in "$dir"/modules/patches/*.nix; do
            [ -e "$patch" ] || continue
            id="$(basename "$patch" .nix)"
            meta="$(patches_metadata_file "$dir" "$id")"
            name="$(patches_metadata_get "$meta" name || true)"
            printf '%s\t%s\t%s\n' "$id" "${name:-unknown}" "$(patches_repo_label "$dir")"
        done
    done <"$(patches_repos_file)" | sort
}

patches_list_installed() {
    local dir file id name

    dir="$(ojuny_patch_dir)"
    [ -d "$dir" ] || return 0

    for file in "$dir"/patch-*.nix; do
        [ -e "$file" ] || continue
        id="$(basename "$file" .nix)"
        name="$(patches_installed_name "$id")"
        printf '%s\t%s\tinstalled\n' "$id" "$name"
    done | sort
}

patches_list() {
    case "${1:-}" in
    available)
        patches_list_available
        ;;
    installed)
        patches_list_installed
        ;;
    *)
        ojuny_err "usage: ojuny-patches list <available|installed>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

patches_info() {
    local id="${1:-}"
    local repos repo meta commit installed

    [ -n "$id" ] || {
        ojuny_err "usage: ojuny-patches info <id>"
        return "$OJUNY_EXIT_USAGE"
    }

    if ! patches_id_valid "$id"; then
        ojuny_err "invalid patch id: $id"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    installed="$(ojuny_patch_dir)/$id.nix"

    if repos="$(patches_find_repos "$id")"; then
        while IFS= read -r repo; do
            meta="$(patches_metadata_file "$repo" "$id")"
            commit="$(patches_repo_commit "$repo")"
            printf 'id: %s\n' "$id"
            printf 'name: %s\n' "$(patches_metadata_get "$meta" name)"
            printf 'description: %s\n' "$(patches_metadata_get "$meta" description)"
            printf 'version: %s\n' "$(patches_metadata_get "$meta" version)"
            printf 'dependencies: %s\n' "$(patches_metadata_get "$meta" dependencies)"
            printf 'repository: %s\n' "$repo"
            printf 'commit: %s\n' "$commit"
            printf 'patch: %s\n' "$(patches_patch_file "$repo" "$id")"
            if [ -f "$installed" ]; then
                printf 'installed: yes\n'
            else
                printf 'installed: no\n'
            fi
        done <<<"$repos"
        return 0
    fi

    if [ -f "$installed" ]; then
        printf 'id: %s\n' "$id"
        printf 'name: %s\n' "$(patches_installed_name "$id")"
        printf 'installed: yes\n'
        printf 'patch: %s\n' "$installed"
        return 0
    fi

    ojuny_err "patch not found: $id"
    return "$OJUNY_EXIT_VALIDATION"
}

patches_configure() {
    local key="${1:-}"
    local value="${2:-}"

    case "$key" in
    local_repository | patch_directory) ;;
    *)
        ojuny_err "usage: ojuny-patches configure <local_repository|patch_directory> <value>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac

    [ -n "$value" ] || {
        ojuny_err "configuration value must not be empty"
        return "$OJUNY_EXIT_USAGE"
    }

    patches_config_set "$key" "$value"
    printf '%s=%s\n' "$key" "$value"
}

patches_repo() {
    case "${1:-}" in
    list)
        patches_repo_list
        ;;
    add)
        shift || true
        patches_repo_add "$@"
        ;;
    remove)
        shift || true
        patches_repo_remove "$@"
        ;;
    *)
        ojuny_err "usage: ojuny-patches repo <list|add|remove>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

patches_main() {
    local command="${1:-}"
    shift || true

    case "$command" in
    sync)
        patches_sync "$@"
        ;;
    list)
        patches_list "$@"
        ;;
    configure)
        patches_configure "$@"
        ;;
    repo)
        patches_repo "$@"
        ;;
    install)
        patches_install "$@"
        ;;
    remove)
        patches_remove "$@"
        ;;
    info)
        patches_info "$@"
        ;;
    reinstall)
        patches_reinstall "$@"
        ;;
    *)
        ojuny_err "unknown command: $command"
        patches_usage >&2
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
