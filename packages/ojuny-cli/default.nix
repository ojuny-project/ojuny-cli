{
  lib,
  stdenvNoCC,
  scdoc,
  bash,
  coreutils,
  findutils,
  procps,
  gawk,
  gnugrep,
  gnused,
  jq,
  git,
  nix,
  nixos-rebuild,
  nixos-option,
  util-linux,
  systemd,
  networkmanager,
  modemmanager,
  bluez,
  wireplumber,
  playerctl,
  udisks2,
  upower,
  sbctl,
  wtype,
  ydotool,
  socat,
}:

(import ../../lib/mk-cli.nix {
  inherit
    lib
    stdenvNoCC
    scdoc
    bash
    ;
})
  {
    pname = "ojuny-cli";
    program = "ojuny";
    description = "Main entry point for the ojuny command line utilities";
    src = ../../src/ojuny-cli;
    sharedLib = ../../src/lib;
    completions = true;
    runtimeInputs = [
      coreutils
      findutils
      procps
      gawk
      gnugrep
      gnused
      jq
      git
      nix
      nixos-rebuild
      nixos-option
      util-linux
      systemd
      networkmanager
      modemmanager
      bluez
      wireplumber
      playerctl
      udisks2
      upower
      sbctl
      wtype
      ydotool
      socat
    ];
    postInstall = ''
      install -Dm644 ${../../src/ojuny-cli/systemd/ojuny-ipc.service} $out/share/systemd/user/ojuny-ipc.service
      substituteInPlace $out/share/systemd/user/ojuny-ipc.service \
        --replace-fail '@ojuny@' "$out/bin/ojuny"
    '';
  }
