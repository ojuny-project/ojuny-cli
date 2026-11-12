# ojuny user guide

`ojuny` is a thin wrapper. It does not store configuration and does not edit
Nix files. It translates a command into the backend tool that already owns the
feature.

## Persistence

Most commands are runtime only. A reload or rebuild may discard the change.

Persistent values belong in nix-settings-gui:

```sh
ojuny settings
ojuny settings display
ojuny settings bar
```

`ojuny raw-settings display` opens the module that declares the matching
`@menu` in `$VISUAL`, `$EDITOR`, or `nano`. It opens the first match only.

## Defaults

A bare category runs its safe default:

```sh
ojuny dux          # status
ojuny keybinds     # open the viewer
ojuny vpn          # VPN status
ojuny settings     # open nix-settings-gui
```

## Flake commands

```sh
ojuny flake status
ojuny flake update nixpkgs
ojuny flake validate
ojuny flake build
sudo ojuny flake activate --boot
sudo ojuny flake activate --now
```

`flake update` requires at least one input. `flake activate` requires root and
prints a sudo hint when run unprivileged.

Flake commands print a context block with the flake path, host, Git revision,
Nix version, input revisions, and result. `validate` also prints the patch
switch and the patch modules found in the flake. `validate` does not build.

`flake rollback` passes the configured flake and host to `nixos-rebuild` for
the previous generation. An explicit generation is activated from the system
profile with `nix-env` and `switch-to-configuration`. Without an argument it
prompts for one of three targets: the previous generation, the booted
generation, or a number of generations back. Pass a generation number to skip
the prompt:

```sh
sudo ojuny flake rollback
sudo ojuny flake rollback 5
```

## Services and logs

```sh
ojuny service list
ojuny service status NetworkManager
sudo ojuny service restart NetworkManager
ojuny logs NetworkManager --since "10 min ago"
```

`service` and `logs` use `systemctl --user` and `journalctl --user` unless the
process runs as root. The CLI never calls `sudo`. Use `--system` to target the
system scope for read-only checks.

## Lock and screensaver

```sh
ojuny system lock
ojuny toggle lockscreen
ojuny toggle screensaver
```

`system lock` and `toggle lockscreen` call `loginctl lock-session` for the
active graphical session, so they also work from SSH. Without an active
graphical session they exit 5 with a hint. The screensaver is a separate
command; the Dux lock screen starts its screensaver while locked.

## JSON

Every command accepts `--json`:

```sh
ojuny status --json | jq .data.battery
ojuny commands --json | jq '.data.commands[] | .path'
```

Most commands use the success envelope
`{"schema":1,"command":"...","ok":true,"data":{}}`. The failure envelope carries
`error.code`, `error.message`, and `error.hint`.

`ojuny status --json` uses schema 2. The plaintext summary keeps the same
fields and layout; only the JSON data is structured:

```json
{
  "schema": 2,
  "command": "status",
  "ok": true,
  "data": {
    "network": {"state": "connected", "wifi": "enabled"},
    "audio": {"volume": 0.4, "muted": false},
    "shell": {"state": "running", "version": "dms 1.0.0"}
  }
}
```

`network.state` comes from `nmcli general`, `audio.volume` is the sink volume
between 0 and 1, and `audio.muted` is a boolean. When the Dux session is not on
`PATH`, `shell` is `{"state":"unavailable","reason":"dms not on PATH"}`.
`audio.volume` and `audio.muted` are `null` when no sink is available.

## Failures

A backend failure exits 4. When a handler fails without printing anything to
stdout, the CLI prints `ojuny: <command> failed (exit N)` to stderr, so a
failure is never silent. Usage, dependency, validation, and conflict errors keep
their documented codes.

## Session-only commands

`dms` and `mmsg` are installed by the Mango and Dux session, not by
`ojuny-cli`. They are not on the login or SSH `PATH`. Commands that need them
exit 3 with:

```
ojuny: missing required command: dms
  hint: dms is provided by the desktop session; run this from the Mango session or add its bin directory to PATH
```

`ojuny doctor` reports the session and labels missing `dms`/`mmsg` as
`missing (no graphical session)`.

## Keybinds

```sh
ojuny keybinds show binds
ojuny keybinds count binds
```

`show` prints the raw provider list. `count` prints the number of binds per
category and the total. The `SUPER+K` cheatsheet is a grouped view: it merges
rows with the same label and action and collapses consecutive numeric keys such
as `SUPER+1` through `SUPER+9` into one row. Its row count is therefore lower
than the provider count, and `count` is the authoritative total.

## Discovery

```sh
ojuny help
ojuny help wifi
ojuny help wifi connect
ojuny commands
ojuny print-agent-details
ojuny doctor
```

`print-agent-details` prints the layout, rules, JSON contract, and command map
for an agent.

## Path resolution

The flake path is resolved in this order:

1. `--flake`
2. `OJUNY_FLAKE`
3. `flake_path` in `~/.config/nix-settings-gui/config.json`
4. The current Git root, if it contains `flake.nix`

The host is resolved from `--host`, the only configured host, or the current
hostname.

## Diagnostics and IPC

```sh
ojuny print-system-details
ojuny crashes
ojuny crashes latest
ojuny debug on
ojuny ipc status
ojuny ipc call status
```

`print-system-details` is plaintext by default and includes the current DE/WM.
`crashes` is system-wide through `coredumpctl`. `ipc` exposes a local Unix
socket at `$XDG_RUNTIME_DIR/ojuny/ipc.sock` with newline-delimited JSON.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 2 | Usage error |
| 3 | Missing dependency |
| 4 | Backend failure |
| 5 | Validation failure |
| 6 | Conflict |

## Diagnostics

```sh
ojuny doctor
ojuny doctor crashes
ojuny doctor boot
```

`doctor` checks the flake, host, patch state, and the expected backend tools.
