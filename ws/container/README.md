# Container Workspace

Container based "workspace" .

## Build

```bash
podman build --progress=plain --pull --no-cache --build-arg USERNAME=kwarunek -t ws ws
podman build --progress=plain --no-cache --build-arg USERNAME=kwarunek -t llm llm
```
