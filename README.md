# ojuny-cli

Status: core surface redesigned, not yet tested on a live session. The install,
build, and runtime paths in this README have not been run for this revision.

## Purpose

`ojuny-cli` builds two command line programs for a NixOS desktop running Dux
Modular Shell and MangoWM. `ojuny` is the single command for imperative
management and status: network, Wi-Fi, modem, Bluetooth, VPN, audio, media,
display, storage, services, Secure Boot, Nix, DMS, Mango, screenshots,
notifications, and synthetic input. `ojuny-patches` manages git repositories
that contain optional Nix modules called patches.

`ojuny` is a wrapper. It does not store configuration and does not edit Nix
files. Persistent values are changed through `ojuny settings` (nix-settings-gui)
or `ojuny raw-settings` (the module behind a settings page).

## Status

Both programs are version 0.1.0 and no tagged release exists. The flake checks
build each program, run the test script, verify the man page, and verify the
installed completion files.

The core `ojuny` surface is implemented. Optional patch stacks such as flatpak,
docker, libvirt, and development are out of scope and are not part of the core
command set.

## Requirements

- Linux.
- Nix with flakes enabled, to install from the flake.
- A running Dux Modular Shell session for `bar`, `dock`, `dashboard`, `island`,
  `spotlight`, `toggle`, `clipboard`, `notepad`, `keybinds`, `settings`, and
  `capture` commands. `dms` and `mmsg` come from that session and are not on
  the login or SSH `PATH`; commands that need them exit 3 with a session hint.
- NixOS for `ojuny flake` and `ojuny secureboot`.
- `git` for `ojuny-patches`.
- NetworkManager, ModemManager, BlueZ, PipeWire/WirePlumber, playerctl,
  udisks2, upower, systemd, sbctl, wtype, and ydotool for their categories.
- `nix-settings-gui` on `PATH` for `ojuny settings`.
- The ojuny screenshot helpers (`ojuny-screenshot-menu`, `ojuny-screenshot-edit`,
  `ojuny-capture-text`, `ojuny-capture-qr`, `ojuny-capture-scroll`) on `PATH`
  for the matching `ojuny capture` commands.
- Power and session commands call `systemctl` and `loginctl`, so polkit may ask
  for authentication.
- Disk and memory use: not measured.

## Install

Install both packages into your Nix profile:

```console
$ nix profile install github:ojuny-project/ojuny-cli#ojuny-cli
$ nix profile install github:ojuny-project/ojuny-cli#ojuny-patches-cli
```

Check the version and the manual:

```console
$ ojuny --version
ojuny 0.1.0
$ man ojuny
```

The package installs completion for bash, zsh, and fish. The completion scripts
are regenerated from the command table at build time.

## Usage

```console
$ ojuny status
$ ojuny wifi list
$ ojuny vpn up work
$ ojuny settings displays
```

Every command accepts `--help` and `--json`. A bare category runs its default,
for example `ojuny dux` prints status, `ojuny keybinds` opens the viewer, and
`ojuny vpn` prints VPN status.

See `docs/cli-reference.md` for the generated category and command list. The man
page carries the same surface.

## Settings

`ojuny settings` opens nix-settings-gui. `ojuny settings displays` opens the
Displays page. The page argument is a regular expression.

`ojuny raw-settings displays` finds the first module that declares the matching
`@menu` and opens it in `$VISUAL`, then `$EDITOR`, then `nano`. It never opens
more than one file.

Persistent values belong in nix-settings-gui. The CLI does not write Nix files.

## Services and logs

`ojuny service` and `ojuny logs` use `systemctl --user` and `journalctl --user`
unless the process runs as root. The CLI never calls `sudo`.

To control system services, prefix the command:

```console
$ sudo ojuny service restart NetworkManager
```

The same rule applies to `ojuny secureboot` mutations and
`ojuny flake activate`.

## Configuration and state

The flake path is resolved from `--flake`, then `OJUNY_FLAKE`, then
`~/.config/nix-settings-gui/config.json`, then the current Git root.

`ojuny vpn import` copies a `.conf` profile to the WireGuard watch directory:
`--dir`, then `OJUNY_WIREGUARD_DIR`, then
`ojuny.vpn.wireguard.directory`, then `~/.config/ojuny/wireguard`.
NetworkManager imports the profile from there.

`ojuny-patches` stores its repository list and settings under
`$XDG_CONFIG_HOME/ojuny/` and its clones under `$XDG_CACHE_HOME/ojuny/patches`.

## Output

Human output uses aligned tables and color on a TTY. `NO_COLOR` and
`CLICOLOR=0` disable color. `--json` emits one document on stdout with a stable
envelope. `--quiet` prints only the primary value. `--verbose` prints the
resolved backend argv to stderr. `--dry-run` prints the argv and does not run.

Exit codes: 0 success, 2 usage, 3 missing dependency, 4 backend failure,
5 validation failure, 6 conflict. A backend failure exits 4 and always prints
`ojuny: <command> failed (exit N)` to stderr when the handler printed no output.

`ojuny status --json` uses schema 2: `data.network`, `data.audio`, and
`data.shell` are objects. The plaintext status keeps the same fields.
`ojuny keybinds count` reports the full bind total; the cheatsheet is a grouped
view.

## Diagnostics and IPC

`ojuny print-system-details` prints a plaintext support bundle with the flake,
host, kernel, hardware, DE/WM, session, backend versions, patch state, paths,
debug tail, failed units, and a short journal tail. `ojuny crashes` lists
system-wide coredumps from `coredumpctl`; `ojuny crashes latest` prints the
newest entry and `ojuny crashes <entry>` prints plaintext details.

`ojuny debug on|off|status|tail|clear` controls debug logging under
`$XDG_STATE_HOME/ojuny/debug.log`. Secrets are redacted.

`ojuny ipc` exposes a local Unix socket at
`$XDG_RUNTIME_DIR/ojuny/ipc.sock` with newline-delimited JSON. `ojuny ipc call`
runs one method, `ojuny ipc watch` streams topic events, and `ojuny ipc serve`
runs the `socat` listener. The package installs
`share/systemd/user/ojuny-ipc.service`; enable it with
`systemctl --user enable --now ojuny-ipc.service`.

## Limits

`ojuny` is a wrapper around the tools that own each feature. It does not
implement its own network, audio, Bluetooth, or display stack.

`ojuny flake activate`, `ojuny flake gc`, `ojuny flake rollback`, and
`ojuny secureboot` mutations require root. The CLI prints a sudo hint instead
of escalating.

`ojuny flake rollback` passes `--flake <path>#<host>` for the previous
generation and activates an explicit generation from the system profile.
Without a generation argument it prompts for the previous generation, the
booted generation, or a number of generations back. `ojuny system lock` and
`ojuny toggle lockscreen` lock the active graphical session through
`loginctl lock-session`, including from SSH; `ojuny toggle screensaver` is a
separate command for the lock-screen screensaver.

`ojuny` does not manage flatpak, docker, container, or virtualisation state.
Those belong to optional patches and stay outside the core surface.

`ojuny` does not manage DMS plugins. Plugin management is declarative. Hardware
support is `nixos-hardware`-driven and has no imperative CLI backend.

`ojuny-patches install` copies one module into the local flake. It does not
enable the patch or rebuild the system; enable the patch in the settings GUI
after installation. Dependencies are checked by file presence and are not
versioned. A dependency cycle exits 6 and a missing dependency exits 5.

Patches are Nix code evaluated with the privileges of the system
configuration. Add only repositories you trust.

## Documentation

- [`docs/cli-reference.md`](docs/cli-reference.md): generated command list.
- `man ojuny`: the full category and command surface.
- `man ojuny-patches`: patch installation, repository layout, and metadata.
- `docs/user.md`: flake path discovery, exit codes, and `ojuny doctor`.
- `docs/patches.md`: the patch lifecycle, repository list, and security notes.

## Contributing

Report bugs at <https://github.com/ojuny-project/ojuny-cli/issues>. A change must
update the command table, regenerate the reference, update the man page, add or
adjust a case in `tests/run.sh`, and pass `nix flake check`. Do not include
generated files from `result-cli` or `result-patches`.

## License

GNU General Public License, version 3 or later. See `LICENSE`. mmsg, Dux Modular
Shell, NetworkManager, BlueZ, PipeWire, playerctl, WireGuard, systemd, sbctl,
and Nix are separate upstream projects under their own licenses.

