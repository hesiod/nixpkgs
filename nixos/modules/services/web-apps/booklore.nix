{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.booklore;
in
{
  options = {
    services.booklore = {
      enable = lib.mkEnableOption "Booklore";

      package = lib.mkPackageOption pkgs "booklore" { };

      listen = {
        ip = lib.mkOption {
          type = lib.types.str;
          default = "::1";
          description = ''
            IP address that Calibre-Web should listen on.
          '';
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8083;
          description = ''
            Listen port for Calibre-Web.
          '';
        };
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "calibre-web";
        description = ''
          Where Calibre-Web stores its data.
          Either an absolute path, or the directory name below {file}`/var/lib`.
        '';
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "calibre-web";
        description = "User account under which Calibre-Web runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "calibre-web";
        description = "Group account under which Calibre-Web runs.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Open ports in the firewall for the server.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.booklore = {
      isSystemUser = true;
      group = "booklore";
    };
    users.groups.booklore = { };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb_118;
      ensureDatabases = [ "booklore" ];
      ensureUsers = [
        {
          name = "booklore";
          ensurePermissions = {
            "booklore.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    systemd.services.booklore = {
        description = "Web app for browsing, reading and downloading eBooks stored in a Calibre database";
        after = [
          "network.target"
          "mysql.service"
        ];
        requires = [ "mysql.service" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          # DATABASE_URL = "jdbc:mariadb://booklore@%%2Frun%%2Fmysqld%%2Fmysqld.sock/booklore";
          # DATABASE_URL = "jdbc:mariadb://localhost:3306/booklore?localSocket=/run/mysqld/mysqld.sock";
          # DATABASE_URL = "jdbc:mariadb://localhost:3306/booklore";
          # DATABASE_URL = "jdbc:mariadb://localhost/booklore";
          DATABASE_URL = "jdbc:mariadb://127.0.0.1:3306/booklore";

          DATABASE_USERNAME = "booklore";
          DATABASE_PASSWORD = "booklore";
        };

        serviceConfig = {
          Type = "exec";
          #User = cfg.user;
          #Group = cfg.group;
          User = "booklore";
          Group = "booklore";

          PermissionsStartOnly = false;
          ExecStartPre = "+${pkgs.writeShellScript "librenms-db-init" (''
            echo "SET old_passwords=0; ALTER USER 'booklore'@'localhost' IDENTIFIED BY 'booklore';" | ${lib.getExe' config.services.mysql.package "mariadb"} --socket=/run/mysqld/mysqld.sock
          '')}";
          # echo "ALTER USER 'booklore'@'localhost' IDENTIFIED VIA unix_socket;" | ${lib.getExe' config.services.mysql.package "mariadb"} --socket=/run/mysqld/mysqld.sock

          ExecStart = "${lib.getExe cfg.package} --app.bookdrop-folder=/var/lib/booklore/bookdrop --app.path-config=/var/lib/booklore/config";
          StateDirectory = "booklore";
          # -Dspring.datasource.url=jdbc:mariadb://localhost/booklore -Dspring.datasource.username=booklore -Dspring.datasource.password=";
          # Restart = "on-failure";
        };
      };

    #networking.firewall = mkIf cfg.openFirewall {
    #  allowedTCPPorts = [ cfg.listen.port ];
    #};

    #users.users = mkIf (cfg.user == "calibre-web") {
    #  calibre-web = {
    #    isSystemUser = true;
    #    group = cfg.group;
    #  };
    #};

    #users.groups = mkIf (cfg.group == "calibre-web") {
    #  calibre-web = { };
    #};
  };

  meta.maintainers = with lib.maintainers; [ tmarkus ];
}
