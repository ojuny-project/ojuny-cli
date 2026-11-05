# ojuny-cli

Status: incomplete and untested. Applies to commit `bd216aa`, 2026-10-31. The install and usage commands were not run for this rewrite.

## Purpose

`ojuny-cli` builds two command line programs for a NixOS desktop running Dux Modular Shell and MangoWM. `ojuny` maps short commands to the tools that own each feature, including mmsg, NetworkManager, BlueZ, PipeWire, playerctl, WireGuard, systemd, and Nix. `ojuny-patches` manages git repositories that contain optional Nix modules called patches.

## Status

Both programs are version 0.1.0 and no tagged release exists. The flake checks
build each program, run the test script, and verify the man page.

The CLI is incomplete. Parts of the designed command surface are not
implemented, and commands may change. The generated reference covers what the
binaries expose today, not the full design. If a command from an older document
is missing, the reference and the man page are the accurate record.

## Requirements

- Linux.
- Nix with flakes enabled, to install from the flake.
- A running Dux Modular Shell session for the categories that control the shell, such as window, workspace, bar, and dock.
- NixOS for `ojuny flake activate-boot` and `ojuny flake activate-now`, which call `nixos-rebuild`.
- `git` for `ojuny-patches`, which clones patch repositories.
- Power and session commands call `systemctl` and `loginctl`, so polkit may ask for authentication. Do not run them from a root shell.
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
$ ojuny-patches --version
ojuny-patches 0.1.0
$ man ojuny
```

`man ojuny` opens the page built from `src/ojuny-cli/man/ojuny.1.scd`. If it reports no manual entry, check that `$XDG_DATA_DIRS` includes the profile that holds the package.

## Releases

A `v*` tag, a manual workflow run, or a commit on `main` whose title starts with
a version such as `v0.1.0` builds `ojuny-cli.bin`, `ojuny-patches.bin`, and
`ojuny-cli-flake.tar.gz`.

The release flake installs the prebuilt bundles without compiling:

```nix
inputs.ojuny-cli.url =
  "tarball+https://github.com/ojuny-project/ojuny-cli/releases/download/vX.Y.Z/ojuny-cli-flake.tar.gz";
```

Add `inputs.ojuny-cli.packages.${pkgs.system}.ojuny-cli` and
`inputs.ojuny-cli.packages.${pkgs.system}.ojuny-patches` to
`environment.systemPackages`.


## Usage

```console
$ ojuny window float
```

See [`docs/cli-reference.md`](docs/cli-reference.md) for every command, option,
and category that the two binaries expose today. The man pages carry the same
text: `man ojuny` and `man ojuny-patches`.

## Configuration and state

Most `ojuny` commands change the running session only. Persistent values belong in the settings menu, for example `ojuny settings open bar`; a reload or rebuild may discard a runtime change. `ojuny flake` is the exception and changes the system through Nix. It reads the flake path from `--flake`, then `OJUNY_FLAKE`, then `~/.config/nix-settings-gui/config.json`, then the current Git root.

`ojuny-patches` stores its repository list and settings under `$XDG_CONFIG_HOME/ojuny/` and its clones under `$XDG_CACHE_HOME/ojuny/patches`. `--dry-run` is accepted for the `ojuny` commands that support it.

## Limits

`ojuny` is a wrapper. It does not store configuration and does not edit Nix files.

`ojuny-patches install` copies one module into the local flake. It does not enable the patch or rebuild the system; enable the patch in the settings GUI after installation. Dependencies are checked by file presence and are not versioned. A dependency cycle exits 6 and a missing dependency exits 5.

Patches are Nix code evaluated with the privileges of the system configuration. Add only repositories you trust.

## Documentation

- [`docs/cli-reference.md`](docs/cli-reference.md): generated list of every
  command, option, and category the binaries expose.
- `man ojuny`: every `ojuny` category, command, option, and exit code.
- `man ojuny-patches`: patch installation, repository layout, and metadata format.
- `docs/user.md`: flake path discovery, exit codes, and `ojuny doctor`.
- `docs/patches.md`: the patch lifecycle, repository list, and security notes.

## Contributing

Report bugs at <https://github.com/ojuny-project/ojuny-cli/issues>. A change must update the affected man page, add or adjust a case in `tests/run.sh`, and pass `nix flake check`. Do not include generated files from `result-cli` or `result-patches`.

## License

GNU General Public License, version 3 or later. See `LICENSE`. mmsg, Dux Modular Shell, NetworkManager, BlueZ, PipeWire, playerctl, WireGuard, systemd, and Nix are separate upstream projects under their own licenses.
