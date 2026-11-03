ojuny-patches(1)

# NAME

ojuny-patches - git-backed patch manager for ojuny

# SYNOPSIS

*ojuny-patches* [options] <command> [arguments]

# DESCRIPTION

*ojuny-patches* manages a list of git repositories that contain ojuny patches.
It clones or updates the repositories in a cache, reads patch metadata, and
installs a patch by copying one Nix module into the local flake.

Installation is only a file copy. The tool does not enable patches, edit their
contents, or rebuild the system. Enable the patch in the settings GUI after
installation.

# OPTIONS

*-h*, *--help*
	Show usage and exit.

*-V*, *--version*
	Show the version and exit.

*--flake* <path>
	Use this flake as the local repository. Overrides the configured
	*local_repository*.

*--yes*
	Do not prompt.

# COMMANDS

*sync* [repo]
	Clone missing repositories and run *git pull --ff-only* on existing
	repositories. The optional argument matches a URL or cache name.

*list* *available*|*installed*
	List patches in the synced repositories or in the local patch directory.

*configure* <key> <value>
	Set *local_repository* or *patch_directory*.

*repo* *list*, *repo* *add* <url>, *repo* *remove* <url>
	Manage the repository list.

*install* <id>
	Install a patch and its dependencies. Dependencies are installed first.
	A dependency cycle exits 6. A missing dependency exits 5.

*remove* <id>
	Remove an installed patch after confirmation.

*info* <id>
	Show metadata, repository, commit, and install state.

*reinstall* <id>
	Remove and install a patch.

# FILES

_$XDG_CONFIG_HOME/ojuny/patches.conf_
	Configuration keys *local_repository* and *patch_directory*.

_$XDG_CONFIG_HOME/ojuny/repos.list_
	One repository URL per line. Created with the default repository on first
	use.

_$XDG_CACHE_HOME/ojuny/patches_
	One git clone per repository.

# REPOSITORY LAYOUT

A repository may contain multiple patches:

```
modules/patches/<id>.nix
<id>/metadata.md
```

The ID is the non-pretified name, for example *patch-development*. IDs
use lowercase letters, digits, and single dashes. The installed file is copied
to *<local_repository>/<patch_directory>/<id>.nix*.

Metadata is Markdown with simple *key: value* lines:

```
name: Development
id: patch-development
description: VSCodium, per-language LSP toggles, optional coding agents, the dmenu project picker with devshell actions, and multi-repository project scaffolding
dependencies:
version: 4
```

*dependencies* is a comma-separated list of patch IDs. Dependencies are not
versioned.

# EXIT STATUS

0
	Success.

2
	Usage error.

3
	Missing dependency.

5
	Validation failure.

6
	Conflict or dependency cycle.

# EXAMPLES

```
ojuny-patches repo list
ojuny-patches sync
ojuny-patches list available
ojuny-patches install patch-development
ojuny-patches info patch-development
ojuny-patches --yes remove patch-development
```

# SEE ALSO

*ojuny*(1)
