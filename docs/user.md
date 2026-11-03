# ojuny user guide

`ojuny` is a thin wrapper. It does not store configuration and does not edit
Nix files. It translates a command into the backend tool that already owns the
feature.

## Persistence

Most commands are runtime only. A reload or rebuild may discard the change.

Use the settings GUI for persistent values:

```sh
ojuny settings open displays
ojuny settings open bar
ojuny settings open network
```

## Flake commands

```sh
ojuny flake update <input>
ojuny flake validate
ojuny flake build
ojuny flake activate-boot
ojuny flake activate-now
```

Flake commands print a context block with the flake path, host, Git revision,
Nix version, input revisions, and result. `validate` also prints the patch
switch and the patch modules found in the flake.

## Discovery

The flake path is resolved in this order:

1. `--flake`
2. `OJUNY_FLAKE`
3. `flake_path` in `~/.config/nix-settings-gui/config.json`
4. The current Git root, if it contains `flake.nix`

The host is resolved from `--host`, the only configured host, or the current
hostname.

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
```

`doctor` checks the flake, host, patch state, and the expected backend tools.
