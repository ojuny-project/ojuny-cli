ojuny(1)

# NAME

ojuny - thin command line wrapper for Dux Modular Shell

# SYNOPSIS

*ojuny* [options] <category> <command> [arguments]

# DESCRIPTION

*ojuny* maps a category and command to a small backend wrapper. It runs
*mmsg*, *dms*, *nmcli*, *bluetoothctl*, *wpctl*, *playerctl*, *wg*,
*systemctl*, *loginctl*, *nix*, and *nixos-rebuild* as needed.

Dux Modular Shell is the desktop shell product. The upstream runtime binary is still
*dms*, and IPC still runs through *dms ipc call*.

Most commands affect the running session only. A reload or rebuild may discard
a runtime change. Persistent settings belong in the settings GUI. The *flake*
category is the exception and changes the system through Nix.

# OPTIONS

*-h*, *--help*
	Show usage and exit.

*-V*, *--version*
	Show the version and exit.

*--flake* <path>
	Use this flake. Overrides *OJUNY_FLAKE*.

*--host* <name>
	Use this NixOS configuration.

*--yes*
	Do not prompt.

*--dry-run*
	Accepted for commands that support it.

# COMMANDS

*bar* *preset* <name>
	Switch a non-island bar preset at runtime. Island presets need a save
	and rebuild.

*bar* *toggle*|*show*|*hide*
	Control bar visibility.

*dock* *toggle*, *autohide*
	Control dock visibility and auto hide.

*layout* *set* <name> [variant], *current*
	Change or read the active layout.

*sound* *list*, *input* <id>, *output* <id>, *volume* <value>,
*micvolume* <value>, *current*, *mute* [on|off|toggle],
*micmute* [on|off|toggle]
	Audio devices and volume.

*network* *open*, *status*, *list*, *connect* <name>, *disconnect* <device>,
*enable*, *disable*
	NetworkManager controls.

*bluetooth* *open*, *status*, *list*, *scan* <on|off>, *power* <on|off>,
*connect* <mac>, *disconnect* <mac>
	Bluetooth controls.

*window* *list*, *kill*, *focus* <direction>, *move* <direction>,
*exchange* <direction>, *resize* <direction>, *fullscreen*, *maximize*,
*float*, *float-all*, *minimize*, *restore*, *pin*, *overlay*, *detail*,
*tag-special*, *toggle-special*, *group-leave*
	Window controls.

*workspace* *view* <id>, *toggle* <id>, *move* <id>, *next*, *previous*,
*next-client*, *previous-client*
	Workspace controls.

*flake* *update* <input>, *validate*, *build*, *activate-boot*,
*activate-now*
	Flake and system commands. These print a copy-paste context block.

*toggle* *night*, *idle*, *sleep*, *lockscreen*, *screensaver*, *dnd*
	Runtime toggles.

*display* *list*, *current*
	Display information.

*media* *play*, *pause*, *play-pause*, *next*, *previous*, *stop*,
*status*, *volume* <value>
	Media playback.

*dashboard* *open* <tab>, *close*, *toggle* <tab>
	Dashboard controls.

*island* *open* <activity>, *show* <activity>, *cycle*, *move* <x> <y>,
*center* <x> <y>
	Island controls.

*spotlight* *toggle*, *open*, *close*, *query* <text>
	Spotlight controls.

*vpn* *status*, *list*, *up* <interface>, *down* <interface>
	WireGuard controls.

*run* <application> [arguments], *run* *--shell* <command>
	Launch an application or shell command.

*dispatch* <dispatcher> [arguments]
	Raw *mmsg dispatch*.

*dux* *start*, *stop*, *restart*, *status*, *ipc* <arguments>
	Dux Modular Shell lifecycle and raw IPC through the *dms* binary.

*dms* and *shell* are aliases for *dux*.

*capture* *toolbar*, *region*, *full*, *window*
	Screenshots and recording.

*clipboard* *open*, *clear*
	Clipboard history.

*notepad* *open*, *toggle*
	Notepad.

*keybinds* *open*
	Keybind viewer.

*settings* *open* <page>
	Open a settings page.

*system* *lock*, *logout*, *suspend*, *hibernate*, *reboot*, *shutdown*
	Power and session actions.

*session* *quit*, *restart*
	Desktop session actions.

*doctor*
	Print diagnostics.

# ENVIRONMENT

*OJUNY_LIB_DIR*
	Directory with the shell modules. Set by the package wrapper.

*OJUNY_VERSION*
	Version string shown by *--version*.

*OJUNY_FLAKE*
	Flake path used by the *flake* category.

*OJUNY_HOST*
	NixOS configuration name.

*NO_COLOR*
	Disable color output.

# FILES

_$XDG_CONFIG_HOME/nix-settings-gui/config.json_
	Read for the configured flake path.

# EXIT STATUS

0
	Success.

2
	Usage error.

3
	Missing dependency.

4
	Backend failure.

5
	Validation failure.

6
	Conflict.

# EXAMPLES

```
ojuny window float
ojuny workspace view 2
ojuny flake validate
ojuny flake activate-boot
```

# SEE ALSO

*ojuny-patches*(1)
