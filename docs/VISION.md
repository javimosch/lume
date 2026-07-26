# lume vision: a tiny git-compatible VCS

## North star

lume becomes the smallest self-contained system that can **host a git remote**. A user should be able to:

```sh
git remote add origin lume::http://rbm21:8788/my-repo
git push origin main
git clone lume::http://rbm21:8788/my-repo
```

and have full git history, branches, merge commits, and tags preserved — while lume itself remains a single small binary with no git dependency at runtime.

The object store underneath is still lume's JSON/SHA-256 object model. Git compatibility is provided by a `git-remote-lume` helper that translates between git's SHA-1 packfiles and lume's JSON objects on the fly.

## Why this matters

- lume is already faster and smaller than git for the everyday `add+commit` loop.
- Agents and scripts can use lume's JSON-first CLI for snapshots.
- Humans and existing workflows can keep using `git` when they need history, rebase, merge, and `git push`.
- One tiny server can serve both audiences.

## Phases

### Phase 0 — VISION.md and protocol ground truth

Establish the exact git remote-helper protocol surface and the object translation map. No code yet, only docs and test fixtures.

### Phase 1 — Read-only fetch (clone / pull, done)

`git-remote-lume` supports:

- `capabilities`
- `list`
- `fetch <sha1> <name>`

It downloads a lume branch, converts JSON blobs/trees/commits into git loose objects, and writes them to `.git/objects`. `git clone lume::...` works for linear history with recursive directories.

### Phase 2 — Push (done, Python prototype)

`git-remote-lume` supports:

- `list for-push`
- `push <src>:<dst>`

It reads git objects with `git cat-file` / `git ls-tree`, converts them to lume JSON objects, uploads them to the lume server, and updates the remote ref. The current helper is a Python stdlib prototype that proves the protocol end-to-end; a native MFL port is Phase 5.

### Phase 3 — Merge commits, tags, and shallow clones

- Support multiple parents (merge commits).
- Support annotated and lightweight tags.
- Support shallow fetch (`shallow` and ` deepen` commands).

### Phase 4 — Server-side efficiency

- On the server, keep a loose-object index to avoid re-uploading objects lume already has.
- Add `/have` endpoint for push negotiation.
- Support `git push --force` and ref deletion.

### Phase 5 — Ecosystem polish

- Port `git-remote-lume` from Python to MFL for a single small native helper.
- `lume bundle` and `lume unbundle` for offline git bundles.
- `lume import-git <repo>` to seed a lume server from an existing git repo.
- Documentation and benchmarks against `git clone`/`git push` over HTTP.

## Object translation

### Git → lume

| git object | lume JSON |
|---|---|
| blob (raw bytes) | `{"otype":"blob","data":"<base64>"}` |
| tree | `{"otype":"tree","data":"","entries":[{"mode":"100644","name":"full/path","hash":"<lume-hash>"}, ...]}` (flat list; directories are implicit) |
| commit (Phase 2) | `{"otype":"commit","data":"","entries":[],"tree":"<lume-tree-hash>","parent":"<lume-parent-hash>","author":"Name <email>","timestamp":<unix-sec>,"message":"..."}` (single parent) |
| tag | stored as a lightweight lume ref plus an extra `tag` object if annotated |

Hashes are recomputed: git SHA-1 is used inside git; lume SHA-256 of the JSON is used on the wire.

### lume → git

When fetching, `git-remote-lume` creates git objects with `git hash-object -w --stdin -t <type>` (or `git fast-import` for batches). The git hashes will not match the lume hashes, but the commit graph and file contents are preserved.

## Architecture

```
git client
    |
    v
git-remote-lume  (Python stdlib prototype, MFL port in Phase 5)
    |
    |-- exec git cat-file / git ls-tree / git mktree / git commit-tree
    |
    v
lume HTTP server (rbm21)
    |
    v
.lume/objects (JSON, SHA-256)
```

The remote helper is the only component that understands both formats. The lume server stays unchanged.

## Success criteria

1. `git clone lume::http://rbm21:8788/test-repo` produces a working git repo with the same files as the source.
2. `git push lume::http://rbm21:8788/test-repo main` uploads a new commit and updates the remote ref.
3. After push, `git clone` from the same URL sees the new commit.
4. The native `lume` + MFL `git-remote-lume` helper stay under 200 KB combined (Phase 5 target).
5. No runtime dependency on git on the server; git is only used client-side by the helper.

## Non-goals

- Replace git for interactive use.
- Implement `git merge` or `git rebase` server-side.
- Support signed commits or GPG tags in the first version.
