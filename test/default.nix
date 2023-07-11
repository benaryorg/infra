{ nixpkgs, pkgs, colmena, colmenaConfig, ... }:
let
    rawNodes = builtins.removeAttrs colmenaConfig [ "meta" "defaults" ];
    mapNode = newargs: value: ((colmenaConfig.defaults newargs) // { config = (value newargs); });
    nodes = builtins.mapAttrs (name: value: args: mapNode ({ inherit name pkgs; nodes = []; } // args) value) rawNodes;
  in
    {
      test-kexec = nixpkgs.lib.nixos.runTest
      {
        hostPkgs = pkgs;
        name = "kexec service test";
        machine = nodes."kexec.example.com";

        testScript =
        ''
          machine.wait_for_unit("default.target")
          print(machine.execute("ip a")[1])
          print(machine.execute("ip l")[1])
          print(machine.execute("ip r")[1])
          print(machine.execute("ip -6 r")[1])
          print(machine.execute("cat /etc/resolv.conf")[1])
          print(machine.execute("sed -i -E 's#10.0.2.3#10.0.2.2#g' /etc/resolv.conf")[1])
          print(machine.execute("cat /etc/resolv.conf")[1])
          print(machine.execute("ping -c 2 10.0.2.2")[1])
          machine.succeed("curl -vs https://ip.syseleven.de")
        '';
      };
    }
