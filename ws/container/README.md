# Container Workspace

Throwaway "workspace" sandbox in a podman container, started with `ws-container.py`
(Python 3, no dependencies outside the stdlib).

## Install

The scripts and VM images live in `$WS_DIR` (default `~/ws`), the throwaway workspaces
in `$WS_WORKSPACES_DIR` (default `/tmp/ws-workspaces`).

```
$WS_DIR/
├── bin/ws          entry point, `ws [-t container|vmm] ...`
├── completion/     bash completion for `ws`
├── container/      ws-container.py, Dockerfiles (this directory)
├── vmm/            ws-vmm.py
└── images/         VM rootfs + kernel, made by `ws -t vmm build` (content git-ignored)
```

Copy the contents of `ws/` there and link the entry point and its completion:

```bash
mkdir -p ~/ws ~/.local/bin ~/.local/share/bash-completion/completions
cp -r ws/. ~/ws/
ln -sf ~/ws/bin/ws ~/.local/bin/ws
ln -sf ~/ws/completion/ws.bash ~/.local/share/bash-completion/completions/ws
```

`~/.local/bin` is added to `PATH` by Debian's `~/.profile` when it exists (log in again after creating it).
The completion is loaded automatically by the `bash-completion` package (`sudo apt-get install bash-completion`
if it is missing); without it, add `source ~/ws/completion/ws.bash` to `~/.bashrc`.

`ws` runs `$WS_DIR/<type>/ws-<type>.py` and passes all other arguments through: `ws [OPTIONS]`
(or `ws -t container`) for the container, `ws -t vmm [OPTIONS]` for the VM variant
([../vmm/README.md](../vmm/README.md)).

## Build

```bash
podman build --progress=plain --pull --no-cache --build-arg USERNAME=kwarunek -t ws base
podman build --progress=plain --no-cache --build-arg USERNAME=kwarunek -t ws-llm llm
```

## Run

`ws -h` lists all options. Every run gets a random name, `$WS_WORKSPACES_DIR/<name>` (default
`/tmp/ws-workspaces`) is mounted as `/workspace` and stays there after the run. `CONTAINER_ENGINE` (default `podman`) selects the engine.

```bash
ws [-d DIR [-w]] [-x] [--llm] [--cpu M] [--mem MB] [--pids N]
```

Mounts:
- always: `$WS_WORKSPACES_DIR/<name>` -> `/workspace` (rw)
- `-d DIR`: `DIR` -> `/mnt/DIR` (ro, rw with `-w`)
- `--llm` (uses the `ws-llm` image), each only if it exists on the host, rw:
  - `~/.claude-ws` -> `~/.claude-ws` (`CLAUDE_CONFIG_DIR` points to it)
  - `~/.codex` -> `~/.codex`
  - `~/.copilot` -> `~/.copilot`

With `--llm` these env variables are passed through when set:
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GITHUB_TOKEN`, `GH_TOKEN`.
