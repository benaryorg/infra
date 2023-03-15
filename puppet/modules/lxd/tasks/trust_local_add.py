#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 lxd

import json
import sys
import subprocess

def token_command(remote, token):
	return [
		"lxc",
		"remote",
		"add",
		"--accept-certificate",
		"--auth-type",
		"tls",
		"--password",
		token,
		remote,
	]

config = json.load(sys.stdin)

tokens = config["tokens"]

for remote, token in tokens.items():
	subprocess.run(token_command(remote, token), capture_output=True).check_returncode()

