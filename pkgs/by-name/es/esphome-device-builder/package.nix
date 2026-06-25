{
  lib,
  python3Packages,
  fetchFromGitHub,
  nodejs,
  fetchNpmDeps,
  npmHooks,
  git,
  versionCheckHook,
  nix-update-script,
}:

let
  pythonPackages = python3Packages.overrideScope (
    self: super: {
      esphome-device-builder-frontend = super.buildPythonPackage (finalAttrs: {
        pname = "esphome-device-builder-frontend";
        version = "0.1.231";
        pyproject = true;

        __structuredAttrs = true;

        src = fetchFromGitHub {
          owner = "esphome";
          repo = "device-builder-frontend";
          tag = finalAttrs.version;
          hash = "sha256-3Q4qNTCrXYp50kfIPyDtUIdv1P/mQQQlPBKLMa3PDx8=";
        };

        npmDeps = fetchNpmDeps {
          inherit (finalAttrs) src;
          hash = "sha256-JDpUk/aEgPpx8X2AuPlm7rCpvfOX0vfLHpSDlBRN/5o=";
        };

        nativeBuildInputs = [
          nodejs
          npmHooks.npmConfigHook
          self.pyprojectVersionPatchHook
        ];

        build-system = with self; [
          setuptools
        ];

        preBuild = ''
          npm run build
        '';

        pythonImportsCheck = [
          "esphome_device_builder_frontend"
        ];
      });
    }
  );
  binPath = lib.makeBinPath [
    pythonPackages.esphome
    git
  ];
in

pythonPackages.buildPythonApplication (finalAttrs: {
  pname = "esphome-device-builder";
  version = "1.4.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "esphome";
    repo = "device-builder";
    tag = finalAttrs.version;
    hash = "sha256-OQiBtzY/ADCYT7tqIILqZFn2uQpsZS1w0d5zKypxT8g=";
  };

  __structuredAttrs = true;

  nativeBuildInputs = with pythonPackages; [
    pyprojectVersionPatchHook
  ];

  build-system = with pythonPackages; [
    setuptools
  ];

  dependencies = with pythonPackages; [
    esphome
    esphome-device-builder-frontend

    aiohttp
    aiohttp-asyncmdnsresolver
    colorlog
    cryptography
    fnv-hash-fast
    ifaddr
    icmplib
    mashumaro
    orjson
    pyyaml
    ruamel-yaml
    voluptuous
  ];

  nativeCheckInputs = with pythonPackages; [
    versionCheckHook
    pytestCheckHook
    pytest-aiohttp
    pytest-codspeed
    pytest-cov-stub
    pytest-timeout
    pytest-xdist
    blockbuster
  ];

  # Needed for tests
  __darwinAllowLocalNetworking = true;

  pytestFlags = [
    "--timeout=30"
  ];

  preCheck = ''
    export PATH=$PATH:${binPath}
  '';

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    binPath

    # The dashboard requires esphome to be importable
    # dependencies are added to show better error messages
    "--prefix"
    "PYTHONPATH"
    ":"
    "$out/${pythonPackages.python.sitePackages}:${pythonPackages.makePythonPath finalAttrs.passthru.dependencies}"
  ];

  disabledTestPaths = [
    # consider disabling these tests if test phase is taking excessively long
    # "tests/e2e/slow"

    # presumably fails due to required network access to download LibreTiny
    "tests/e2e/slow/boards/test_create_all_boards.py"
  ];

  disabledTests = [
    # tests that try to access GitHub
    "test_esp_idf_compile_download_round_trip"
    "test_libretiny_bk7231n_compile_download_round_trip"

    # timeout
    "test_get_component_bodies_returns_full_batch_larger_than_cache"
  ];

  passthru = {
    frontend = pythonPackages.esphome-device-builder-frontend;

    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    changelog = "https://github.com/esphome/device-builder/releases/tag/${finalAttrs.src.tag}";
    description = "ESPHome Device Builder Dashboard ";
    homepage = "https://esphome.io/";
    license = [ lib.licenses.asl20 ];
    maintainers = with lib.maintainers; [
      tmarkus
      karlbeecken
    ];
    mainProgram = "esphome-device-builder";
  };
})
