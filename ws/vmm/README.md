# VM Workspace (Cloud Hypervisor)

`ws-vmm.py` boots the image as a Cloud Hypervisor VM: own kernel, no daemon, runs as your user
(`sudo` only for the tap device). Same options and images as `ws-container.py`
(see [../container/README.md](../container/README.md)). Directories are shared live over virtio-fs, one
unprivileged `virtiofsd` per directory, so `/workspace`, `-d`/`-w` and `--llm` work like the podman mounts.

Installed under `$WS_DIR/vmm` (see [../container/README.md](../container/README.md#install)) and run
through the `ws` command (`~/ws/bin/ws`):

```bash
ws -t vmm build            # rootfs from localhost/ws + Cloud Hypervisor kernel
ws -t vmm build --llm      # rootfs from localhost/ws-llm
ws -t vmm [-d DIR [-w]] [-x] [--llm] [--cpu M] [--mem MB] [--pids N]
ws -t vmm cleanup          # remove tap devices / nft tables left behind by crashed runs
```

Rebuild the rootfs (`build`) after every `podman build`. Differences from the container version:
- `--cpu` is rounded up to whole vCPUs, `--pids` is a process limit (`RLIMIT_NPROC`) for the user inside the VM.
- Every run copies the rootfs (`cp --reflink=auto`, instant on btrfs/xfs, a full copy on ext4).
- The shell runs on the virtio console (`hvc0`). The network is a tap device + nftables NAT and the
  port is forwarded by the script (see [Networking](#networking)).
- Files keep their host owners. When your uid is not 1000 (the image user), virtiofsd maps
  guest uid 1000 to your uid (`--translate-uid`, set `WS_GUEST_UID` if the image user differs).

Environment:
- `CLOUD_HYPERVISOR` - binary (default `cloud-hypervisor` from `PATH`)
- `VIRTIOFSD` - binary (default: `PATH`, then `/usr/libexec/virtiofsd`)
- `WS_DIR` - scripts and images (default `~/ws`)
- `WS_WORKSPACES_DIR` - workspaces, one `<name>/` per run (default `/tmp/ws-workspaces`)
- `WS_VMM_DIR` - rootfs images and kernel (default `$WS_DIR/images`)
- `WS_VMM_KERNEL` - kernel (default `$WS_VMM_DIR/vmlinux`)
- `WS_VMM_ARGS` - extra Cloud Hypervisor flags, e.g. `--landlock`
- `WS_VIRTIOFSD_ARGS` - extra virtiofsd flags, e.g. `--sandbox=none` if your system does not allow
  unprivileged user namespaces (the default sandbox confines virtiofsd to the shared dir)
- `WS_VMM_DNS` - guest nameservers (default: non-loopback ones from the host `/etc/resolv.conf`, else `1.1.1.1 9.9.9.9`)

## Setup on Debian (13 / trixie)

Run once. Steps 2 and 3 need `sudo`, the rest runs as your user.

**1. Check that KVM is available**

```bash
grep -cwE 'vmx|svm' /proc/cpuinfo   # must print > 0 (enable VT-x/AMD-V in BIOS, nested virt on a VM host)
ls -l /dev/kvm                      # must exist: crw-rw---- root kvm
```

**2. Install the dependencies from Debian**

```bash
sudo apt-get update
sudo apt-get install -y podman virtiofsd e2fsprogs iproute2 nftables sudo curl
sudo usermod -aG kvm "$USER"        # then log out and back in
```

| package      | used for                                                         |
|--------------|------------------------------------------------------------------|
| `podman`     | building the images, exporting them into the rootfs              |
| `virtiofsd`  | sharing directories with the VM (installed as `/usr/libexec/virtiofsd`) |
| `e2fsprogs`  | `mkfs.ext4` / `debugfs` for the rootfs and the settings drive    |
| `iproute2`, `nftables`, `sudo` | tap device and NAT for the VM network          |
| `curl`       | downloading Cloud Hypervisor                                     |

**3. Install Cloud Hypervisor** (not packaged in Debian, static binary from GitHub)

```bash
curl -fsSL -o /tmp/cloud-hypervisor \
    https://github.com/cloud-hypervisor/cloud-hypervisor/releases/latest/download/cloud-hypervisor-static
sudo install -m 755 /tmp/cloud-hypervisor /usr/local/bin/cloud-hypervisor
rm /tmp/cloud-hypervisor
```

To update later, run the same commands again.

**4. Verify**

```bash
id -nG | grep -qw kvm && echo "kvm group ok"
cloud-hypervisor --version
/usr/libexec/virtiofsd --version
```

**5. Install the scripts, build the images and the VM rootfs**

From the repository root (see [../container/README.md](../container/README.md#install)):

```bash
mkdir -p ~/ws ~/.local/bin ~/.local/share/bash-completion/completions
cp -r ws/. ~/ws/
ln -sf ~/ws/bin/ws ~/.local/bin/ws
ln -sf ~/ws/completion/ws.bash ~/.local/share/bash-completion/completions/ws
(cd ~/ws/container && podman build --pull -t ws --build-arg USERNAME="$USER" base \
    && podman build -t ws-llm --build-arg USERNAME="$USER" llm)
ws -t vmm build                # ~/ws/images/ws.ext4 + kernel (vmlinux)
ws -t vmm build --llm          # ~/ws/images/ws-llm.ext4
```

Repeat `ws -t vmm build [--llm]` after every `podman build`.

**6. Run**

```bash
ws -t vmm                      # shell in the VM, exit it to stop the VM
ws -t vmm --llm -d ~/src -w    # with the agents image and ~/src mounted rw
```

`sudo` asks for the password to create and remove the tap device; `-x` (no network) does not need it.

## Networking

- Guest subnets are /30s from `172.30.0.0/16`, tap devices are named `ws<8 hex>`, both are removed on exit.
  After a crash run `ws -t vmm cleanup`: it lists tap devices without a VM attached and
  `ws_*` nft tables without a live tap, and removes them after confirmation (via `sudo`).
- The guest cannot reach the host itself, only the outside world (NAT) and the forwarded port.
- `net.ipv4.ip_forward` is set to 1 and left on.
- If Docker is installed, it sets the `FORWARD` policy to `DROP`, which blocks guest traffic.
  Allow it with `sudo iptables -I DOCKER-USER -i 'ws+' -j ACCEPT && sudo iptables -I DOCKER-USER -o 'ws+' -j ACCEPT`.
  The same applies to ufw/firewalld setups that drop forwarded traffic.

## Troubleshooting

- When Cloud Hypervisor fails, the script prints its log and the virtiofsd logs before cleaning up.
- `virtiofsd` fails to start: try `WS_VIRTIOFSD_ARGS=--sandbox=none` (no unprivileged user namespaces).
- Changes to `INIT` in `ws-vmm.py` apply on the next run, changes to `INIT_STUB` need `build` again.
