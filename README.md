# lume

A tiny, agent-friendly, git-like version control system built in [machin/MFL](https://github.com/javimosch/machin). Inspired by the *idea* of Lit (JSON-first, agent-native), but written from scratch to actually work and stay small.

See [docs/README.md](docs/README.md) for full documentation and [docs/AGENTS.md](docs/AGENTS.md) for agent orientation.

```sh
./build.sh
./lume init
./lume add .
./lume commit -m "first"
```

Push/pull/clone over HTTP are also supported:

```sh
./lume serve 8788                          # start object server in another repo
./lume push http://host:8788 main          # upload current branch
./lume pull http://host:8788 main          # fast-forward from remote
./lume clone http://host:8788 mycopy main  # clone a remote repo
```
