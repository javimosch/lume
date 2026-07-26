#!/bin/sh
set -e
machin encode src/core.src src/index.src src/refs.src src/worktree.src src/status.src src/commands.src src/main.src > lume.mfl
machin build lume.mfl -o lume
echo "built ./lume"
