# AGENTS.md for lume

## orientation

`lume` is a machin/MFL project. Source lives in `src/*.src`, gets composed into `lume.mfl` by `machin encode`, and compiles to a native `lume` binary. The canonical build command is `./build.sh`.

## cross-link

- Parent toolchain: `~/ai/machin`
- Language catalog: run `machin guide` (or `machin guide --skill backend`)
- GitHub remote: `git@github.com:javimosch/lume.git`
- This project should be listed in [awesome-machin](https://github.com/javimosch/awesome-machin) once public.

## code conventions

- Write loose Go-like `.src` text; run `machin encode` to mint canonical `lume.mfl`.
- Keep source files under 500 LOC.
- Commands emit JSON on stdout. Errors are JSON + non-zero exit.
- No `s[i:j]` string slicing; use `substr(s, start, end)` and `charat(s, i)`.
- No `[]T{value}` literals; use `append([]T{}, value)`.
- Use `make(map[K]V)` and assign keys; map literals are not supported.

## testing

After building, run a smoke test in a throw-away directory:

```sh
mkdir /tmp/lume-smoke && cd /tmp/lume-smoke
~/ai/lume/lume init
echo "a" > a.txt
~/ai/lume/lume add .
~/ai/lume/lume commit -m "first"
~/ai/lume/lume status
```

For network smoke tests, start a server in one directory and push/clone from another:

```sh
mkdir /tmp/lume-server && cd /tmp/lume-server
~/ai/lume/lume init
~/ai/lume/lume add .
~/ai/lume/lume commit -m "srv"
~/ai/lume/lume serve 8788 &

mkdir /tmp/lume-client && cd /tmp/lume-client
~/ai/lume/lume init
echo "hello" > a.txt
~/ai/lume/lume add . && ~/ai/lume/lume commit -m "client"
~/ai/lume/lume push http://localhost:8788 main
~/ai/lume/lume clone http://localhost:8788 /tmp/lume-copy main
```

## architecture

- `core.src`   — object model, SHA-256 object store, `WriteBlob` fast path for blob JSON
- `index.src`  — line-delimited (`index.lst`) staging area, batch writes
- `refs.src`   — HEAD, branches, ref resolution
- `worktree.src` — working-tree scanning via `find`/`test`
- `status.src` — compare HEAD tree, index, and working tree
- `commands.src` — init, add, commit, status, log, branch, checkout, show
- `server.src` — raw HTTP object server for push/pull/clone
- `remote.src` — push, pull, clone client protocol
- `main.src`   — CLI dispatch
