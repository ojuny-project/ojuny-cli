ojuny(1)

# NAME

ojuny - imperative and status command line for an ojuny desktop

# SYNOPSIS

*ojuny* [options] <category> [command] [arguments]

*ojuny* [options] <command> [arguments]

# DESCRIPTION

*ojuny* is the single command for imperative management and status on an
ojuny system. It wraps the tools that already own each feature: *dms*,
*mmsg*, *nmcli*, *mmcli*, *bluetoothctl*, *rfkill*, *wpctl*, *playerctl*,
*udisksctl*, *systemctl*, *loginctl*, *journalctl*, *sbctl*, *upower*,
*wtype*, *ydotool*, *nix*, and *nixos-rebuild*.

Configuration is declarative and lives in the flake. *ojuny* does not edit Nix
files. Persistent values are changed through *ojuny settings* or
*ojuny raw-settings*.

Most commands affect the running session only. A reload or rebuild may discard
a runtime change. The *flake* category changes the system through Nix.

Every command accepts *--json* and *--help*. Every command without a required
argument has a useful default, such as *ojuny dux* printing status or
*ojuny keybinds* opening the viewer.

# OPTIONS

*-h*, *--help*
	Show help for the current category or command.

*-V*, *--version*
	Show the version and exit.

*--json*
	Emit one JSON document on stdout.

*--quiet*
	Suppress human decoration and print only the primary value.

*--verbose*
	Print the resolved backend argv to stderr.

*--no-color*
	Disable color. *NO_COLOR* and *CLICOLOR=0* also disable it.

*--yes*, *-y*
	Do not prompt.

*--dry-run*
	Print the backend argv and do not execute.

*--system*
	Use the system *systemctl* or *journalctl* scope. Mutating system commands
	require root.

*--flake* <path>
	Use this flake. Overrides *OJUNY_FLAKE*.

*--host* <name>
	Use this NixOS configuration.

# COMMANDS

*status*
	Print a compact system summary. With no arguments, *ojuny* runs this.

*settings* [page]
	Open *nix-settings-gui*, optionally with *--page* <page>. Without a page it
	opens the main window.

*raw-settings* <page>
	Find the first module that declares the matching *@menu* and open it in
	*$VISUAL*, then *$EDITOR*, then *nano*.

*notify* <summary> [body] [flags]
	Send a desktop notification through *dms notify*. Flags follow
	*notify-send*.

*doctor* [*check*|*crashes*|*boot*]
	Print diagnostics. Without a command it runs the full check.

*print-agent-details*
	Print the agent guide, including layout, rules, exit codes, JSON envelope,
	and the full command map.

*print-system-details*
	Print a plaintext support bundle. With *--json* emit a structured object.
	The bundle includes the flake, host, kernel, hardware, DE/WM, session,
	backends, patch state, paths, debug tail, failed units, and a short journal
	tail.

*crashes* [entry|latest]
	List system-wide crashes from *coredumpctl*. *crashes* *latest* prints the
	newest entry, and *crashes* <entry> accepts an index, PID, or cursor and
	prints plaintext details suitable for an LLM. Permission failures print a
	sudo hint; the CLI never escalates.

*commands*
	Print the command catalog. With *--json* it emits the machine-readable
	catalog.

*completions* <bash|zsh|fish>
	Print a completion script. The package installs the scripts for all three
	shells.

# CATEGORIES

*bar* *toggle*|*show*|*hide*
	Bar visibility. Without a command it toggles the bar.

*dock* *status*|*toggle*|*autohide* [on|off|toggle]
	Dock state and visibility. Without a command it prints status.

*layout* *set* <layout> [variant]|*current*
	Layout control. Without a command it prints the current layout.

*window* *list*|*kill*|*focus*|*move*|*exchange*|*resize*|*fullscreen*|
*maximize*|*float*|*float-all*|*minimize*|*restore*|*pin*|*overlay*|
*detail*|*tag-special*|*toggle-special*|*group-leave*|*overview*
	Window control through *mmsg*. Without a command it lists clients.

*workspace* *current*|*view* <id>|*toggle* <id>|*move* <id>|*next*|
*previous*|*next-client*|*previous-client*
	Workspace control. Without a command it prints the active workspace.

*keymode* *get*|*set* <mode>
	Mango keymode. Without a command it prints the current keymode.

*trackpad* *status*|*on*|*off*|*toggle*
	Trackpad state and toggling. *on* and *off* compare the recorded state and
	toggle only when the requested state differs. Mango does not expose the live
	toggle, so the state is recorded by *ojuny* and can drift if the trackpad is
	toggled by a keybind.

*dispatch* <dispatcher> [arguments]
	Raw *mmsg dispatch*.

*dux* *status*|*start*|*stop*|*restart*|*ipc* <arguments>
	Dux Modular Shell lifecycle and raw IPC. Without a command it prints
	status. *dms* and *shell* are aliases.

*dashboard* *toggle*|*open* <tab>|*close*
	Dashboard tabs.

*island* *status*|*open* <activity>|*show* <activity>|*cycle*|*move* <x> <y>|
*center* <x> <y>
	Island controls. Without a command it prints status.

*spotlight* *toggle*|*open*|*close*|*query* <text>
	Spotlight. Without a command it toggles.

*toggle* *list*|*night* [on|off|toggle]|*idle* [on|off|toggle]|
*dnd* [on|off|toggle]|*lockscreen*|*screensaver*
	Runtime toggles. Without a command it lists states.

*clipboard* *open*|*clear*|*echo*|*copy* <text>|*history*|*search* <text>
	Clipboard. *echo* prints the current clipboard text. Without a command it
	opens the panel.

*notepad* *open*|*toggle*
	Notepad. Without a command it opens.

*keybinds* *open*|*list*|*show* <provider>
	Keybind viewer. Without a command it opens.

*capture* *menu*|*region*|*full*|*window*|*scroll*|*text*|*qr*|*edit* [target]|
*toolbar*
	Screenshots, OCR, QR, and editing. Without a command it opens the menu.

*sound* *current*|*list* [inputs|outputs]|*input* <id>|*output* <id>|
*volume* <value>|*micvolume* <value>|*mute* [on|off|toggle]|
*micmute* [on|off|toggle]
	Audio devices and volume.

*media* *status*|*play*|*pause*|*play-pause*|*next*|*previous*|*stop*|
*volume* <value>
	Media playback.

*display* *list*|*current*|*brightness* [get|set <value>|up|down]
	Outputs and backlight brightness.

*network* *status*|*list*|*connect* <name>|*disconnect* <device>|*enable*|
*disable*
	NetworkManager control.

*wifi* *status*|*list*|*scan*|*connect* <ssid> [password]|*disconnect*|*enable*|
*disable*
	Wi-Fi control.

*modem* *status* [modem]|*list*|*enable* <modem>|*disable* <modem>|
*connect* <modem> <apn>|*disconnect* <modem>
	Mobile broadband through *mmcli*.

*bluetooth* *status*|*list*|*scan* [on|off]|*power* [on|off]|*pair* <mac>|
*connect* <mac>|*disconnect* <mac>|*trust* <mac>|*remove* <mac>
	Bluetooth control.

*radio* *list*|*wifi* [on|off]|*bluetooth* [on|off]
	Radio kill state through *rfkill*.

*vpn* *status*|*list*|*up* <name>|*down* <name>|*import* <file> [--dir <path>]
	VPN profiles through NetworkManager. *import* copies a *.conf* profile to
	the WireGuard watch directory, which defaults to
	*~/.config/ojuny/wireguard*.

*disk* *list*|*mount* <device>|*unmount* <device>|*eject* <device>
	Removable storage through *udisksctl*.

*system* *status*|*battery*|*lock*|*logout*|*suspend*|*hibernate*|*reboot*|
*shutdown*
	Power and session actions.

*input* *type* <text>|*key* <combo>|*click* [left|right|middle]|
*move* <x> <y>|*scroll* <up|down|left|right> [amount]
	Synthetic input through *wtype* and *ydotool*.

*run* <application> [arguments]|*run* *--shell* <command>
	Launch an application or shell command.

*flake* *status*|*update* <input>...|*validate*|*build* [--serial]|
*activate* [--boot|--now]|*rollback* [generation]|*generations*|
*gc* [--dry-run]|*option* <path>
	Flake and system management. *update* requires at least one input.
	*activate* requires root and prints a sudo hint when run unprivileged.

*service* *list*|*status* <name>|*start* <name>|*stop* <name>|
*restart* <name>|*reload* <name>|*enable* <name>|*disable* <name>
	Systemd services. Uses *systemctl --user* unless the process is root.
	Mutating system services require root.

*logs* [unit] [--follow] [--since <time>] [--lines <n>] [--system]
	Journal logs. Uses *journalctl --user* unless the process is root.

*secureboot* *status*|*list*|*verify*|*sign* <file>|*sign-all*|*bundle*|
*enroll*|*create-keys*|*reset*
	Secure Boot keys and signing through *sbctl*. Mutating commands require
	root.

*multiboot* *status*|*rescan*
	Detected other operating systems through the optional rEFInd helper.
	*status* reads */var/lib/ojuny/multiboot.json*. *rescan* requires root and
	starts *ojuny-multiboot.service*.

*recovery* *status*|*rebuild*
	Recovery UKI state and rebuild. *status* reads */var/lib/ojuny/recovery.json*.
	*rebuild* requires root and starts *ojuny-recovery.service*.

*bootorder* *status*|*fix*
	Firmware boot order through *efibootmgr*. *fix* requires root and starts
	*ojuny-bootorder.service*.

*ipc* *path*|*status*|*call* <method> [args...]|*watch* <topic>|*serve*|*session*
	Local IPC bridge. The socket lives at
	*$XDG_RUNTIME_DIR/ojuny/ipc.sock* and speaks newline-delimited JSON.
	*ipc* *call* sends one method, *ipc* *watch* streams topic events, and
	*ipc* *serve* runs the *socat* listener. *ipc* *session* is internal.

*debug* *status*|*on*|*off*|*tail* [--lines N]|*clear*
	Debug logging. The log lives at *$XDG_STATE_HOME/ojuny/debug.log* and
	redacts passwords, PSKs, private keys, and tokens.

# SETTINGS

*ojuny settings* opens *nix-settings-gui*. *ojuny settings displays* runs
*nix-settings-gui --page displays*. The page argument is a regular expression.

*ojuny raw-settings displays* scans the flake for *@menu* declarations, takes
the first match, and opens that module in the user's editor. *--list* prints
the pages and files without opening anything.

# JSON

Every command accepts *--json*. The success envelope is:

	{"schema":1,"command":"network.status","ok":true,"data":{},"meta":{}}

The failure envelope is:

	{"schema":1,"command":"vpn.up","ok":false,"error":{"code":3,"message":"...","hint":"..."}}

JSON is one document on stdout, with no color and no diagnostics. Backend
output goes to stderr.

# COMPLETION

The package installs *ojuny* completion for bash, zsh, and fish. To print a
script manually, run *ojuny completions* <shell>. Dynamic completion covers
VPN profiles, Wi-Fi networks, Bluetooth devices, settings pages, services,
disks, flake inputs, and generations.

# ENVIRONMENT

*OJUNY_LIB_DIR*
	Directory with the shell modules. Set by the package wrapper.

*OJUNY_VERSION*
	Version string shown by *--version*.

*OJUNY_FLAKE*
	Flake path used by the *flake* category.

*OJUNY_HOST*
	NixOS configuration name.

*OJUNY_WIREGUARD_DIR*
	WireGuard watch directory used by *vpn import*.

*XDG_RUNTIME_DIR*
	Base for the IPC socket. The socket is *$XDG_RUNTIME_DIR/ojuny/ipc.sock*.

*XDG_STATE_HOME*
	Base for debug logs and ojuny crash records.

*OJUNY_DEBUG*
	Set to *1* to enable debug logging without the marker file.

*NO_COLOR*
	Disable color output.

# FILES

_$XDG_CONFIG_HOME/nix-settings-gui/config.json_
	Read for the configured flake path.

_$XDG_CONFIG_HOME/ojuny/wireguard_
	Default WireGuard watch directory.

_$XDG_RUNTIME_DIR/ojuny/ipc.sock_
	IPC socket.

_$XDG_STATE_HOME/ojuny/debug.log_
	Debug log.

_$XDG_STATE_HOME/ojuny/crashes/_
	Ojuny crash records.

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
ojuny status
ojuny wifi list
ojuny wifi connect home-wifi
ojuny vpn import ~/Downloads/work.conf
ojuny vpn up work
ojuny bluetooth connect AA:BB:CC:DD:EE:FF
ojuny display brightness set 60
ojuny service status NetworkManager
ojuny logs NetworkManager --since "10 min ago"
ojuny settings displays
ojuny raw-settings displays
ojuny flake update nixpkgs
sudo ojuny flake activate --boot
ojuny print-system-details
ojuny crashes
ojuny crashes latest
ojuny debug on
ojuny ipc status
ojuny ipc call status
```

# SEE ALSO

*ojuny-patches*(1)
