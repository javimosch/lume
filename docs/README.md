# lume documentation

`lume` is a minimal, content-addressed VCS that feels like git but emits JSON for every command. It is written in MFL (machin) and compiles to a single native binary.

> lume is **git-like, not git-based**. It borrows git's concepts (blob, tree, commit, refs, HEAD) and content-addressed storage, but the implementation, object format, and network protocol are written from scratch in MFL. It does not wrap git, speak the git protocol, or read pack files.

## goals

- **agent-first**: every command prints machine-readable JSON; no interactive prompts.
- **tiny**: one binary, line-delimited staging index, SHA-256 for object identity.
- **clean room**: inspired by the *concept* of [Lit](https://github.com/nervosys/Lit) (JSON-first, agent-native), but implemented from scratch.
- **machin dogfood**: exercises MFL file I/O, JSON, HTTP, and the CLI path.

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

`push` walks all objects reachable from a ref and uploads any the remote does not already have, then updates the remote ref. `pull`/`clone` fetch the remote ref, its tree, and all blobs, then rebuild the working tree and line index.

## benchmarks

Measured on an x86_64 Linux workstation against `/usr/bin/git` 2.34.1, 110 small files across `src/` and `docs/`.

| metric | lume | git | note |
|---|---|---|---|
| binary size | 100 KB | 3.7 MB | lume is ~36× smaller |
| `init` | ~4 ms | ~2 ms | comparable cold start |
| `add .` (110 files) | ~9 ms | ~9 ms | lume writes loose JSON objects per file |
| `commit -m` | ~6 ms | ~5 ms | |
| `add . && commit` (110 files) | **~15 ms** | ~17 ms | **lume wins** |
| repo metadata size after commit | 466 KB (.lume) | 475 KB (.git) | within 2% |
| `push` 50 files over localhost HTTP | ~0.7 s | — | no pack negotiation; simple object exchange |
| `clone` 50 files over localhost HTTP | ~0.7 s | — | |
| `pull` one new file over localhost HTTP | ~0.9 s | — | |

Why machin? A single, small, self-contained native binary with no runtime, no suite of helper binaries, and no pack-format archaeology. Every command emits JSON by default, and the network protocol is plain HTTP + JSON objects. The staging index is a lightweight line-delimited file, so `add` keeps up with git without the SQLite overhead.

## storage layout

```
.lume/
  HEAD              # "ref: refs/heads/main" or a commit hash
  index.lst         # tab-separated staging index
  config            # user info
  refs/heads/       # branch files
  objects/xx/yyyy.. # JSON objects (blob, tree, commit)
```

Objects are JSON and addressed by `sha256(json(object))`.

## git compatibility

`git-remote-lume` lets you use lume as a git remote. Put `git-remote-lume` on `PATH` (or `~/bin`) and use the `lume::` transport:

```sh
git remote add origin lume::http://rbm21:8788
git push origin main
git clone lume::http://rbm21:8788 mycopy
```

The helper translates git's SHA-1 objects into lume's JSON/SHA-256 objects on the fly. It supports linear history (blob/tree/commit) with recursive directories. Merge commits, tags, and shallow clones are on the roadmap (see `docs/VISION.md`).

## limitations

- No merge / rebase / diff implementation yet.
- File type detection uses `find`/`test` via `exec` (Linux-oriented).
- Author name is taken from `LUME_AUTHOR` or `USER` env.
- Push currently overwrites the remote ref (no fast-forward check).
- `git-remote-lume` is a Phase 2 Python prototype; it will be ported to MFL later.
