# ojuny patches

`ojuny-patches` is a small package manager backed by git. Installation is one
file copy.

## Repositories

`repos.list` holds one git URL per line. The file is created with the default
repository on first use.

```sh
ojuny-patches repo list
ojuny-patches repo add https://github.com/example/patches
ojuny-patches repo remove https://github.com/example/patches
ojuny-patches sync
ojuny-patches sync example
```

## Repository layout

A repository may contain multiple patches:

```
modules/patches/<id>.nix
<id>/metadata.md
```

The ID is the non-pretified name. IDs use lowercase letters, digits, and single
dashes. The installed file is copied to:

```
<local_repository>/<patch_directory>/<id>.nix
```

The defaults are `$HOME/repos/nix-flake` and `modules/patches`.

## Metadata

Metadata is Markdown with simple `key: value` lines:

```
name: Development
id: patch-development
description: VSCodium, per-language LSP toggles, optional coding agents, the dmenu project picker with devshell actions, and multi-repository project scaffolding
dependencies:
version: 4
```

`dependencies` is a comma-separated list of patch IDs. Dependencies are checked
by file presence in the local patch directory. Missing dependencies are
installed first, recursively. Cycles are rejected.

## Commands

```sh
ojuny-patches sync [repo]
ojuny-patches list available
ojuny-patches list installed
ojuny-patches info <id>
ojuny-patches install <id>
ojuny-patches remove <id>
ojuny-patches reinstall <id>
ojuny-patches configure local_repository <path>
ojuny-patches configure patch_directory <path>
```

## Enabling

Installation does not enable a patch. Enable it in the settings GUI under
Patches. The installed module already defines the expected `patch-<id>`
attribute.

## Security

Patches are Nix code. A patch is evaluated during a rebuild with the same
privileges as the configuration. Only add repositories you trust.
