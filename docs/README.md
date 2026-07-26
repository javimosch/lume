# lume documentation

`lume` is a minimal, content-addressed VCS that feels like git but emits JSON for every command. It is written in MFL (machin) and compiles to a single native binary.

## goals

- **agent-first**: every command prints machine-readable JSON; no interactive prompts.
- **tiny**: one binary, SQLite for the index, SHA-256 for object identity.
- **clean room**: inspired by the *concept* of Lit, but implemented from scratch.
- **machin dogfood**: exercises MFL file I/O, SQLite, JSON, HTTP, and the CLI path.

## build

```sh
./build.sh
```

Requires `machin` on PATH and a C compiler (`cc`).

## commands

| command | description | example |
|---|---|---|
| `init` | create a `.lume` repository | `./lume init` |
| `add <path>` | stage files or directories | `./lume add .` |
| `status` | show staged / modified / untracked / deleted | `./lume status` |
| `commit -m <msg>` | create a commit from the index | `./lume commit -m "fix"` |
| `log` | list commits from HEAD to root | `./lume log` |
| `branch [name]` | list or create branches | `./lume branch feat` |
| `checkout <target>` | switch branch or commit (short hashes work) | `./lume checkout 4b56b10d` |
| `show <target>` | show object JSON for a commit/tree/blob | `./lume show main` |
| `cat-file <hash>` | dump raw object JSON | `./lume cat-file <hash>` |
| `hash-object <path>` | compute blob hash without storing | `./lume hash-object file.txt` |
| `serve [port]` | start an HTTP object server | `./lume serve 8788` |
| `push <remote> [ref]` | upload a ref and its objects | `./lume push http://host:8788 main` |
| `pull <remote> [ref]` | fast-forward from a remote ref | `./lume pull http://host:8788 main` |
| `clone <remote> [dir] [ref]` | clone a remote repository | `./lume clone http://host:8788 mycopy main` |

## network protocol

`serve` runs a tiny HTTP server on the given port. Endpoints:

- `GET /` or `/info` — repository metadata JSON
- `GET /refs` — list branch names and hashes
- `GET /refs/<name>` — text of the commit hash for a branch
- `POST /refs/<name>` — update a branch to the hash in the request body
- `GET /objects/<hash>` — raw object JSON
- `POST /objects/<hash>` — store raw object JSON

`push` walks all objects reachable from a ref and uploads any the remote does not already have, then updates the remote ref. `pull`/`clone` fetch the remote ref, its tree, and all blobs, then rebuild the working tree and SQLite index.

## storage layout

```
.lume/
  HEAD              # "ref: refs/heads/main" or a commit hash
  index             # SQLite staging area
  config            # user info
  refs/heads/       # branch files
  objects/xx/yyyy.. # JSON objects (blob, tree, commit)
```

Objects are JSON and addressed by `sha256(json(object))`.

## limitations

- No merge / rebase / diff implementation yet.
- File type detection uses `find`/`test` via `exec` (Linux-oriented).
- Author name is taken from `LUME_AUTHOR` or `USER` env.
- Push currently overwrites the remote ref (no fast-forward check).
