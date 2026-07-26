# lume documentation

`lume` is a minimal, content-addressed VCS that feels like git but emits JSON for every command. It is written in MFL (machin) and compiles to a single native binary.

## goals

- **agent-first**: every command prints machine-readable JSON; no interactive prompts.
- **tiny**: one binary, SQLite for the index, SHA-256 for object identity.
- **clean room**: inspired by the *concept* of Lit, but implemented from scratch.
- **machin dogfood**: exercises MFL file I/O, SQLite, JSON, and the HTTP-less CLI path.

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

- No network protocol (no push/pull/clone over the wire).
- No merge / rebase / diff implementation yet.
- File type detection uses `find`/`test` via `exec` (Linux-oriented).
- Author name is taken from `LUME_AUTHOR` or `USER` env.
