{ lib, ... }:
{
  name = "bichon";
  meta = {
    maintainers = with lib.maintainers; [ tmarkus ];
  };

  nodes = {
    bichon =
      { pkgs, ... }:
      {
        services.bichon = {
          enable = true;
          encryptPasswordFile = pkgs.writeText "bichon-encrypt-password" "NIXOS-TEST-PASSWORD";
          settings.BICHON_BIND_IP = "127.0.0.1";
        };
      };
  };

  testScript = ''
    bichon.start()
    bichon.wait_for_unit("multi-user.target")
    bichon.wait_for_unit("bichon.service")
    bichon.wait_for_open_port(15630)
    bichon.succeed('curl -v http://127.0.0.1:15630')
    out = bichon.succeed('systemctl cat bichon.service')
    print(out)
  '';
}
