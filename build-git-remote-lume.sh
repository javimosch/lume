#!/bin/sh
set -e
cd "$(dirname "$0")"
machin encode src/git-remote-lume/util.src src/git-remote-lume/convert.src src/git-remote-lume/main.src > git-remote-lume.mfl
machin build git-remote-lume.mfl -o git-remote-lume
chmod +x git-remote-lume
