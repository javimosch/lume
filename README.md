# lume

A tiny, agent-friendly, **git-like** version control system built in [machin/MFL](https://github.com/javimosch/machin).

> lume is **git-like, not git-based**. It borrows git's vocabulary (blob, tree, commit, refs, HEAD) and the content-addressed object model, but the implementation, storage format, and network protocol are written from scratch in MFL. It does not wrap git, speak the git protocol, or read pack files.

Inspired by the idea of [Lit](https://github.com/nervosys/Lit) (JSON-first, agent-native), but written from scratch to actually work and stay small.

See [docs/README.md](docs/README.md) for full documentation and [docs/AGENTS.md](docs/AGENTS.md) for agent orientation.

## quickstart

```sh
./build.sh
./lume init
./lume add .
./lume commit -m "first"
```

Push/pull/clone over HTTP:

```sh
./lume serve 8788                          # start object server in another repo
./lume push http://host:8788 main          # upload current branch
./lume pull http://host:8788 main          # fast-forward from remote
./lume clone http://host:8788 mycopy main  # clone a remote repo
```

## benchmarks

Measured on an x86_64 Linux workstation against `/usr/bin/git` 2.34.1.

| metric | lume | git | note |
|---|---|---|---|
| binary size | 100 KB | 3.7 MB | lume is ~36× smaller |
| `init` | ~0.02 s | <0.01 s | comparable cold start |
| `add . && commit` (110 small files) | ~1.36 s | ~0.01 s | lume writes loose JSON objects per file; no pack optimization yet |
| repo metadata size after commit | 434 KB (.lume) | 475 KB (.git) | within 10% |
| `push` 50 files over localhost HTTP | ~0.67 s | — | no pack negotiation; simple object exchange |
| `clone` 50 files over localhost HTTP | ~0.66 s | — | |
| `pull` one new file over localhost HTTP | ~0.89 s | — | |

Why build this in machin? It yields a single, small, self-contained native binary with no runtime, no suite of helper binaries, and no pack-format archaeology. Every command emits JSON by default, and the network protocol is plain HTTP + JSON objects. The trade-off is batch throughput until the storage layer is optimized.
