{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.services.bichon;
  format = pkgs.formats.keyValue { };
  settingsFile = format.generate "bichon-env-vars" cfg.settings;
in
{
  options.services.bichon = {
    enable = lib.mkEnableOption "bichon";
    package = lib.mkPackageOption pkgs "bichon" { };

    # TODO: Bikeshed option name
    encryptPasswordFile = lib.mkOption {
      type = lib.types.path;
      example = "/run/secrets/bichon-encrypt-password";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 15630;
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;

        # TODO: Select which subset of options to keep
        options = {
          BICHON_LOG_LEVEL = lib.mkOption {
            type = lib.types.str;
            default = "info";
          };
          BICHON_ANSI_LOGS = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          BICHON_LOG_TO_FILE = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          BICHON_JSON_LOGS = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          BICHON_MAX_SERVER_LOG_FILES = lib.mkOption {
            type = lib.types.int;
            default = 5;
          };

          BICHON_HTTP_PORT = lib.mkOption {
            type = lib.types.int;
            description = "Port for the HTTP server.";
            default = 15630;
          };
          BICHON_BIND_IP = lib.mkOption {
            type = lib.types.str;
            default = "0.0.0.0";
          };
          #BICHON_CORS_ORIGINS = lib.mkOption {
          #  type = lib.types.str;
          #  example = "http://localhost:5173, http://localhost:15630, *";
          # default = "0.0.0.0";
          #};
          #BICHON_CORS_MAX_AGE = lib.mkOption {
          #  type = lib.types.int;
          #  description = "Maximum age in seconds for CORS preflight cache.";
          #  default = 86400;
          #};
          #BICHON_PUBLIC_URL = lib.mkOption {
          #  type = lib.types.str;
          #  example = "https://example.org";
          #  # default = "0.0.0.0";
          #};

          # TODO: Hook up to StateDirectory machinery
          BICHON_ROOT_DIR = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/bichon";
          };
          BICHON_INDEX_DIR = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/bichon/envelope";
          };
          BICHON_DATA_DIR = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/bichon/eml";
          };
          BICHON_METADATA_CACHE_SIZE = lib.mkOption {
            type = lib.types.int;
            description = "Cache size (bytes) for metadata database";
            default = 128 * 1024 * 1024;
            defaultText = "128 MiB";
          };
          BICHON_ENVELOPE_CACHE_SIZE = lib.mkOption {
            type = lib.types.int;
            description = "Cache size (bytes) for envelope database";
            default = 1024 * 1024 * 1024;
            defaultText = "1 GiB";
          };
          #BICHON_SYNC_CONCURRENCY = lib.mkOption {
          #  type = lib.types.int;
          #  description = "Maximum number of concurrent email sync tasks. Must be ≥ 1.";
          #};
          #BICHON_HTTP_COMPRESSION_ENABLED = lib.mkOption {
          #  type = lib.types.nullOr lib.types.bool;
          #  description = "Enable HTTP compression for API responses.";
          # default = null;
          #};
        };
      };

      default = { };

      description = "Bichon settings as documented in the wiki: <https://github.com/rustmailer/bichon/wiki/Configuration-Reference>";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bichon = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        BICHON_ROOT_DIR = "%S/bichon/data";
        BICHON_ENCRYPT_PASSWORD_FILE = "%d/bichon-encrypt-password";
        # BICHON_HTTP_PORT = cfg.port;
      };

      unitConfig = {
        Description = "A lightweight, high-performance Rust email archiver with WebUI";
        Documentation = [ "https://github.com/rustmailer/bichon" ];
        Wants = [ "network.target" ];
      };

      serviceConfig = {
        Type = "exec";
        ExecStart = "${lib.getExe' cfg.package "bichon"}";
        # serve --config-dir $CONFIGURATION_DIRECTORY --data-dir $STATE_DIRECTORY";
        Restart = "on-failure";

        EnvironmentFile = [
          settingsFile
        ];

        DynamicUser = true;

        StateDirectory = "bichon";

        LoadCredential = [
          "bichon-encrypt-password:${cfg.encryptPasswordFile}"
        ];

        # Hardening
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateUsers = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateMounts = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        UMask = "0077";
        SystemCallFilter = "@system-service";
      };
    };
  };
}
