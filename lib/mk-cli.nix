{
  lib,
  stdenvNoCC,
  scdoc,
  bash,
}:

{
  pname,
  program,
  src,
  description,
  version ? "0.1.0",
  sharedLib ? null,
  runtimeInputs ? [ ],
  completions ? false,
  postInstall ? "",
}:

let
  libDirEnvVar = "${lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] program)}_LIB_DIR";
  versionEnvVar = "${lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] program)}_VERSION";
  runtimePath = lib.makeBinPath (runtimeInputs ++ [ bash ]);
in

stdenvNoCC.mkDerivation {
  inherit
    pname
    src
    version
    postInstall
    ;

  nativeBuildInputs = [ scdoc ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${src}/bin/${program} "$out/libexec/${program}"

    install -d "$out/share/${pname}/lib"
    ${lib.optionalString (sharedLib != null) ''cp -r ${sharedLib}/. "$out/share/${pname}/lib/"''}
    cp -r ${src}/lib/. "$out/share/${pname}/lib/"
    chmod -R u+w "$out/share/${pname}/lib"

    install -d "$out/share/man/man1"
    scdoc < ${src}/man/${program}.1.scd > "$out/share/man/man1/${program}.1"

    ${lib.optionalString completions ''
      install -d "$out/share/bash-completion/completions"
      install -d "$out/share/zsh/site-functions"
      install -d "$out/share/fish/vendor_completions.d"
      OJUNY_LIB_DIR="$out/share/${pname}/lib" OJUNY_VERSION="${version}" \
        ${bash}/bin/bash "$out/libexec/${program}" completions bash \
        > "$out/share/bash-completion/completions/${program}"
      OJUNY_LIB_DIR="$out/share/${pname}/lib" OJUNY_VERSION="${version}" \
        ${bash}/bin/bash "$out/libexec/${program}" completions zsh \
        > "$out/share/zsh/site-functions/_${program}"
      OJUNY_LIB_DIR="$out/share/${pname}/lib" OJUNY_VERSION="${version}" \
        ${bash}/bin/bash "$out/libexec/${program}" completions fish \
        > "$out/share/fish/vendor_completions.d/${program}.fish"
    ''}

    install -d "$out/bin"
    cat > "$out/bin/${program}" <<EOF
    #!${bash}/bin/bash
    export ${libDirEnvVar}="$out/share/${pname}/lib"
    export OJUNY_VERSION="${version}"
    export ${versionEnvVar}="${version}"
    export PATH="${runtimePath}:\$PATH"
    exec "$out/libexec/${program}" "\$@"
    EOF
    chmod 755 "$out/bin/${program}"

    runHook postInstall
  '';

  meta = {
    inherit description;
    mainProgram = program;
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
