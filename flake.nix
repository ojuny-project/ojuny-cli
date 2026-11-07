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
    inputs@{ self, flake-parts, nixpkgs, ... }:
    let
      binaryInfo =
        if builtins.pathExists ./binary-url.json then
          builtins.fromJSON (builtins.readFile ./binary-url.json)
        else
          null;

      mkBinary =
        {
          system,
          tag ? (
            if binaryInfo == null then throw "ojuny-cli: binary-url.json is missing" else binaryInfo.latest
          ),
          package,
        }:
        let
          release =
            if binaryInfo == null then
              throw "ojuny-cli: binary-url.json is missing"
            else
              binaryInfo.releases.${tag}
                or (throw "ojuny-cli: release '${tag}' is not recorded in binary-url.json");
          packageInfo =
            release.packages.${package}
              or (throw "ojuny-cli: package '${package}' is not recorded in release '${tag}'");
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.callPackage ./nix/binary.nix {
          name = package;
          program = packageInfo.program or package;
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

      flake = {
        hydraJobs = self.checks;
      };

      flake.lib.mkBinary = mkBinary;

      perSystem =
        { pkgs, ... }:
        let
          ojuny-cli = pkgs.callPackage ./packages/ojuny-cli { };
          ojuny-patches-cli = pkgs.callPackage ./packages/ojuny-patches-cli { };

          ojuny-cli-check = pkgs.runCommand "check-ojuny-cli" { } ''
            export HOME="$(mktemp -d)"
            help_file="$(mktemp)"
            version_file="$(mktemp)"
            ${ojuny-cli}/bin/ojuny --help > "$help_file"
            ${ojuny-cli}/bin/ojuny --version > "$version_file"
            grep -q "Usage:" "$help_file"
            grep -q "ojuny" "$version_file"
            test -f ${ojuny-cli}/share/man/man1/ojuny.1.gz
            test -f ${ojuny-cli}/share/bash-completion/completions/ojuny
            test -f ${ojuny-cli}/share/zsh/site-functions/_ojuny
            test -f ${ojuny-cli}/share/fish/vendor_completions.d/ojuny.fish
            test -f ${ojuny-cli}/share/systemd/user/ojuny-ipc.service
            touch $out
          '';

          ojuny-patches-cli-check = pkgs.runCommand "check-ojuny-patches-cli" { } ''
            export HOME="$(mktemp -d)"
            help_file="$(mktemp)"
            version_file="$(mktemp)"
            ${ojuny-patches-cli}/bin/ojuny-patches --help > "$help_file"
            ${ojuny-patches-cli}/bin/ojuny-patches --version > "$version_file"
            grep -q "Usage:" "$help_file"
            grep -q "ojuny-patches" "$version_file"
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
                  pkgs.findutils
                  pkgs.gawk
                  pkgs.gnugrep
                  pkgs.gnused
                  pkgs.git
                  pkgs.jq
                  pkgs.procps
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
          }
          // (
            if binaryInfo != null && binaryInfo.system == pkgs.stdenv.hostPlatform.system then
              {
                ojuny-cli-binary = mkBinary {
                  system = pkgs.stdenv.hostPlatform.system;
                  package = "ojuny-cli";
                };
                ojuny-patches-binary = mkBinary {
                  system = pkgs.stdenv.hostPlatform.system;
                  package = "ojuny-patches";
                };
              }
            else
              { }
          );

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
            ci = {
              type = "app";
              program = "${
                pkgs.writeShellApplication {
                  name = "ci";
                  runtimeInputs = [ pkgs.nix ];
                  text = ''
                    exec nix flake check "$@"
                  '';
                }
              }/bin/ci";
            };
          };

          checks = {
            ojuny-cli = ojuny-cli-check;
            ojuny-patches-cli = ojuny-patches-cli-check;
            binary-programs =
              pkgs.runCommand "check-binary-programs"
                {
                  nativeBuildInputs = [ pkgs.jq ];
                }
                ''
                  jq -e '.releases[.latest].packages["ojuny-cli"].program == "ojuny"' ${./binary-url.json}
                  jq -e '.releases[.latest].packages["ojuny-patches"].program == "ojuny-patches"' ${./binary-url.json}
                  touch $out
                '';
            inherit lint tests;

            cli-reference-current =
              let
                source = pkgs.lib.cleanSource ./.;
              in
              pkgs.runCommand "check-cli-reference" {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.diffutils
                  pkgs.gawk
                  pkgs.gnused
                ];
              } ''
                cp -r ${source} work
                chmod -R u+w work
                cd work
                ./scripts/gen-cli-reference.sh docs/cli-reference.md
                diff -u ${source}/docs/cli-reference.md docs/cli-reference.md
                touch $out
              '';

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
