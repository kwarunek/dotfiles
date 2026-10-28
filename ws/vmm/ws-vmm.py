#!/usr/bin/env python3
"""Spawn a throwaway workspace as a Cloud Hypervisor VM. Stdlib only.

  ws-vmm.py build [--llm]   turn the podman image into an ext4 rootfs (+ fetch a kernel)
  ws-vmm.py cleanup         remove tap devices and nft tables left behind by crashed runs
  ws-vmm.py [OPTIONS]       boot a VM, same options as ws-container.py

Directories are shared live over virtio-fs (one unprivileged virtiofsd per directory), so
/workspace, -d/-w and the --llm config dirs behave like the podman bind mounts.
"""
import argparse
import importlib.util
import json
import math
import os
import random
import re
import shlex
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request

# Shared options and helpers live in ../container/ws-container.py (not importable by name: dash, other dir).
sys.dont_write_bytecode = True  # no __pycache__ next to the installed scripts
_spec = importlib.util.spec_from_file_location(
    "ws", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "container", "ws-container.py"))
ws = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ws)

VMM_DIR = os.environ.get("WS_VMM_DIR", os.path.join(ws.WS_DIR, "images"))
CH_BIN = os.environ.get("CLOUD_HYPERVISOR", "cloud-hypervisor")
CH_KERNEL = os.environ.get("WS_VMM_KERNEL", os.path.join(VMM_DIR, "vmlinux"))
CH_KERNEL_URL = "https://github.com/cloud-hypervisor/linux/releases/latest/download/"
CH_ARGS = shlex.split(os.environ.get("WS_VMM_ARGS", ""))  # e.g. --landlock
CH_NET = "172.30"  # one /30 per VM out of 172.30.0.0/16
VIRTIOFSD_ARGS = shlex.split(os.environ.get("WS_VIRTIOFSD_ARGS", ""))  # e.g. --sandbox=none
GUEST_UID = int(os.environ.get("WS_GUEST_UID", "1000"))  # uid of the image user

# PID 1 baked into the rootfs: mounts the ws-seed drive and runs the INIT that comes with it,
# so changes to INIT do not need a rootfs rebuild.
INIT_STUB = r"""#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev 2>/dev/null
mount -t tmpfs tmpfs /run
mkdir -p /run/ws-seed
mount -o ro LABEL=ws-seed /run/ws-seed
exec /bin/sh /run/ws-seed/init
"""

# The real init (dash, run by INIT_STUB), reads its per-run settings from the ws-seed drive.
INIT = r"""
mkdir -p /dev/pts /dev/shm
mount -t devpts -o gid=5,mode=620,ptmxmode=666 devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm
mount -t tmpfs -o mode=1777 tmpfs /tmp
mount -t cgroup2 cgroup2 /sys/fs/cgroup 2>/dev/null
. /run/ws-seed/env
user=$(. /etc/ws-image-env; echo "$WS_IMAGE_USER")

hostname "$WS_HOSTNAME"
echo "$WS_HOSTNAME" > /etc/hostname
printf '127.0.0.1 localhost\n127.0.1.1 %s\n::1 localhost\n' "$WS_HOSTNAME" > /etc/hosts
ip link set lo up
if [ -n "$WS_IP" ]; then
    ip addr add "$WS_IP" dev eth0
    ip link set eth0 up
    ip route add default via "$WS_GW"
    rm -f /etc/resolv.conf
    for ns in $WS_DNS; do echo "nameserver $ns"; done > /etc/resolv.conf
fi

uid=$(id -u "$user")
gid=$(id -g "$user")
home=$(getent passwd "$user" | cut -d: -f6)

# lines: TAG MODE PATH
while read -r tag mode path; do
    mkdir -p "$path"
    mount -t virtiofs -o "$mode" "$tag" "$path"
done < /run/ws-seed/mounts

stty -F /dev/hvc0 rows "$WS_ROWS" cols "$WS_COLS" 2>/dev/null
cd /workspace

env -i HOME="$home" USER="$user" LOGNAME="$user" SHELL=/bin/bash TERM="$WS_TERM" \
    sh -c '. /etc/ws-image-env; . /run/ws-seed/user-env; exec "$@"' sh \
    prlimit --nofile=65536:65536 --nproc="$WS_PIDS:$WS_PIDS" \
    setsid -w -c setpriv --reuid="$uid" --regid="$gid" --init-groups --no-new-privs \
    bash -l <>/dev/hvc0 >&0 2>&0

# Stop everything so the shared dirs are flushed and unmounted cleanly.
cd /
kill -TERM -1 2>/dev/null; sleep 1; kill -KILL -1 2>/dev/null
sync
tac /run/ws-seed/mounts | while read -r tag mode path; do umount "$path"; done
mount -o remount,ro /
echo 1 > /proc/sys/kernel/sysrq
dmesg -n 1
# The trigger is asynchronous and PID 1 must not exit before it happens. Start the waiting
# process first: after the trigger the disks go away and nothing can be loaded from them.
sleep 3600 &
# Power off (Cloud Hypervisor exits); a reboot would restart the VM.
echo o > /proc/sysrq-trigger
wait
"""


def die(msg):
    sys.exit(f"ws-vmm: {msg}")


def run(*cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


def sudo(script):
    """Run a privileged shell snippet (network setup/teardown)."""
    cmd = ["sh", "-ec", script]
    if os.geteuid() != 0:
        cmd = ["sudo", *cmd]
    return subprocess.run(cmd).returncode == 0


def mkfs(path, size_mb, label, src=None):
    with open(path, "wb") as f:
        f.truncate(size_mb << 20)
    cmd = ["mkfs.ext4", "-q", "-F", "-L", label]
    if src:
        cmd += ["-d", src]
    run(*cmd, path)


def image_name(llm):
    return "ws-llm" if llm else "ws"


# --- build -------------------------------------------------------------------

def fetch_kernel(path):
    """Kernel built by the Cloud Hypervisor project (virtio-fs, virtio-console, ACPI)."""
    asset = {"x86_64": "vmlinux-x86_64", "aarch64": "Image-arm64"}[os.uname().machine]
    print(f"kernel: {CH_KERNEL_URL}{asset}")
    urllib.request.urlretrieve(CH_KERNEL_URL + asset, path + ".part")
    os.replace(path + ".part", path)


def build(argv):
    p = argparse.ArgumentParser(prog="ws-vmm.py build")
    p.add_argument("--llm", action="store_true", help="build from the ws-llm image")
    p.add_argument("--image", help="podman image (default: localhost/ws or localhost/ws-llm)")
    p.add_argument("--free", type=ws.positive_int, default=4096, metavar="MB",
                   help="free space left in the rootfs (default: 4096)")
    p.add_argument("--kernel", help="use this kernel instead of downloading one")
    args = p.parse_args(argv)

    os.makedirs(VMM_DIR, exist_ok=True)
    if args.kernel:
        shutil.copyfile(args.kernel, CH_KERNEL)
    elif not os.path.exists(CH_KERNEL):
        fetch_kernel(CH_KERNEL)

    image = args.image or f"localhost/{image_name(args.llm)}"
    out = os.path.join(VMM_DIR, image_name(args.llm) + ".ext4")
    cfg = json.loads(run("podman", "image", "inspect", image, capture_output=True, text=True).stdout)[0]["Config"]
    env = "".join(f"export {k}={shlex.quote(v)}\n" for k, _, v in (e.partition("=") for e in cfg.get("Env", [])))
    user = (cfg.get("User") or "root").split(":")[0]

    with tempfile.TemporaryDirectory(dir=VMM_DIR) as tmp:
        files = {"usr/sbin/ws-init": INIT_STUB, "etc/ws-image-env": env + f"export WS_IMAGE_USER={shlex.quote(user)}\n"}
        for name, content in files.items():
            with open(os.path.join(tmp, os.path.basename(name)), "w") as f:
                f.write(content)
            os.chmod(os.path.join(tmp, os.path.basename(name)), 0o755)
        debugfs = "".join(f"rm /{n}\nwrite {tmp}/{os.path.basename(n)} /{n}\nsif /{n} uid 0\nsif /{n} gid 0\n"
                          for n in files)
        with open(os.path.join(tmp, "debugfs"), "w") as f:
            f.write(debugfs)
        # Inside the podman user namespace the image files keep their in-image owners.
        script = f"""
            set -e
            root=$(podman image mount {shlex.quote(image)})
            trap 'podman image unmount {shlex.quote(image)} >/dev/null' EXIT
            size=$(( $(du -sm "$root" | cut -f1) + {args.free} ))
            rm -f {shlex.quote(out)}.part
            truncate -s ${{size}}M {shlex.quote(out)}.part
            mkfs.ext4 -q -F -L ws-root -d "$root" {shlex.quote(out)}.part
            debugfs -w -f {shlex.quote(tmp)}/debugfs {shlex.quote(out)}.part >/dev/null 2>&1
            debugfs -R "cat /etc/ws-image-env" {shlex.quote(out)}.part 2>/dev/null | grep -q WS_IMAGE_USER
            mv {shlex.quote(out)}.part {shlex.quote(out)}
        """
        print(f"building {out} from {image}")
        run("podman", "unshare", "sh", "-c", script)
    print(f"done, user {user}, kernel {CH_KERNEL}")


# --- run ---------------------------------------------------------------------

def pick_subnet():
    used = subprocess.run(["ip", "-o", "-4", "addr"], capture_output=True, text=True).stdout
    while True:
        n = random.randrange(1 << 14) * 4
        host, guest = f"{CH_NET}.{n >> 8}.{(n & 255) + 1}", f"{CH_NET}.{n >> 8}.{(n & 255) + 2}"
        if f" {host}/" not in used:
            return host, guest


def host_dns():
    try:
        with open("/etc/resolv.conf") as f:
            ns = [l.split()[1] for l in f if l.startswith("nameserver") and len(l.split()) > 1]
    except OSError:
        ns = []
    ns = [n for n in ns if ":" not in n and not n.startswith("127.")]
    return os.environ.get("WS_VMM_DNS", " ".join(ns) or "1.1.1.1 9.9.9.9")


def net_up(tap, host, guest):
    table = f"ws_{tap}"
    return sudo(f"""
        ip tuntap add dev {tap} mode tap user {os.getuid()}
        ip addr add {host}/30 dev {tap}
        ip link set {tap} up
        sysctl -qw net.ipv4.ip_forward=1
        nft -f - <<EOF
table ip {table} {{
    chain postrouting {{
        type nat hook postrouting priority srcnat;
        ip saddr {guest} oifname != "{tap}" masquerade
    }}
    chain forward {{
        type filter hook forward priority filter;
        iifname "{tap}" accept
        oifname "{tap}" ct state established,related accept
    }}
    chain input {{
        type filter hook input priority filter;
        iifname "{tap}" ct state established,related accept
        iifname "{tap}" drop
    }}
}}
EOF
    """)


def net_down(tap):
    sudo(f"nft delete table ip ws_{tap} 2>/dev/null || true; ip link del {tap} 2>/dev/null || true")


def cleanup():
    """Find tap devices and nft tables of VMs that are gone, remove them after confirmation."""
    links = subprocess.run(["ip", "-o", "link", "show"], capture_output=True, text=True).stdout
    taps = {m[1]: "NO-CARRIER" in m[2] for m in re.finditer(r"^\d+: (ws[0-9a-f]{8})[@:].*?<([^>]*)>", links, re.M)}
    cmd = ["nft", "list", "tables", "ip"]
    if os.geteuid() != 0:
        cmd = ["sudo", *cmd]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    tables = re.findall(r"^table ip ws_(ws[0-9a-f]{8})$", out, re.M)

    # A tap of a running VM has a carrier (cloud-hypervisor holds it open).
    orphan_taps = sorted(t for t, no_carrier in taps.items() if no_carrier)
    orphan_tables = sorted(t for t in tables if t not in taps or taps[t])
    for t in sorted(set(taps) - set(orphan_taps)):
        print(f"in use: link {t}")
    if not orphan_taps and not orphan_tables:
        print("nothing to clean up")
        return
    for t in orphan_taps:
        print(f"orphaned: link {t}")
    for t in orphan_tables:
        print(f"orphaned: nft table ip ws_{t}")
    if input("remove them? [y/N] ").strip().lower() != "y":
        return
    script = "".join(f"nft delete table ip ws_{t}\n" for t in orphan_tables)
    script += "".join(f"ip link del {t}\n" for t in orphan_taps)
    if not sudo(script):
        die("cleanup failed")
    print("removed")


def forward_port(port, guest):
    """127.0.0.1:port -> guest:port, the counterpart of `-p 127.0.0.1:port:port`."""
    def pipe(a, b):
        try:
            while data := a.recv(65536):
                b.sendall(data)
        except OSError:
            pass
        finally:
            for s in (a, b):
                try:
                    s.shutdown(socket.SHUT_RDWR)
                except OSError:
                    pass

    def handle(client):
        try:
            upstream = socket.create_connection((guest, port), timeout=5)
            upstream.settimeout(None)
        except OSError:
            client.close()
            return
        threading.Thread(target=pipe, args=(client, upstream), daemon=True).start()
        pipe(upstream, client)
        client.close()
        upstream.close()

    srv = socket.create_server(("127.0.0.1", port))

    def accept():
        while True:
            client, _ = srv.accept()
            threading.Thread(target=handle, args=(client,), daemon=True).start()

    threading.Thread(target=accept, daemon=True).start()


def make_seed(vm, env, user_env, mounts):
    """The ws-seed drive read by INIT: settings, user env, (tag, mode, path) mounts and INIT itself."""
    seed = os.path.join(vm, "seed")
    os.mkdir(seed)
    with open(os.path.join(seed, "env"), "w") as f:
        f.writelines(f"{k}={shlex.quote(str(v))}\n" for k, v in env.items())
    with open(os.path.join(seed, "user-env"), "w") as f:
        f.writelines(f"export {k}={shlex.quote(v)}\n" for k, v in user_env.items())
    with open(os.path.join(seed, "mounts"), "w") as f:
        f.writelines(" ".join(m) + "\n" for m in mounts)
    with open(os.path.join(seed, "init"), "w") as f:
        f.write(INIT)
    mkfs(seed + ".ext4", 8, "ws-seed", seed)
    return seed + ".ext4"


def find_virtiofsd():
    for path in (os.environ.get("VIRTIOFSD"), shutil.which("virtiofsd"),
                 "/usr/libexec/virtiofsd", "/usr/lib/qemu/virtiofsd"):
        if path and os.access(path, os.X_OK):
            return path
    die("virtiofsd not found (apt install virtiofsd, or set VIRTIOFSD)")


def start_virtiofsd(binary, vm, tag, src, mode):
    sock = os.path.join(vm, f"{tag}.sock")
    cmd = [binary, f"--socket-path={sock}", f"--shared-dir={src}", "--cache=auto", *VIRTIOFSD_ARGS]
    if mode == "ro":
        cmd.append("--readonly")
    if os.getuid() != GUEST_UID:
        # Files of the host user show up as owned by the image user and vice versa.
        cmd += [f"--translate-uid=map:{GUEST_UID}:{os.getuid()}:1",
                f"--translate-gid=map:{GUEST_UID}:{os.getgid()}:1"]
    log = open(os.path.join(vm, f"virtiofsd-{tag}.log"), "w")
    proc = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=log, stderr=log)
    for _ in range(100):
        if os.path.exists(sock):
            return proc, sock
        if proc.poll() is not None:
            break
        time.sleep(0.05)
    with open(log.name) as f:
        die(f"virtiofsd for {src} failed:\n{f.read()}")


def main():
    if sys.argv[1:2] == ["build"]:
        return build(sys.argv[2:])
    if sys.argv[1:2] == ["cleanup"]:
        return cleanup()

    args = ws.build_parser("ws-vmm.py").parse_args()

    rootfs = os.path.join(VMM_DIR, image_name(args.llm) + ".ext4")
    for path, hint in ((rootfs, f"run: ws -t vmm build{' --llm' if args.llm else ''}"),
                       (CH_KERNEL, "run: ws -t vmm build"),
                       ("/dev/kvm", "KVM is not available")):
        if not os.path.exists(path):
            die(f"{path} missing, {hint}")
    if not shutil.which(CH_BIN):
        die(f"{CH_BIN} not found in PATH (or set CLOUD_HYPERVISOR)")
    virtiofsd = find_virtiofsd()

    port = ws.free_port()
    name = ws.random_name()
    workspace = os.path.join(ws.WORKSPACES_DIR, name)
    os.makedirs(workspace, exist_ok=True)
    vm = tempfile.mkdtemp(prefix=f".{name}.", dir=ws.WORKSPACES_DIR)
    tap = None
    daemons = []

    try:
        root = os.path.join(vm, "root.ext4")
        run("cp", "--reflink=auto", "--sparse=always", rootfs, root)

        # (virtiofs tag, host dir, mode, guest path)
        shares = [("ws-work", workspace, "rw", "/workspace")]
        if args.dir:
            d = os.path.realpath(args.dir)
            shares.append(("ws-mnt", d, "rw" if args.rw else "ro", f"/mnt{d}"))
        user_env = {}
        if args.llm:
            if args.no_net:
                print("warning: -x disables networking, the agents will not be able to authenticate",
                      file=sys.stderr)
            home = os.path.expanduser("~")
            for i, d in enumerate(ws.LLM_DIRS):
                if os.path.isdir(os.path.join(home, d)):
                    shares.append((f"ws-llm{i}", os.path.join(home, d), "rw", f"{ws.WS_HOME_IN}/{d}"))
            user_env["CLAUDE_CONFIG_DIR"] = f"{ws.WS_HOME_IN}/{ws.WS_CLAUDE_CONFIG_DIR_NAME}"
            user_env.update({v: os.environ[v] for v in ws.LLM_ENV if os.environ.get(v)})
            print(f"llm: host configs mounted rw under {ws.WS_HOME_IN}")

        fs_args = []
        for tag, src, mode, _ in shares:
            proc, sock = start_virtiofsd(virtiofsd, vm, tag, src, mode)
            daemons.append(proc)
            fs_args.append(f"tag={tag},socket={sock}")

        cols, rows = shutil.get_terminal_size()
        seed_env = {
            "WS_HOSTNAME": name, "WS_PIDS": args.pids, "WS_ROWS": rows, "WS_COLS": cols,
            "WS_TERM": os.environ.get("TERM", "xterm"),
        }
        net_args = []
        if not args.no_net:
            host, guest = pick_subnet()
            tap = "ws" + os.urandom(4).hex()
            if not net_up(tap, host, guest):
                die("network setup failed")
            seed_env.update(WS_IP=f"{guest}/30", WS_GW=host, WS_DNS=host_dns())
            mac = "06:00:" + ":".join(f"{int(x):02x}" for x in guest.split("."))
            net_args = ["--net", f"tap={tap},mac={mac}"]
            forward_port(port, guest)

        seed = make_seed(vm, seed_env, user_env, [(tag, mode, path) for tag, _, mode, path in shares])

        cmd = [
            CH_BIN,
            "--kernel", CH_KERNEL,
            "--cmdline", "console=hvc0 root=/dev/vda rw quiet init=/usr/sbin/ws-init",
            "--cpus", f"boot={math.ceil(args.cpu / 1000)}",
            # virtio-fs (vhost-user) needs guest memory shared with virtiofsd.
            "--memory", f"size={args.mem}M,shared=on",
            "--disk", f"path={root},image_type=raw", f"path={seed},image_type=raw,readonly=on",
            "--fs", *fs_args,
            *net_args,
            "--console", "tty", "--serial", "off",
            "--log-file", os.path.join(vm, "cloud-hypervisor.log"),
            *CH_ARGS,
        ]
        print(f"port {port} {workspace} mounted in /workspace", flush=True)
        res = subprocess.run(cmd)
        subprocess.run(["stty", "sane"], stderr=subprocess.DEVNULL)
        if res.returncode:
            # The VM dir is removed below, show the logs while they exist.
            for log in sorted(f for f in os.listdir(vm) if f.endswith(".log")):
                with open(os.path.join(vm, log)) as f:
                    if content := f.read().strip():
                        print(f"--- {log}\n{content[-4000:]}", file=sys.stderr)
    finally:
        for proc in daemons:
            proc.terminate()
        for proc in daemons:
            try:
                proc.wait(5)
            except subprocess.TimeoutExpired:
                proc.kill()
        if tap:
            net_down(tap)
        shutil.rmtree(vm, ignore_errors=True)


if __name__ == "__main__":
    main()
