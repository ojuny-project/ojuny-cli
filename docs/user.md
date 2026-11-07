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
switch and the patch modules found in the flake.

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

## JSON

Every command accepts `--json`:

```sh
ojuny status --json | jq .data.battery
ojuny commands --json | jq '.data.commands[] | .path'
```

The success envelope is `{"schema":1,"command":"...","ok":true,"data":{}}`.
The failure envelope carries `error.code`, `error.message`, and `error.hint`.

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
