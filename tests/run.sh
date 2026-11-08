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

for name in mmsg dms nmcli mmcli bluetoothctl wpctl playerctl rfkill \
    udisksctl systemctl loginctl journalctl sbctl upower wtype ydotool \
    nix-settings-gui ojuny-screenshot-menu ojuny-capture-text ojuny-capture-qr \
    ojuny-screenshot-edit socat; do
    write_fake "$name"
done

cat >"$tmp/bin/coredumpctl" <<EOF
#!$BASH
printf '%s:%s\n' "coredumpctl" "\$*" >>"\$TEST_LOG"
case "\$*" in
    "list --json=short --no-pager")
        printf '%s\n' '[{"time":1700000000000000,"pid":12345,"uid":1000,"gid":100,"sig":11,"corefile":"present","exe":"/usr/bin/fake-exe","size":1000}]'
        ;;
    "info --no-pager"*)
        printf 'fake crash details\n'
        ;;
esac
EOF
chmod +x "$tmp/bin/coredumpctl"

cat >"$tmp/bin/dms" <<EOF
#!$BASH
printf '%s:%s\n' "dms" "\$*" >>"\$TEST_LOG"
case "\$*" in
    --version) echo "dms test" ;;
    version) echo "dms test" ;;
    "clipboard paste") printf 'hello\n' ;;
    "ipc call dock status") echo "hidden" ;;
    "ipc call island status") echo '{"available":true,"enabled":true}' ;;
esac
EOF
chmod +x "$tmp/bin/dms"

cat >"$tmp/bin/systemctl" <<EOF
#!$BASH
printf '%s:%s\n' "systemctl" "\$*" >>"\$TEST_LOG"
EOF
chmod +x "$tmp/bin/systemctl"

export PATH="$tmp/bin:$PATH"

ojuny_prefix="$(cd "$(dirname "$OJUNY_BIN")/.." && pwd)"
ojuny_lib="$ojuny_prefix/share/ojuny-cli/lib"
ojuny_direct="$ojuny_prefix/libexec/ojuny"
ojuny_cli() {
    OJUNY_LIB_DIR="$ojuny_lib" OJUNY_VERSION=test "$ojuny_direct" "$@"
}

assert_contains "$(ojuny_cli --help)" "Usage: ojuny"
assert_contains "$(ojuny_cli --help)" "wifi"
assert_contains "$(ojuny_cli --help)" "secureboot"
assert_contains "$(ojuny_cli --help)" "multiboot"
assert_contains "$(ojuny_cli --version)" "ojuny"
assert_contains "$(ojuny_cli dux --help)" "Usage: ojuny dux"
assert_contains "$(ojuny_cli settings --help)" "Open nix-settings-gui"
assert_contains "$(ojuny_cli multiboot status)" "Multiboot helper"

assert_status 2 ojuny_cli unknown-category
assert_status 2 ojuny_cli bar preset taskbar
assert_status 2 ojuny_cli flake update
assert_status 2 ojuny_cli display resolution

ojuny_cli dux
ojuny_cli keybinds
ojuny_cli clipboard echo
ojuny_cli window float
ojuny_cli workspace view 2
ojuny_cli wifi status
ojuny_cli bluetooth status
ojuny_cli service restart demo

log="$(cat "$TEST_LOG")"
assert_contains "$log" "dms:version"
assert_contains "$log" "dms:ipc call keybinds open binds"
assert_contains "$log" "mmsg:dispatch togglefloating"
assert_contains "$log" "mmsg:dispatch view,2"
assert_contains "$log" "systemctl:--user restart demo"

assert_contains "$(ojuny_cli clipboard echo)" "hello"

json="$(ojuny_cli --json status)"
printf '%s' "$json" | jq -e '.schema == 1 and .ok == true' >/dev/null ||
    fail "status JSON is invalid: $json"

catalog="$(ojuny_cli --json commands)"
printf '%s' "$catalog" | jq -e '.data.commands | length > 100' >/dev/null ||
    fail "command catalog is missing entries"

assert_contains "$(ojuny_cli completions bash)" "complete -F _ojuny ojuny"
assert_contains "$(ojuny_cli print-agent-details)" "sudo ojuny service restart"

settings_out="$(ojuny_cli --dry-run settings bar 2>&1)"
assert_contains "$settings_out" "nix-settings-gui --page bar"

assert_status 5 ojuny_cli --system service restart demo

mkdir -p "$tmp/vpn"
printf '[Interface]\n' >"$tmp/work.conf"
OJUNY_WIREGUARD_DIR="$tmp/vpn" ojuny_cli vpn import "$tmp/work.conf"
[ -f "$tmp/vpn/work.conf" ] || fail "vpn import did not copy the profile"
[ "$(stat -c %a "$tmp/vpn/work.conf")" = "600" ] || fail "vpn import did not use mode 600"

export XDG_STATE_HOME="$tmp/state"
ojuny_cli trackpad on
ojuny_cli trackpad off
ojuny_cli trackpad off
trackpad_toggles="$(grep -c 'mmsg:dispatch toggle_trackpad_enable' "$TEST_LOG" || true)"
[ "$trackpad_toggles" -eq 1 ] || fail "trackpad on/off did not toggle exactly once"

assert_contains "$(ojuny_cli ipc path)" "ipc.sock"
ipc_response="$(printf '%s\n' '{"schema":1,"id":"1","method":"status","args":[]}' | ojuny_cli ipc session)"
assert_contains "$ipc_response" '"id":"1"'
assert_contains "$ipc_response" '"ok":true'
destructive_response="$(printf '%s\n' '{"schema":1,"id":"2","method":"system.reboot","args":[]}' | ojuny_cli ipc session)"
assert_contains "$destructive_response" '"code":5'
assert_contains "$destructive_response" 'requires confirm'

assert_contains "$(ojuny_cli print-system-details)" "DE/WM:"
assert_contains "$(ojuny_cli crashes)" "fake-exe"
assert_contains "$(ojuny_cli crashes latest)" "fake crash details"
assert_contains "$(ojuny_cli crashes 1)" "fake crash details"

ojuny_cli debug on
ojuny_cli --dry-run wifi connect mynet supersecret >/dev/null 2>&1
assert_contains "$(ojuny_cli debug tail)" "[redacted]"
if ojuny_cli debug tail | grep -q 'supersecret'; then
    fail "debug log leaked a password"
fi
ojuny_cli debug off

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
