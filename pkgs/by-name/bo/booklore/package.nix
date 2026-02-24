{
  stdenv,
  fetchFromGitHub,
  lib,
  makeWrapper,
  gradle_8,
  openjdk25,
  buildNpmPackage,
  nix-update-script,
}:

let
  gradle = gradle_8;
  jdk = openjdk25;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "booklore";
  version = "2.0.4";

  src = fetchFromGitHub {
    owner = "booklore-app";
    repo = "booklore";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JbOS4F1dFFIIu93spBXkEORvTEMmEV0B3VGkKwk+QEI=";
  };

  sourceRoot = "${finalAttrs.src.name}/booklore-api";

  nativeBuildInputs = [
    gradle
    jdk
    makeWrapper
  ];

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  gradleFlags = [
    "--info"
    "-Dorg.gradle.welcome=never"
    "-Dorg.gradle.java.home=${jdk}"
  ];
  # doCheck = true;
  doCheck = false;

  passthru.frontend = buildNpmPackage (finalAttrs': {
    pname = "booklore-ui";
    inherit (finalAttrs) version src;

    sourceRoot = "${finalAttrs.src.name}/booklore-ui";

    npmDepsHash = "sha256-Ne+BRJyaWPm+u/FxOLThLpQdmtZh7i0K+IZih/vY6T4=";

    npmFlags = [ "--legacy-peer-deps" ];
  });

  passthru.updateScript = nix-update-script { };

  installPhase = ''
    mkdir -p $out/{bin,share/booklore-api}
    cp build/libs/booklore-api-0.0.1-SNAPSHOT.jar $out/share/booklore-api

    makeWrapper ${lib.getExe jdk} $out/bin/booklore-api \
      --add-flags "-jar $out/share/booklore-api/booklore-api-0.0.1-SNAPSHOT.jar"
  '';

  meta = {
    description = "A self-hosted, multi-user digital library with smart shelves, auto metadata, Kobo & KOReader sync, BookDrop imports, OPDS support, and a built-in reader for EPUB, PDF, and comics";
    homepage = "https://github.com/booklore-app/booklore";
    mainProgram = "booklore-api";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ tmarkus ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # mitm cache
    ];
  };
})

