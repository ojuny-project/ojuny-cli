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
    "ipc call dock autoHide true") printf 'Too few arguments provided (2 required but 0 were provided.)\n' ;;
    "keybinds show binds")
        printf '%s\n' '{"provider":"binds","binds":{"Windows":[{"key":"SUPER+q","desc":"Close"}],"Navigation":[{"key":"SUPER+1","desc":"View tag 1"},{"key":"SUPER+2","desc":"View tag 2"}]}}'
        ;;
esac
EOF
chmod +x "$tmp/bin/dms"

cat >"$tmp/bin/nmcli" <<EOF
#!$BASH
printf '%s:%s\n' "nmcli" "\$*" >>"\$TEST_LOG"
case "\$*" in
    "-t -f STATE general") echo "connected" ;;
    "radio wifi") echo "enabled" ;;
esac
EOF
chmod +x "$tmp/bin/nmcli"

cat >"$tmp/bin/wpctl" <<EOF
#!$BASH
printf '%s:%s\n' "wpctl" "\$*" >>"\$TEST_LOG"
if [ -n "\${TEST_WPCTL_FAIL:-}" ]; then
    exit 1
fi
case "\$*" in
    "get-volume @DEFAULT_AUDIO_SINK@") echo "Volume: 0.40" ;;
esac
EOF
chmod +x "$tmp/bin/wpctl"

cat >"$tmp/bin/upower" <<EOF
#!$BASH
printf '%s:%s\n' "upower" "\$*" >>"\$TEST_LOG"
if [ -n "\${TEST_UPOWER_FAIL:-}" ]; then
    exit 1
fi
EOF
chmod +x "$tmp/bin/upower"

cat >"$tmp/bin/uptime" <<EOF
#!$BASH
case "\$1" in
    -p) exit 1 ;;
esac
printf ' 12:00:00 up 1 day,  1 user,  load average: 0.00, 0.00, 0.00\n'
EOF
chmod +x "$tmp/bin/uptime"

cat >"$tmp/bin/loginctl" <<EOF
#!$BASH
printf '%s:%s\n' "loginctl" "\$*" >>"\$TEST_LOG"
case "\$*" in
    "list-sessions --no-legend")
        if [ -n "\${TEST_NO_GRAPHICAL:-}" ]; then
            printf '3 $(id -u) den seat0 tty3\n'
        else
            printf '3 $(id -u) den seat0 tty3\n5 $(id -u) den seat0 tty5\n'
        fi
        ;;
    "show-session 3 -p Type --value") echo "tty" ;;
    "show-session 3 -p Active --value") echo "yes" ;;
    "show-session 3 -p Remote --value") echo "no" ;;
    "show-session 3 -p Seat --value") echo "seat0" ;;
    "show-session 5 -p Type --value") echo "wayland" ;;
    "show-session 5 -p Active --value") echo "yes" ;;
    "show-session 5 -p Remote --value") echo "no" ;;
    "show-session 5 -p Seat --value") echo "seat0" ;;
esac
EOF
chmod +x "$tmp/bin/loginctl"

write_fake nixos-rebuild
write_fake nix-env

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
assert_contains "$(OJUNY_MULTIBOOT_MANIFEST="$tmp/missing.json" ojuny_cli multiboot status)" "Multiboot helper"

status_out="$(ojuny_cli status)"
assert_contains "$status_out" "host"
assert_contains "$status_out" "40% (unmuted)"
assert_contains "$status_out" "dms test"
assert_contains "$(ojuny_cli system status)" "uptime"

printf 'not json\n' >"$tmp/multiboot.json"
status=0
err="$(OJUNY_MULTIBOOT_MANIFEST="$tmp/multiboot.json" ojuny_cli multiboot status 2>&1 >/dev/null)" || status=$?
[ "$status" -eq 5 ] || fail "an invalid multiboot manifest should exit 5, got $status"
assert_contains "$err" "not valid JSON"

cat >"$tmp/bin/efibootmgr" <<EOF
#!$BASH
printf '%s:%s\n' "efibootmgr" "\$*" >>"\$TEST_LOG"
printf '%s\n' \
    'BootCurrent: 0001' \
    'BootOrder: 0001,0002' \
    'Boot0001* Linux Boot Manager' \
    'Boot0002* Windows Boot Manager'
EOF
chmod +x "$tmp/bin/efibootmgr"

assert_contains "$(ojuny_cli recovery status)" "Recovery"
assert_contains "$(ojuny_cli bootorder status)" "BootOrder"

printf '{"helper_state":"enabled","generated_at":"2026-01-01T00:00:00Z","secure_boot":true,"bitlocker":true,"boot_mount":"/boot","systems":[]}\n' >"$tmp/multiboot.json"
multiboot_out="$(OJUNY_MULTIBOOT_MANIFEST="$tmp/multiboot.json" ojuny_cli multiboot status)"
assert_contains "$multiboot_out" "Generated: 2026-01-01T00:00:00Z"
assert_contains "$multiboot_out" "rescan"

ojuny_cli bar hide
ojuny_cli bar show
ojuny_cli bar toggle
log="$(cat "$TEST_LOG")"
assert_contains "$log" "dms:ipc call bar hide index 0"
assert_contains "$log" "dms:ipc call bar reveal index 0"
assert_contains "$log" "dms:ipc call bar toggle index 0"

status=0
err="$(ojuny_cli dock autohide on 2>&1 >/dev/null)" || status=$?
[ "$status" -eq 4 ] || fail "a dux error printed on stdout should exit 4, got $status"
assert_contains "$err" "Too few arguments"

status=0
err="$(TEST_UPOWER_FAIL=1 ojuny_cli system battery 2>&1 >/dev/null)" || status=$?
[ "$status" -eq 4 ] || fail "a silent backend failure should exit 4, got $status"
assert_contains "$err" "system.battery failed (exit 1)"

status=0
json_err="$(TEST_WPCTL_FAIL=1 ojuny_cli --json sound mute toggle 2>/dev/null)" || status=$?
[ "$status" -eq 4 ] || fail "a JSON backend failure should exit 4, got $status"
printf '%s' "$json_err" | jq -e '.error.code == 4' >/dev/null ||
    fail "JSON backend failure code is wrong: $json_err"

keybinds_count="$(ojuny_cli --json keybinds count binds)"
printf '%s' "$keybinds_count" | jq -e '.data.total == 3 and .data.categories.Navigation == 2' >/dev/null ||
    fail "keybinds count is invalid: $keybinds_count"

nosession="$tmp/bin-nosession"
mkdir -p "$nosession"
for file in "$tmp/bin"/*; do
    case "${file##*/}" in
    dms | mmsg) continue ;;
    esac
    ln -sf "$file" "$nosession/${file##*/}"
done
tool_path="$(dirname "$(command -v mktemp)"):$(dirname "$(command -v jq)"):$(dirname "$(command -v grep)"):$(dirname "$(command -v sed)")"
status=0
err="$(PATH="$nosession:$tool_path:/usr/bin:/bin" ojuny_cli dux status 2>&1 >/dev/null)" || status=$?
[ "$status" -eq 3 ] || fail "a missing session dms should exit 3, got $status"
assert_contains "$err" "missing required command: dms"
assert_contains "$err" "desktop session"

lock_out="$(XDG_SESSION_ID=3 ojuny_cli system lock 2>&1)" || fail "system lock failed: $lock_out"
assert_contains "$(cat "$TEST_LOG")" "loginctl:lock-session 5"
if grep -q "loginctl:lock-session 3" "$TEST_LOG"; then
    fail "system lock targeted the tty session"
fi
XDG_SESSION_ID=3 ojuny_cli toggle lockscreen

status=0
err="$(TEST_NO_GRAPHICAL=1 XDG_SESSION_ID=3 ojuny_cli system lock 2>&1 >/dev/null)" || status=$?
[ "$status" -eq 5 ] || fail "system lock without a graphical session should exit 5, got $status"
assert_contains "$err" "no active graphical session"

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
printf '%s' "$json" |
    jq -e '.schema == 2 and .ok == true and .data.network == {"state":"connected","wifi":"enabled"} and .data.audio == {"volume":0.4,"muted":false} and .data.shell.state == "running"' >/dev/null ||
    fail "status JSON schema 2 is invalid: $json"

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

profile="$tmp/profiles/system"
mkdir -p "$tmp/profiles/system-3-link" "$tmp/profiles/system-4-link" "$tmp/profiles/system-5-link/bin"
ln -sfn system-5-link "$profile"
cat >"$tmp/profiles/system-5-link/bin/switch-to-configuration" <<EOF
#!$BASH
printf '%s:%s\n' "switch-to-configuration" "\$*" >>"\$TEST_LOG"
EOF
chmod +x "$tmp/profiles/system-5-link/bin/switch-to-configuration"

(
    # shellcheck source=/dev/null
    . "$ojuny_lib/args.sh"
    # shellcheck source=/dev/null
    . "$ojuny_lib/common.sh"
    # shellcheck source=/dev/null
    . "$ojuny_lib/nix.sh"
    OJUNY_VERBOSE=0 OJUNY_DRY_RUN=0
    nixos_rollback "/flake" "host"
    OJUNY_SYSTEM_PROFILE="$profile" nixos_rollback "/flake" "host" 42
)
rollback_log="$(cat "$TEST_LOG")"
assert_contains "$rollback_log" "nixos-rebuild:switch --rollback --flake /flake#host"
assert_contains "$rollback_log" "nix-env:--switch-generation 42 -p $profile"
assert_contains "$rollback_log" "switch-to-configuration:switch"

generations="$(
    # shellcheck source=/dev/null
    . "$ojuny_lib/args.sh"
    # shellcheck source=/dev/null
    . "$ojuny_lib/common.sh"
    # shellcheck source=/dev/null
    . "$ojuny_lib/nix.sh"
    printf 'current:%s\n' "$(OJUNY_SYSTEM_PROFILE="$profile" nixos_generation_current)"
    printf 'back:%s\n' "$(OJUNY_SYSTEM_PROFILE="$profile" nixos_generation_back 2)"
    printf 'booted:%s\n' "$(OJUNY_SYSTEM_PROFILE="$profile" OJUNY_BOOTED_SYSTEM="$tmp/profiles/system-4-link" nixos_generation_booted)"
)"
assert_contains "$generations" "current:5"
assert_contains "$generations" "back:3"
assert_contains "$generations" "booted:4"

printf 'all tests passed\n'
