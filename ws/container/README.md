# Container Workspace

Container based "workspace", started with the `ws` bash function (`.bash_functions.d/ws.sh`).

## Build

```bash
podman build --progress=plain --pull --no-cache --build-arg USERNAME=kwarunek -t ws base
podman build --progress=plain --no-cache --build-arg USERNAME=kwarunek -t ws-llm llm
```

## Run

`ws -h` lists all options. Every run gets a random name, `$WS_DIR/<name>` (default `/tmp/ws`)
is mounted as `/workspace`.

Mounts:
- always: `$WS_DIR/<name>` -> `/workspace` (rw)
- `-d DIR`: `DIR` -> `/mnt/DIR` (ro, rw with `-w`)
- `--llm` (uses the `ws-llm` image), each only if it exists on the host, rw:
  - `~/.claude-ws` -> `~/.claude-ws` (`CLAUDE_CONFIG_DIR` points to it)
  - `~/.codex` -> `~/.codex`
  - `~/.copilot` -> `~/.copilot`

With `--llm` these env variables are passed through when set:
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GITHUB_TOKEN`, `GH_TOKEN`.
