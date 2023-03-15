#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 colmena

import json
import sys
import subprocess

COLMENA_COMMAND = [
  "colmena",
  "eval",
  "-E",
  "config: with config.pkgs; with builtins; with lib; mapAttrs (name: value: value.config.deployment.tags) config.nodes",
]

config = json.load(sys.stdin)

tag = config["tag"]

colmena = subprocess.run(COLMENA_COMMAND, capture_output=True)
colmena.check_returncode()

colmena_inventory = json.loads(colmena.stdout)
inventory = [ { "name": node, "uri": node, } for node, data in colmena_inventory.items() if tag in data ]

result = { "value": inventory }

json.dump(result, sys.stdout)
