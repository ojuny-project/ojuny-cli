ojuny_usage() {
    cat <<'EOF'
Usage: ojuny [options] <category> <command> [arguments]

Options:
  --flake <path>   Use this flake
  --host <name>    Use this host
  --yes            Do not prompt
  --dry-run        Accepted for commands that support it
  -h, --help       Show help
  -V, --version    Show version

Categories:
  bar          Bar visibility
  dock         Dock visibility
  layout       Layout control
  sound        Audio devices and volume
  network      NetworkManager
  bluetooth    Bluetooth
  window       Window control
  workspace    Workspace control
  flake        Flake update, validate, build, activate
  toggle       Runtime toggles
  display      Display information
  media        Media playback
  dashboard    Dashboard tabs
  island       Island controls
  spotlight    Spotlight
  vpn          WireGuard
  run          Launch an application
  dispatch     Raw mmsg dispatch
  dux          Dux Modular Shell IPC and lifecycle (aliases: dms, shell)
  capture      Screenshots and recording
  clipboard    Clipboard
  notepad      Notepad
  keybinds     Keybind viewer
  settings     Settings pages
  system       Power and session actions
  session      Desktop session actions
  doctor       Diagnostics

Run 'ojuny help <category>' for category help.
EOF
}

ojuny_category_help() {
    case "$1" in
    "")
        ojuny_usage
        ;;
    bar)
        cat <<'EOF'
Usage: ojuny bar <command>
  preset <name>     Switch a non-island bar preset at runtime
  toggle
  show
  hide
  autohide <value>  Persistent setting, use the settings GUI
  move <edge>       Persistent setting, use the settings GUI
EOF
        ;;
    dock)
        cat <<'EOF'
Usage: ojuny dock <command>
  toggle
  autohide
EOF
        ;;
    layout | lay)
        cat <<'EOF'
Usage: ojuny layout <command>
  set <layout> [variant]
  current
EOF
        ;;
    sound | audio)
        cat <<'EOF'
Usage: ojuny sound <command>
  list [inputs|outputs]
  input <id>
  output <id>
  volume <value>
  micvolume <value>
  current
  mute [on|off|toggle]
  micmute [on|off|toggle]
EOF
        ;;
    network | nw | net)
        cat <<'EOF'
Usage: ojuny network <command>
  open
  status
  list
  connect <name>
  disconnect <device>
  enable
  disable
EOF
        ;;
    bluetooth | bt)
        cat <<'EOF'
Usage: ojuny bluetooth <command>
  open
  status
  list
  scan <on|off>
  power <on|off>
  connect <mac>
  disconnect <mac>
EOF
        ;;
    window | win)
        cat <<'EOF'
Usage: ojuny window <command>
  list
  kill
  focus <direction>
  move <direction>
  exchange <direction>
  resize <direction>
  fullscreen
  maximize
  float
  float-all
  minimize
  restore
  pin
  overlay
  detail
  tag-special
  toggle-special
  group-leave
EOF
        ;;
    workspace | ws)
        cat <<'EOF'
Usage: ojuny workspace <command>
  view <id>
  toggle <id>
  move <id>
  next
  previous
  next-client
  previous-client
EOF
        ;;
    flake)
        cat <<'EOF'
Usage: ojuny flake <command>
  update <input>
  validate
  build
  activate-boot
  activate-now
EOF
        ;;
    toggle | tgl)
        cat <<'EOF'
Usage: ojuny toggle <command>
  night
  idle
  sleep
  lockscreen
  screensaver
  dnd
EOF
        ;;
    display | disp)
        cat <<'EOF'
Usage: ojuny display <command>
  list
  current
EOF
        ;;
    media | music)
        cat <<'EOF'
Usage: ojuny media <command>
  play
  pause
  play-pause
  next
  previous
  stop
  status
  volume <value>
EOF
        ;;
    dashboard | dash)
        cat <<'EOF'
Usage: ojuny dashboard <command>
  open <tab>
  close
  toggle <tab>
EOF
        ;;
    island)
        cat <<'EOF'
Usage: ojuny island <command>
  open <activity>
  show <activity>
  cycle
  move <x> <y>
  center <x> <y>
EOF
        ;;
    spotlight | spot)
        cat <<'EOF'
Usage: ojuny spotlight <command>
  toggle
  open
  close
  query <text>
EOF
        ;;
    vpn)
        cat <<'EOF'
Usage: ojuny vpn <command>
  status
  list
  up <interface>
  down <interface>
EOF
        ;;
    run)
        cat <<'EOF'
Usage: ojuny run <command>
  <application> [arguments]
  --shell <command>
EOF
        ;;
    dispatch)
        cat <<'EOF'
Usage: ojuny dispatch <dispatcher> [arguments]
EOF
        ;;
    dux)
        cat <<'EOF'
Usage: ojuny dux <command>
  start
  stop
  restart
  status
  ipc <arguments>

'dms' is a deprecated alias for 'dux'.
EOF
        ;;
    dms)
        dux_deprecation_warning
        ojuny_category_help dux
        ;;
    capture | shot)
        cat <<'EOF'
Usage: ojuny capture <command>
  toolbar
  region
  full
  window
EOF
        ;;
    clipboard | clip)
        cat <<'EOF'
Usage: ojuny clipboard <command>
  open
  clear
EOF
        ;;
    notepad | notes)
        cat <<'EOF'
Usage: ojuny notepad <command>
  open
  toggle
EOF
        ;;
    keybinds)
        cat <<'EOF'
Usage: ojuny keybinds [open]
EOF
        ;;
    settings | set)
        cat <<'EOF'
Usage: ojuny settings open <page>
EOF
        ;;
    system | sys)
        cat <<'EOF'
Usage: ojuny system <command>
  lock
  logout
  suspend
  hibernate
  reboot
  shutdown
EOF
        ;;
    session | sess)
        cat <<'EOF'
Usage: ojuny session <command>
  quit
  restart
EOF
        ;;
    doctor)
        cat <<'EOF'
Usage: ojuny doctor
EOF
        ;;
    *)
        ojuny_err "unknown category: $1"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
