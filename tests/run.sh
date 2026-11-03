#!/usr/bin/env bash
set -euo pipefail

: "${OJUNY_BIN:?OJUNY_BIN is not set}"
: "${OJUNY_PATCHES_BIN:?OJUNY_PATCHES_BIN is not set}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home"
export XDG_CONFIG_HOME="$tmp/config"
export XDG_CACHE_HOME="$tmp/cache"
export TEST_LOG="$tmp/backends.log"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$tmp/bin"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local value="$1"
    local expected="$2"
    printf '%s' "$value" | grep -Fq -- "$expected" || fail "missing '$expected' in '$value'"
}

assert_status() {
    local expected="$1"
    shift
    local status=0
    "$@" >/dev/null 2>&1 || status=$?
    [ "$status" -eq "$expected" ] || fail "expected status $expected, got $status: $*"
}

write_fake() {
    local name="$1"
    cat >"$tmp/bin/$name" <<EOF
#!$BASH
printf '%s:%s\n' "$name" "\$*" >>"\$TEST_LOG"
EOF
    chmod +x "$tmp/bin/$name"
}

for name in mmsg dms nmcli bluetoothctl wpctl playerctl wg wg-quick systemctl loginctl; do
    write_fake "$name"
done

cat >"$tmp/bin/dms" <<EOF
#!$BASH
printf '%s:%s\n' "dms" "\$*" >>"\$TEST_LOG"
if [ "\$*" = "ipc call settings get barConfigs" ]; then
    printf '%s\n' '[{"id":"default","island":true},{"id":"taskbar","island":false},{"id":"status","island":false},{"id":"caelestia","island":false},{"id":"disabled","island":false,"enabled":false}]'
fi
EOF
chmod +x "$tmp/bin/dms"

export PATH="$tmp/bin:$PATH"

ojuny_prefix="$(cd "$(dirname "$OJUNY_BIN")/.." && pwd)"
ojuny_lib="$ojuny_prefix/share/ojuny-cli/lib"
ojuny_direct="$ojuny_prefix/libexec/ojuny"
ojuny_cli() {
    OJUNY_LIB_DIR="$ojuny_lib" OJUNY_VERSION=test "$ojuny_direct" "$@"
}

assert_contains "$(ojuny_cli --help)" "Usage: ojuny"
assert_contains "$(ojuny_cli --help)" "dux"
assert_contains "$(ojuny_cli --version)" "ojuny"
assert_contains "$(ojuny_cli network --help)" "Usage: ojuny network"
assert_contains "$(ojuny_cli dux --help)" "Usage: ojuny dux"
assert_status 2 ojuny_cli unknown-category

ojuny_cli dux status
dms_alias_stderr="$(ojuny_cli dms status 2>&1 >/dev/null)"
assert_contains "$dms_alias_stderr" "deprecated"
assert_contains "$(cat "$TEST_LOG")" "dms:--version"

ojuny_cli window float
ojuny_cli window maximize
ojuny_cli workspace view 2
ojuny_cli nw status
ojuny_cli settings open network
ojuny_cli capture full
ojuny_cli session quit
ojuny_cli system lock

log="$(cat "$TEST_LOG")"
assert_contains "$log" "mmsg:dispatch togglefloating"
assert_contains "$log" "mmsg:dispatch togglemaximizescreen"
assert_contains "$log" "mmsg:dispatch view,2"
assert_contains "$log" "nmcli:general status"
assert_contains "$log" "dms:ipc call settings focusOrToggleWith network"
assert_contains "$log" "dms:screenshot full"
assert_contains "$log" "mmsg:dispatch quit"
assert_contains "$log" "loginctl:lock-session"

ojuny_cli bar preset taskbar
ojuny_cli bar preset caelestia
assert_status 5 ojuny_cli bar preset default
assert_status 5 ojuny_cli bar preset disabled
assert_status 2 ojuny_cli bar preset nope
log="$(cat "$TEST_LOG")"
assert_contains "$log" "dms:ipc call settings set frameEnabled false"
assert_contains "$log" "dms:ipc call settings set frameEnabled true"
assert_contains "$log" "dms:ipc call bar hide id status"
assert_contains "$log" "dms:ipc call bar reveal id taskbar"
assert_contains "$log" "dms:ipc call bar reveal id caelestia"

assert_contains "$("$OJUNY_PATCHES_BIN" --help)" "Usage: ojuny-patches"
assert_contains "$("$OJUNY_PATCHES_BIN" --version)" "ojuny-patches"
assert_contains "$("$OJUNY_PATCHES_BIN" repo list)" "https://github.com/ojuny-project/ojuny-patches"

flake="$tmp/flake"
registry="$tmp/registry"
mkdir -p "$flake/modules/patches" "$registry/modules/patches"
mkdir -p "$registry/patch-base" "$registry/patch-demo" "$registry/patch-cycle-a" "$registry/patch-cycle-b"

printf '{ ... }: { flake.modules.nixos.patch-base = { }: { }; }\n' >"$registry/modules/patches/patch-base.nix"
printf 'name: Base\nid: patch-base\ndescription: Base patch\nversion: 1\n' >"$registry/patch-base/metadata.md"

printf '{ ... }: { flake.modules.nixos.patch-demo = { }: { }; }\n' >"$registry/modules/patches/patch-demo.nix"
printf 'name: Demo\nid: patch-demo\ndescription: Demo patch\ndependencies: patch-base\nversion: 1\n' >"$registry/patch-demo/metadata.md"

printf '{ ... }: { flake.modules.nixos.patch-cycle-a = { }: { }; }\n' >"$registry/modules/patches/patch-cycle-a.nix"
printf 'name: Cycle A\nid: patch-cycle-a\ndescription: Cycle A\ndependencies: patch-cycle-b\nversion: 1\n' >"$registry/patch-cycle-a/metadata.md"

printf '{ ... }: { flake.modules.nixos.patch-cycle-b = { }: { }; }\n' >"$registry/modules/patches/patch-cycle-b.nix"
printf 'name: Cycle B\nid: patch-cycle-b\ndescription: Cycle B\ndependencies: patch-cycle-a\nversion: 1\n' >"$registry/patch-cycle-b/metadata.md"

git -C "$registry" init -q
git -C "$registry" config user.email test@example.com
git -C "$registry" config user.name Test
git -C "$registry" add .
git -C "$registry" commit -qm initial

"$OJUNY_PATCHES_BIN" repo add "$registry" >/dev/null
"$OJUNY_PATCHES_BIN" configure local_repository "$flake" >/dev/null
"$OJUNY_PATCHES_BIN" sync "$registry" >/dev/null

assert_contains "$("$OJUNY_PATCHES_BIN" list available)" "patch-demo"
"$OJUNY_PATCHES_BIN" install patch-demo >/dev/null
[ -f "$flake/modules/patches/patch-base.nix" ] || fail "base dependency was not installed"
[ -f "$flake/modules/patches/patch-demo.nix" ] || fail "demo patch was not installed"
assert_contains "$("$OJUNY_PATCHES_BIN" list installed)" "patch-demo"
assert_contains "$("$OJUNY_PATCHES_BIN" info patch-demo)" "dependencies: patch-base"
assert_status 6 "$OJUNY_PATCHES_BIN" install patch-cycle-a
[ ! -f "$flake/modules/patches/patch-cycle-a.nix" ] || fail "cycle patch was installed"
"$OJUNY_PATCHES_BIN" --yes remove patch-demo >/dev/null
[ ! -f "$flake/modules/patches/patch-demo.nix" ] || fail "demo patch was not removed"

printf 'all tests passed\n'
