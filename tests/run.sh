#!/usr/bin/env bash
set -euo pipefail

: "${OJUNY_BIN:?OJUNY_BIN is not set}"
: "${OJUNY_PATCHES_BIN:?OJUNY_PATCHES_BIN is not set}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home"
export XDG_CONFIG_HOME="$tmp/config"
export XDG_CACHE_HOME="$tmp/cache"
export XDG_RUNTIME_DIR="$tmp/runtime"
export TEST_LOG="$tmp/backends.log"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR" "$tmp/bin"

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
    udisksctl systemctl loginctl journalctl sbctl upower wtype ydotool nom \
    nix-settings-gui ojuny-screenshot-menu ojuny-capture-text ojuny-capture-qr \
    ojuny-screenshot-edit socat; do
    write_fake "$name"
done

cat >"$tmp/bin/ojuny-login-splash" <<EOF
#!$BASH
printf '%s:%s\n' "ojuny-login-splash" "\$*" >>"\$TEST_LOG"
case "\$1" in
--seconds)
    mkdir -p "\$XDG_RUNTIME_DIR/ojuny-login-splash"
    : >"\$XDG_RUNTIME_DIR/ojuny-login-splash/\$\$.sock"
    ;;
--quit)
    rm -f "\$XDG_RUNTIME_DIR/ojuny-login-splash/"*.sock
    ;;
esac
EOF
chmod +x "$tmp/bin/ojuny-login-splash"

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

write_fake nix-env

cat >"$tmp/bin/nixos-rebuild" <<EOF
#!$BASH
printf '%s:%s\n' "nixos-rebuild" "\$*" >>"\$TEST_LOG"
[ -z "\${FAIL_REBUILD:-}" ] || exit 1
EOF
chmod +x "$tmp/bin/nixos-rebuild"

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

# A stuck shell backend must not hang the status or support bundle.
cp "$tmp/bin/dms" "$tmp/bin/dms.real"
cat >"$tmp/bin/dms" <<EOF
#!$BASH
sleep 30
EOF
chmod +x "$tmp/bin/dms"
start=$SECONDS
status=0
details_status=0
timeout 10 "$OJUNY_BIN" status >/dev/null 2>&1 || status=$?
timeout 10 "$OJUNY_BIN" print-system-details >/dev/null 2>&1 || details_status=$?
elapsed=$((SECONDS - start))
mv "$tmp/bin/dms.real" "$tmp/bin/dms"
[ "$elapsed" -lt 12 ] || fail "status waited ${elapsed}s on a stuck dms"
[ "$status" -ne 124 ] || fail "status hit the test timeout on a stuck dms"
[ "$details_status" -ne 124 ] || fail "print-system-details hit the test timeout on a stuck dms"

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
tool_path="$(dirname "$(command -v mktemp)"):$(dirname "$(command -v jq)"):$(dirname "$(command -v grep)"):$(dirname "$(command -v sed)"):$(dirname "$(command -v awk)"):$(dirname "$(command -v mkdir)"):$(dirname "$(command -v tee)")"
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

mkdir -p "$tmp/bin-empty"
cat >"$tmp/bin-empty/coredumpctl" <<EOF
#!$BASH
case "\$*" in
    "list --json=short --no-pager") printf '%s\n' '[]' ;;
    "info --no-pager"*) exit 1 ;;
esac
EOF
chmod +x "$tmp/bin-empty/coredumpctl"

captured_state="$tmp/captured-state"
mkdir -p "$captured_state/ojuny/crashes"
printf 'ojuny crash\n  command: demo\n' >"$captured_state/ojuny/crashes/20261127T000000Z-1.log"
captured_out="$(PATH="$tmp/bin-empty:$PATH" XDG_STATE_HOME="$captured_state" ojuny_cli crashes)"
assert_contains "$captured_out" "CAPTURED FAILURES"
assert_contains "$captured_out" "demo"

raven_state="$tmp/raven-state"
mkdir -p "$raven_state/ojuny/raven"
printf 'Native process exited with status 4294967295\nExit status: 255\n' \
    >"$raven_state/ojuny/raven/20261127-001042-failure.log"
raven_out="$(PATH="$tmp/bin-empty:$PATH" XDG_STATE_HOME="$raven_state" ojuny_cli crashes 2>&1)"
assert_contains "$raven_out" "COREDUMPS"
assert_contains "$raven_out" "CAPTURED FAILURES"
assert_contains "$raven_out" "RAVEN FAILURES"
assert_contains "$raven_out" "20261127-001042-failure.log"
assert_contains "$raven_out" "hint: a session freeze is a hang"
assert_contains "$(PATH="$tmp/bin-empty:$PATH" XDG_STATE_HOME="$raven_state" ojuny_cli crashes latest)" \
    "Native process exited with status 4294967295"
assert_contains "$(PATH="$tmp/bin-empty:$PATH" XDG_STATE_HOME="$raven_state" ojuny_cli crashes R1)" \
    "Exit status: 255"
raven_json="$(PATH="$tmp/bin-empty:$PATH" XDG_STATE_HOME="$raven_state" ojuny_cli --json crashes)"
printf '%s' "$raven_json" | jq -e '(.data.raven | length) == 1 and (.data.coredumps | length) == 0' >/dev/null ||
    fail "crashes JSON does not separate Raven failures from coredumps: $raven_json"

ojuny_cli debug on
ojuny_cli --dry-run wifi connect mynet supersecret >/dev/null 2>&1
assert_contains "$(ojuny_cli debug tail)" "[redacted]"
if ojuny_cli debug tail | grep -q 'supersecret'; then
    fail "debug log leaked a password"
fi
ojuny_cli debug off

mkdir -p "$tmp/flake/modules/07-system"
printf '{ outputs = _: { }; }\n' >"$tmp/flake/flake.nix"
printf '/* @menu displayname = "Secure Boot"; */\n{ ... }: { }\n' >"$tmp/flake/modules/07-system/00-secureboot.nix"
printf '/* @menu displayname = "Networking and VPN"; */\n{ ... }: { }\n' >"$tmp/flake/modules/07-system/02-networking.nix"
printf '/* @menu icon = "x"; */\n{ ... }: { }\n' >"$tmp/flake/modules/07-system/00-noname.nix"

list="$(OJUNY_FLAKE="$tmp/flake" ojuny_cli raw-settings --list)"
assert_contains "$list" "PAGE"
assert_contains "$list" "FILE"
assert_contains "$list" "Secure Boot"
assert_contains "$list" "Networking and VPN"
assert_contains "$list" "00-secureboot.nix"
if printf '%s\n' "$list" | grep -q $'\t'; then
    fail "raw-settings --list still uses tabs"
fi
printf '%s\n' "$list" | awk 'NR > 1 { print index($0, $NF) }' | sort -u |
    awk 'END { exit (NR == 1 ? 0 : 1) }' ||
    fail "raw-settings --list file column is not aligned"

status=0
out="$(OJUNY_FLAKE="$tmp/flake" ojuny_cli raw-settings 2>&1)" || status=$?
[ "$status" -eq 2 ] || fail "raw-settings without a page should exit 2, got $status"
assert_contains "$out" "usage: ojuny raw-settings [--list|<page>]"
assert_contains "$out" "PAGE"
assert_contains "$out" "Secure Boot"

status=0
out="$(OJUNY_FLAKE="$tmp/flake" ojuny_cli raw-settings nope 2>&1)" || status=$?
[ "$status" -eq 5 ] || fail "an unknown raw-settings page should exit 5, got $status"
assert_contains "$out" "no settings page matches: nope"
assert_contains "$out" "PAGE"
assert_contains "$out" "Networking and VPN"

assert_contains "$(OJUNY_FLAKE="$tmp/flake" ojuny_cli --dry-run raw-settings secureboot 2>&1)" "00-secureboot.nix"
assert_contains "$(OJUNY_FLAKE="$tmp/flake" ojuny_cli --dry-run raw-settings secure-boot 2>&1)" "00-secureboot.nix"
assert_contains "$(OJUNY_FLAKE="$tmp/flake" ojuny_cli --dry-run raw-settings secure_boot 2>&1)" "00-secureboot.nix"
assert_contains "$(OJUNY_FLAKE="$tmp/flake" ojuny_cli --dry-run raw-settings "secure boot" 2>&1)" "00-secureboot.nix"
assert_contains "$(OJUNY_FLAKE="$tmp/flake" ojuny_cli --dry-run raw-settings 00-noname 2>&1)" "00-noname.nix"

pages_json="$(OJUNY_FLAKE="$tmp/flake" ojuny_cli --json raw-settings --list)"
printf '%s' "$pages_json" | jq -e '.data.pages | map(.page) | index("Secure Boot") != null' >/dev/null ||
    fail "raw-settings --list JSON has no page array"
if OJUNY_FLAKE="$tmp/flake" ojuny_cli __complete raw-settings | grep -qx 'PAGE'; then
    fail "raw-settings completion includes the table header"
fi

mkdir -p "$tmp/validation-state"
status=0
XDG_STATE_HOME="$tmp/validation-state" OJUNY_FLAKE="$tmp/flake" \
    ojuny_cli raw-settings nope >/dev/null 2>&1 || status=$?
[ "$status" -eq 5 ] || fail "raw-settings nope should exit 5, got $status"
if [ -d "$tmp/validation-state/ojuny/crashes" ] &&
    find "$tmp/validation-state/ojuny/crashes" -type f -name '*.log' -print -quit | grep -q .; then
    fail "a validation failure was recorded as a crash"
fi

assert_contains "$(ojuny_cli --dry-run build nixpkgs#hello 2>&1)" "nom build nixpkgs#hello"
assert_contains "$(ojuny_cli --dry-run build hello 2>&1)" "nom build nixpkgs#hello"
assert_contains "$(ojuny_cli --dry-run build ojuny-cli 2>&1)" "nom build github:ojuny-project/ojuny-cli#ojuny-cli"
assert_contains "$(ojuny_cli --dry-run build owner/repo 2>&1)" "nom build github:owner/repo"
assert_contains "$(ojuny_cli --dry-run build github:owner/repo#pkg 2>&1)" "nom build github:owner/repo#pkg"
assert_contains "$(ojuny_cli --dry-run build nixpkgs#hello -- --print-build-logs 2>&1)" "--print-build-logs"
assert_contains "$(ojuny_cli --dry-run shell zsh fzf ncdu 2>&1)" "nom shell nixpkgs#zsh nixpkgs#fzf nixpkgs#ncdu"
assert_contains "$(ojuny_cli --dry-run develop --command true 2>&1)" "nom develop --command true"

assert_contains "$(OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host ojuny_cli --dry-run rebuild 2>&1)" "nixos-rebuild switch --flake $tmp/flake#host |& nom"
assert_contains "$(OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host ojuny_cli --dry-run rebuild boot 2>&1)" "nixos-rebuild boot --flake $tmp/flake#host |& nom"

: >"$TEST_LOG"
output="$(OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host \
    OJUNY_ENVIRONMENT_RELOAD='printf "reload\n" >> "$TEST_LOG"' \
    OJUNY_REBUILD_HOLD=1 \
    OJUNY_REBUILD_HOLD_COMMAND='printf "hold\n" | tee -a "$TEST_LOG"' \
    ojuny_cli rebuild 2>&1)"
rebuild_line="$(grep -n '^nixos-rebuild:' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
stop_login_line="$(grep -n '^systemctl:--user stop ojuny-login-splash' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
start_line="$(grep -n '^ojuny-login-splash:--seconds' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
reload_line="$(grep -n '^reload$' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
quit_line="$(grep -n '^ojuny-login-splash:--quit' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
hold_line="$(grep -n '^hold$' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
[ -n "$rebuild_line" ] && [ -n "$stop_login_line" ] && [ -n "$start_line" ] &&
    [ -n "$reload_line" ] && [ -n "$quit_line" ] && [ -n "$hold_line" ] ||
    fail "rebuild, login stop, splash start, reload, splash quit and hold did not all run"
[ "$rebuild_line" -lt "$stop_login_line" ] || fail "the login splash was stopped before activation"
[ "$stop_login_line" -lt "$start_line" ] || fail "the login splash was stopped after the rebuild splash started"
[ "$start_line" -lt "$reload_line" ] || fail "the splash started after the environment reload"
[ "$reload_line" -lt "$quit_line" ] || fail "splash quit before the environment reload"
[ "$quit_line" -lt "$hold_line" ] || fail "the hold ran before the splash quit"
result_line="$(printf '%s\n' "$output" | grep -n 'result: ok' | cut -d: -f1 | sed -n '1p')"
hold_output_line="$(printf '%s\n' "$output" | grep -n '^hold$' | cut -d: -f1 | sed -n '1p')"
[ -n "$result_line" ] && [ -n "$hold_output_line" ] &&
    [ "$result_line" -lt "$hold_output_line" ] ||
    fail "the hold ran before the rebuild result was printed"

: >"$TEST_LOG"
status=0
output="$(FAIL_REBUILD=1 OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host \
    OJUNY_REBUILD_HOLD=1 \
    OJUNY_REBUILD_HOLD_COMMAND='printf "hold\n" | tee -a "$TEST_LOG"' \
    ojuny_cli rebuild 2>&1)" || status=$?
[ "$status" -ne 0 ] || fail "a failed rebuild should not exit 0"
assert_contains "$output" "result: failed"
assert_contains "$output" "hold"
[ -n "$(grep '^hold$' "$TEST_LOG" || true)" ] || fail "a failed rebuild did not hold the terminal"
if grep -q '^ojuny-login-splash:' "$TEST_LOG"; then
    fail "the splash ran on a failed rebuild"
fi

: >"$TEST_LOG"
status=0
output="$(OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host \
    OJUNY_ENVIRONMENT_RELOAD='exit 7' \
    OJUNY_REBUILD_HOLD=1 \
    OJUNY_REBUILD_HOLD_COMMAND='printf "hold\n" | tee -a "$TEST_LOG"' \
    ojuny_cli rebuild 2>&1)" || status=$?
[ "$status" -eq 7 ] || fail "a failed environment reload should keep exit 7, got $status"
assert_contains "$output" "result: failed"
start_line="$(grep -n '^ojuny-login-splash:--seconds' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
quit_line="$(grep -n '^ojuny-login-splash:--quit' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
hold_line="$(grep -n '^hold$' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
[ -n "$start_line" ] && [ -n "$quit_line" ] && [ -n "$hold_line" ] ||
    fail "a failed reload did not start, stop and hold"
[ "$start_line" -lt "$quit_line" ] && [ "$quit_line" -lt "$hold_line" ] ||
    fail "a failed reload ran the splash stop and hold out of order"

: >"$TEST_LOG"
OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host \
    OJUNY_ENVIRONMENT_RELOAD='printf "reload\n" >> "$TEST_LOG"; true # dms' \
    ojuny_cli rebuild >/dev/null
reload_line="$(grep -n '^reload$' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
dms_line="$(grep -n '^dms:version' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
quit_line="$(grep -n '^ojuny-login-splash:--quit' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
[ -n "$reload_line" ] && [ -n "$dms_line" ] && [ -n "$quit_line" ] ||
    fail "the DMS readiness wait did not run"
[ "$reload_line" -lt "$dms_line" ] && [ "$dms_line" -lt "$quit_line" ] ||
    fail "the splash quit before DMS was ready"

mkdir -p "$XDG_RUNTIME_DIR/ojuny-login-splash"
: >"$XDG_RUNTIME_DIR/ojuny-login-splash/login.sock"
: >"$TEST_LOG"
OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host ojuny_cli rebuild >/dev/null
stop_login_line="$(grep -n '^systemctl:--user stop ojuny-login-splash' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
start_line="$(grep -n '^ojuny-login-splash:--seconds' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
quit_line="$(grep -n '^ojuny-login-splash:--quit' "$TEST_LOG" | cut -d: -f1 | sed -n '1p')"
[ -n "$stop_login_line" ] && [ -n "$start_line" ] && [ -n "$quit_line" ] ||
    fail "a running login splash was not stopped"
[ "$stop_login_line" -lt "$start_line" ] && [ "$quit_line" -lt "$start_line" ] ||
    fail "the login splash stop ran after the rebuild splash started"

mkdir -p "$tmp/bin-slow"
cat >"$tmp/bin-slow/ojuny-login-splash" <<EOF
#!$BASH
printf '%s:%s\n' "ojuny-login-splash" "\$*" >>"\$TEST_LOG"
case "\$1" in
--seconds)
    mkdir -p "\$XDG_RUNTIME_DIR/ojuny-login-splash"
    : >"\$XDG_RUNTIME_DIR/ojuny-login-splash/\$\$.sock"
    ;;
--quit)
    sleep 30
    ;;
esac
EOF
chmod +x "$tmp/bin-slow/ojuny-login-splash"
rm -f "$XDG_RUNTIME_DIR/ojuny-login-splash/"*.sock
: >"$TEST_LOG"
start=$SECONDS
PATH="$tmp/bin-slow:$PATH" OJUNY_FLAKE="$tmp/flake" OJUNY_HOST=host \
    OJUNY_SPLASH_QUIT_TIMEOUT=1 ojuny_cli rebuild >/dev/null 2>&1 || status=$?
elapsed=$((SECONDS - start))
[ "$elapsed" -lt 8 ] || fail "a stuck splash quit blocked the rebuild for ${elapsed}s"
rm -f "$XDG_RUNTIME_DIR/ojuny-login-splash/"*.sock

assert_contains "$("$OJUNY_PATCHES_BIN" --help)" "Usage: ojuny-patches"
assert_contains "$("$OJUNY_PATCHES_BIN" --version)" "ojuny-patches"
assert_contains "$("$OJUNY_PATCHES_BIN" repo list)" "https://github.com/ojuny-project/ojuny-patches"

flake="$tmp/flake"
registry="$tmp/registry"
mkdir -p "$flake/modules/patches" "$registry/modules/patches"
mkdir -p "$registry/patch-base" "$registry/patch-demo" "$registry/patch-cycle-a" "$registry/patch-cycle-b" "$registry/patch-zed" "$registry/patch-zed-extra"

printf '{ ... }: { flake.modules.nixos.patch-base = { }: { }; }\n' >"$registry/modules/patches/patch-base.nix"
printf 'name: Base\nid: patch-base\ndescription: Base patch\nversion: 1\n' >"$registry/patch-base/metadata.md"

printf '{ ... }: { flake.modules.nixos.patch-demo = { }: { }; }\n' >"$registry/modules/patches/patch-demo.nix"
printf 'name: Demo\nid: patch-demo\ndescription: Demo patch\ndependencies: patch-base\nversion: 1\n' >"$registry/patch-demo/metadata.md"

printf '{ ... }: { flake.modules.nixos.patch-zed = { }: { }; }\n' >"$registry/modules/patches/patch-zed.nix"
printf 'name: Zed\nid: patch-zed\ndescription: Zed patch\nversion: 1\n' >"$registry/patch-zed/metadata.md"

printf '{ ... }: { flake.modules.nixos.patch-zed-extra = { }: { }; }\n' >"$registry/modules/patches/patch-zed-extra.nix"
printf 'name: Zed Extra\nid: patch-zed-extra\ndescription: Zed extra patch\nversion: 1\n' >"$registry/patch-zed-extra/metadata.md"

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

available="$("$OJUNY_PATCHES_BIN" list available)"
assert_contains "$available" "ID"
assert_contains "$available" "NAME"
assert_contains "$available" "SOURCE"
assert_contains "$available" "patch-demo"
case "$available" in
*$'\t'*) fail "list available still prints tabs" ;;
esac
printf '%s\n' "$available" |
    awk 'NR == 1 { header = index($0, "NAME") } /^patch-demo/ { row = index($0, "Demo") } END { exit !(header && header == row) }' ||
    fail "list available columns are not aligned"

"$OJUNY_PATCHES_BIN" install demo >/dev/null
[ -f "$flake/modules/patches/patch-base.nix" ] || fail "base dependency was not installed"
[ -f "$flake/modules/patches/patch-demo.nix" ] || fail "demo patch was not installed"

installed="$("$OJUNY_PATCHES_BIN" list installed)"
assert_contains "$installed" "STATUS"
assert_contains "$installed" "patch-demo"
case "$installed" in
*$'\t'*) fail "list installed still prints tabs" ;;
esac
printf '%s\n' "$installed" |
    awk 'NR == 1 { header = index($0, "NAME") } /^patch-demo/ { row = index($0, "Demo") } END { exit !(header && header == row) }' ||
    fail "list installed columns are not aligned"

assert_contains "$("$OJUNY_PATCHES_BIN" info patch-demo)" "dependencies: patch-base"
assert_contains "$("$OJUNY_PATCHES_BIN" info zed)" "id: patch-zed"

"$OJUNY_PATCHES_BIN" install ZED >/dev/null
[ -f "$flake/modules/patches/patch-zed.nix" ] || fail "the prefixless uppercase install failed"
"$OJUNY_PATCHES_BIN" install '^patch-zed-extra$' >/dev/null
[ -f "$flake/modules/patches/patch-zed-extra.nix" ] || fail "the anchored regex install failed"
assert_status 6 "$OJUNY_PATCHES_BIN" install 'zed.*'
assert_status 6 "$OJUNY_PATCHES_BIN" install '^patch-ze'
[ ! -f "$flake/modules/patches/patch-zed-bad.nix" ] || fail "an ambiguous pattern installed a patch"
assert_status 5 "$OJUNY_PATCHES_BIN" install 'no-such-patch'
assert_status 5 "$OJUNY_PATCHES_BIN" install '['
"$OJUNY_PATCHES_BIN" --yes remove zed-extra >/dev/null
[ ! -f "$flake/modules/patches/patch-zed-extra.nix" ] || fail "the prefixless remove failed"
"$OJUNY_PATCHES_BIN" --yes reinstall zed >/dev/null
[ -f "$flake/modules/patches/patch-zed.nix" ] || fail "the prefixless reinstall failed"
assert_status 6 "$OJUNY_PATCHES_BIN" install 'demo|zed'

assert_status 6 "$OJUNY_PATCHES_BIN" install patch-cycle-a
[ ! -f "$flake/modules/patches/patch-cycle-a.nix" ] || fail "cycle patch was installed"
"$OJUNY_PATCHES_BIN" --yes remove demo >/dev/null
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
