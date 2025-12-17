{
  stdenv,
  fetchFromGitHub,
  lib,
  gradle,
  makeWrapper,
  jre,
  buildNpmPackage,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "booklore";
  version = "1.14.1";

  src = fetchFromGitHub {
    owner = "booklore-app";
    repo = "booklore";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8Aw908Yz2W/Pi0DsblwYGiwRPWJJo/jP8/D56obDMwY=";
  };

  sourceRoot = "${finalAttrs.src.name}/booklore-api";

  nativeBuildInputs = [
    gradle
    makeWrapper
  ];

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  gradleFlags = [ "-Dorg.gradle.welcome=never" ];

  # defaults to "assemble"
  # gradleBuildTask = "shadowJar";

  # doCheck = true;
  doCheck = false;

  passthru.frontend = buildNpmPackage (finalAttrs': {
    pname = "booklore-ui";
    inherit (finalAttrs) version src;

    sourceRoot = "${finalAttrs.src.name}/booklore-ui";

    npmDepsHash = "sha256-DEC67N9ArHpM5cR+l1gYkt3pQy1C5EH2jq9e/05qdDA=";

    npmFlags = [ "--legacy-peer-deps" ];
  });

  installPhase = ''
    mkdir -p $out/{bin,share/booklore-api}
    cp build/libs/booklore-api-0.0.1-SNAPSHOT.jar $out/share/booklore-api

    makeWrapper ${lib.getExe jre} $out/bin/booklore-api \
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
