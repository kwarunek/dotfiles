#!/usr/bin/env python3
"""Spawn a throwaway workspace container (podman/docker). Stdlib only."""
import argparse
import os
import random
import socket
import sys

# Scripts and VM images; workspaces are throwaway and live in /tmp by default.
WS_DIR = os.environ.get("WS_DIR", os.path.expanduser("~/ws"))
WORKSPACES_DIR = os.environ.get("WS_WORKSPACES_DIR", "/tmp/ws-workspaces")
CONTAINER_ENGINE = os.environ.get("CONTAINER_ENGINE", "podman")
WS_HOME_IN = f"/home/{os.environ.get('USER', 'user')}"
WS_CLAUDE_CONFIG_DIR_NAME = ".claude-ws"
LLM_DIRS = (WS_CLAUDE_CONFIG_DIR_NAME, ".codex", ".copilot")
LLM_ENV = ("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GITHUB_TOKEN", "GH_TOKEN")

COLORS = ("amber", "azure", "beige", "black", "blue", "bronze", "brown", "coral", "crimson",
          "cyan", "gold", "gray", "green", "indigo", "ivory", "jade", "khaki", "lime",
          "magenta", "maroon", "navy", "olive", "orange", "pink", "plum", "purple", "red",
          "ruby", "salmon", "silver", "tan", "teal", "violet", "white", "yellow")
ANIMALS = ("badger", "bat", "bear", "beaver", "bison", "camel", "cat", "cobra", "crane",
           "crow", "deer", "dingo", "eagle", "eel", "falcon", "ferret", "fox", "frog",
           "gecko", "goat", "hare", "hawk", "heron", "ibis", "koala", "lemur", "lynx",
           "marten", "mole", "moose", "newt", "otter", "owl", "panda", "puma", "raven",
           "seal", "shark", "sloth", "stoat", "swan", "tapir", "tiger", "toad", "viper",
           "walrus", "wolf", "wombat", "yak", "zebra")


def positive_int(value):
    try:
        n = int(value)
    except ValueError:
        n = 0
    if n <= 0:
        raise argparse.ArgumentTypeError("expects a positive integer")
    return n


def build_parser(prog="ws"):
    p = argparse.ArgumentParser(prog=prog)
    p.add_argument("-d", dest="dir", metavar="DIR",
                   help="mount directory DIR to /mnt/DIR inside the sandbox (read-only)")
    p.add_argument("-w", dest="rw", action="store_true",
                   help="mount the -d directory read-write (default: read-only)")
    p.add_argument("--cpu", type=positive_int, default=1500, metavar="MILLICORES",
                   help="CPU limit in millicores (default: 1500)")
    p.add_argument("--mem", type=positive_int, default=1024, metavar="MB",
                   help="memory limit in MB (default: 1024)")
    p.add_argument("--pids", type=positive_int, default=256, metavar="N",
                   help="max processes/threads (default: 256)")
    p.add_argument("-x", dest="no_net", action="store_true", help="run without network")
    p.add_argument("--llm", action="store_true",
                   help=f"use the ws-llm image and mount ~/{WS_CLAUDE_CONFIG_DIR_NAME}, ~/.codex, "
                        "~/.copilot read-write into the image's own $HOME (shared history + credentials)")
    return p


def random_name():
    return f"{random.choice(COLORS)}-{random.choice(ANIMALS)}"


def free_port():
    while True:
        port = random.randint(10000, 65000)
        with socket.socket() as s:
            try:
                s.bind(("127.0.0.1", port))
                return port
            except OSError:
                pass


def run(engine=CONTAINER_ENGINE, extra=(), prog="ws", check=None):
    """Parse the ws options and exec `engine run`; extra flags go before the image."""
    args = build_parser(prog).parse_args()
    if check:
        check()
    port = free_port()
    name = random_name()
    workspace = os.path.join(WORKSPACES_DIR, name)
    os.makedirs(workspace, exist_ok=True)

    mount_args = []
    if args.dir:
        d = os.path.realpath(args.dir)
        mount_args += ["-v", f"{d}:/mnt{d}:{'rw' if args.rw else 'ro'}"]
    mount_args += ["-v", f"{workspace}:/workspace"]

    podman = engine == "podman"
    image = "localhost/ws" if podman else "ws"
    engine_args = ["--pull=never", "--userns=keep-id"] if podman else []

    llm_args = []
    if args.llm:
        image = "ws-llm"
        if args.no_net:
            print("warning: -x disables networking, the agents will not be able to authenticate",
                  file=sys.stderr)
        home = os.path.expanduser("~")
        for d in LLM_DIRS:
            if os.path.isdir(os.path.join(home, d)):
                llm_args += ["-v", f"{home}/{d}:{WS_HOME_IN}/{d}"]
        llm_args += ["-e", f"CLAUDE_CONFIG_DIR={WS_HOME_IN}/{WS_CLAUDE_CONFIG_DIR_NAME}"]
        llm_args += [a for v in LLM_ENV if os.environ.get(v) for a in ("-e", v)]
        print(f"llm: host configs mounted rw under {WS_HOME_IN}")

    if args.no_net:
        network_args = ["--network", "none"]
    elif podman:
        network_args = ["--network=slirp4netns:allow_host_loopback=false"]
    else:
        network_args = []

    print(f"port {port} {workspace} mounted in /workspace")

    cmd = [
        engine, "run", "-it", "-h", name, "--name", name,
        "--cap-drop=ALL",
        "--security-opt=no-new-privileges:true",
        f"--pids-limit={args.pids}",
        "--ulimit", "nofile=65536:65536",
        f"--memory={args.mem}m", f"--cpus={args.cpu / 1000:.3f}",
        "--user", f"{os.getuid()}:{os.getgid()}", "--rm",
        *engine_args,
        "-p", f"127.0.0.1:{port}:{port}",
        *network_args, *mount_args, *llm_args,
        *(extra(args) if callable(extra) else extra),
        image,
    ]
    sys.stdout.flush()
    os.execvp(cmd[0], cmd)


if __name__ == "__main__":
    run()
