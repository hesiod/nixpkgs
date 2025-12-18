{ lib, ... }:

let
  port = 3142;
  defaultPort = 8083;
in
{
  name = "booklore";
  meta.maintainers = with lib.maintainers; [ pborzenkov ];
  interactive.sshBackdoor.enable = true;

  # enableDebugHook = true;

  nodes = {
    customized =
      { pkgs, ... }:
      {

        services.booklore = {
          enable = true;
          listen.port = port;
          options = {
            calibreLibrary = "/tmp/books";
            reverseProxyAuth = {
              enable = true;
              header = "X-User";
            };
          };
        };
        # environment.systemPackages = [ pkgs.calibre ];
      };
  };
  testScript = ''
    start_all()
    customized.wait_for_unit("mysql.service")

    customized.succeed("systemctl restart mysql.service")
    customized.systemctl("start booklore.service")
    customized.wait_for_unit("booklore.service")
    '';
#    customized.shell_interact()
  # customized.wait_for_open_port(${toString port})
  #   customized.succeed(
  #      "curl --fail -H X-User:admin 'http://localhost:${toString port}' | grep test-book"
  # )

}
