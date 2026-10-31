patches_install_one() {
    local id="$1"
    local stack="${2:-}"
    local dest meta patch repos count repo dep candidate legacy legacy_count

    if ! patches_id_valid "$id"; then
        ojuny_err "invalid patch id: $id"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    case ",$stack," in
    *",$id,"*)
        ojuny_err "dependency cycle: $stack -> $id"
        return "$OJUNY_EXIT_CONFLICT"
        ;;
    esac

    dest="$(ojuny_patch_dir)/$id.nix"

    legacy=""
    legacy_count=0
    for candidate in "$(ojuny_patch_dir)"/[0-9][0-9]-"$id".nix; do
        [ -e "$candidate" ] || continue
        legacy="$candidate"
        legacy_count=$((legacy_count + 1))
    done

    if [ -f "$dest" ]; then
        if [ "$legacy_count" -gt 0 ]; then
            ojuny_err "conflict: both $dest and legacy $legacy exist; remove the legacy file first"
            return "$OJUNY_EXIT_CONFLICT"
        fi
        printf 'already installed: %s\n' "$id"
        return 0
    fi

    if [ "$legacy_count" -gt 1 ]; then
        ojuny_err "conflict: multiple legacy files for $id in $(ojuny_patch_dir); remove all but one"
        return "$OJUNY_EXIT_CONFLICT"
    fi

    if [ "$legacy_count" -eq 1 ]; then
        mv -- "$legacy" "$dest"
        printf 'upgraded legacy patch %s -> %s\n' "$legacy" "$dest"
        return 0
    fi

    repos="$(patches_find_repos "$id")" || {
        ojuny_err "patch not found: $id"
        return "$OJUNY_EXIT_VALIDATION"
    }

    count="$(printf '%s\n' "$repos" | wc -l)"
    if [ "$count" -gt 1 ]; then
        ojuny_err "patch id exists in multiple repositories:"
        printf '%s\n' "$repos" >&2
        return "$OJUNY_EXIT_CONFLICT"
    fi

    repo="$repos"
    patch="$(patches_patch_file "$repo" "$id")"
    meta="$(patches_metadata_file "$repo" "$id")"

    patches_metadata_validate "$meta" "$id" || return

    ojuny_require_command nix
    if ! nix-instantiate --parse "$patch" >/dev/null 2>&1; then
        ojuny_err "patch does not parse: $patch"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    if ! grep -Eq "flake[.]modules[.](nixos|homeManager)[.]\"?${id}\"?" "$patch"; then
        ojuny_err "patch does not define flake.modules.*.$id: $patch"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    while IFS= read -r dep; do
        [ -n "$dep" ] || continue
        if [ ! -f "$(ojuny_patch_dir)/$dep.nix" ]; then
            patches_install_one "$dep" "${stack:+$stack,}$id" || return
        fi
    done < <(patches_metadata_dependencies "$meta")

    mkdir -p "$(ojuny_patch_dir)"
    cp -- "$patch" "$dest"
    printf 'installed %s\n' "$id"
}

patches_install() {
    local id="${1:-}"

    [ -n "$id" ] || {
        ojuny_err "usage: ojuny-patches install <id>"
        return "$OJUNY_EXIT_USAGE"
    }

    patches_install_one "$id"
}

patches_remove() {
    local id="${1:-}"
    local dest

    [ -n "$id" ] || {
        ojuny_err "usage: ojuny-patches remove <id>"
        return "$OJUNY_EXIT_USAGE"
    }

    if ! patches_id_valid "$id"; then
        ojuny_err "invalid patch id: $id"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    dest="$(ojuny_patch_dir)/$id.nix"
    if [ ! -f "$dest" ]; then
        ojuny_err "patch is not installed: $id"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    ojuny_confirm "Remove patch $id from $(ojuny_patch_dir)?" || return 1
    rm -- "$dest"
    printf 'removed %s\n' "$id"
}

patches_reinstall() {
    local id="${1:-}"
    local dest

    [ -n "$id" ] || {
        ojuny_err "usage: ojuny-patches reinstall <id>"
        return "$OJUNY_EXIT_USAGE"
    }

    dest="$(ojuny_patch_dir)/$id.nix"
    if [ -f "$dest" ]; then
        patches_remove "$id" || return
    fi

    patches_install "$id"
}
