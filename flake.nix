{
  description = "ojuny-cli - CLI utilities for ojuny";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    let
      binaryInfo =
        if builtins.pathExists ./binary-url.json
        then builtins.fromJSON (builtins.readFile ./binary-url.json)
        else null;

      mkBinary = {
        system,
        tag ? (if binaryInfo == null then throw "ojuny-cli: binary-url.json is missing" else binaryInfo.latest),
        package,
      }: let
        release =
          if binaryInfo == null
          then throw "ojuny-cli: binary-url.json is missing"
          else binaryInfo.releases.${tag} or (throw "ojuny-cli: release '${tag}' is not recorded in binary-url.json");
        packageInfo = release.packages.${package} or (throw "ojuny-cli: package '${package}' is not recorded in release '${tag}'");
        pkgs = nixpkgs.legacyPackages.${system};
      in
        pkgs.callPackage ./nix/binary.nix {
          name = package;
          inherit (packageInfo) file;
          info = {
            inherit (binaryInfo) repo system;
            inherit (release) tag version;
            inherit (packageInfo) url hash;
          };
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      flake.lib.mkBinary = mkBinary;

      perSystem =
        { pkgs, ... }:
        let
          ojuny-cli = pkgs.callPackage ./packages/ojuny-cli { };
          ojuny-patches-cli = pkgs.callPackage ./packages/ojuny-patches-cli { };

          ojuny-cli-check = pkgs.runCommand "check-ojuny-cli" { } ''
            export HOME="$(mktemp -d)"
            ${ojuny-cli}/bin/ojuny --help | grep -q "Usage:"
            ${ojuny-cli}/bin/ojuny --version | grep -q "ojuny"
            test -f ${ojuny-cli}/share/man/man1/ojuny.1.gz
            touch $out
          '';

          ojuny-patches-cli-check = pkgs.runCommand "check-ojuny-patches-cli" { } ''
            export HOME="$(mktemp -d)"
            ${ojuny-patches-cli}/bin/ojuny-patches --help | grep -q "Usage:"
            ${ojuny-patches-cli}/bin/ojuny-patches --version | grep -q "ojuny-patches"
            test -f ${ojuny-patches-cli}/share/man/man1/ojuny-patches.1.gz
            touch $out
          '';

          lint =
            pkgs.runCommand "lint"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.nixfmt
                  pkgs.shellcheck
                  pkgs.shfmt
                ];
              }
              ''
                cd ${./.}
                shellcheck -S warning \
                  src/lib/*.sh \
                  src/ojuny-cli/bin/ojuny \
                  src/ojuny-cli/lib/*.sh \
                  src/ojuny-cli/lib/subtrees/*.sh \
                  src/ojuny-patches-cli/bin/ojuny-patches \
                  src/ojuny-patches-cli/lib/*.sh
                shfmt -d -i 4 src tests
                nixfmt --check flake.nix lib/mk-cli.nix \
                  packages/ojuny-cli/default.nix \
                  packages/ojuny-patches-cli/default.nix
                touch $out
              '';

          tests =
            pkgs.runCommand "tests"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.git
                  pkgs.gnugrep
                  pkgs.jq
                ];
              }
              ''
                export HOME="$(mktemp -d)"
                OJUNY_BIN=${ojuny-cli}/bin/ojuny \
                  OJUNY_PATCHES_BIN=${ojuny-patches-cli}/bin/ojuny-patches \
                  bash ${./tests/run.sh}
                touch $out
              '';
        in
        {
          packages = {
            inherit ojuny-cli ojuny-patches-cli;
            default = ojuny-cli;
          } // (if binaryInfo != null && binaryInfo.system == pkgs.stdenv.hostPlatform.system then {
            ojuny-cli-binary = mkBinary {system = pkgs.stdenv.hostPlatform.system; package = "ojuny-cli";};
            ojuny-patches-binary = mkBinary {system = pkgs.stdenv.hostPlatform.system; package = "ojuny-patches";};
          } else {});

          apps = {
            ojuny = {
              type = "app";
              program = "${ojuny-cli}/bin/ojuny";
            };
            ojuny-patches = {
              type = "app";
              program = "${ojuny-patches-cli}/bin/ojuny-patches";
            };
            default = {
              type = "app";
              program = "${ojuny-cli}/bin/ojuny";
            };
          };

          checks = {
            ojuny-cli = ojuny-cli-check;
            ojuny-patches-cli = ojuny-patches-cli-check;
            inherit lint tests;
            default = ojuny-cli-check;
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.bash
              pkgs.gawk
              pkgs.git
              pkgs.jq
              pkgs.nixfmt
              pkgs.scdoc
              pkgs.shellcheck
              pkgs.shfmt
            ];
          };

          formatter = pkgs.nixfmt;
        };
    };
}
