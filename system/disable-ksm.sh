#!/usr/bin/env bash
# Disable Kernel Samepage Merging (KSM) now and across reboots.
set -euo pipefail

KSM_DIR="/sys/kernel/mm/ksm"
KSM_RUN="$KSM_DIR/run"
TMPFILES_DIR="/etc/tmpfiles.d"
TMPFILES_CONF="$TMPFILES_DIR/disable-ksm.conf"
TMPFILES_LINE="w $KSM_RUN - - - - 0"
SERVICES=(ksm ksmtuned)

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

# Root check
if [[ $EUID -ne 0 ]]; then
    die "Run as root: sudo $0"
fi

# 1. Kernel support check
if [[ ! -d "$KSM_DIR" ]]; then
    info "$KSM_DIR not found: kernel has no KSM support. Nothing to do."
    exit 0
fi
if [[ ! -w "$KSM_RUN" ]]; then
    die "$KSM_RUN exists but is not writable."
fi

# 2. Stop and disable services that may re-enable KSM
if command -v systemctl >/dev/null 2>&1; then
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files "${svc}.service" --no-legend 2>/dev/null | grep -q "^${svc}\.service"; then
            info "Disabling and stopping ${svc}.service"
            systemctl disable --now "${svc}.service" || warn "Failed to disable ${svc}.service"
        else
            info "${svc}.service not installed, skipping"
        fi
    done
else
    warn "systemctl not found, skipping service checks"
fi

# 3. Disable KSM immediately
current=$(cat "$KSM_RUN")
if [[ "$current" == "0" ]]; then
    info "KSM already stopped (run=0)"
else
    info "Stopping KSM (run=$current -> 0)"
    echo 0 > "$KSM_RUN"
fi

# 4. Persist across reboots via systemd-tmpfiles
if [[ -d "$TMPFILES_DIR" ]]; then
    if [[ -f "$TMPFILES_CONF" ]] && grep -qxF "$TMPFILES_LINE" "$TMPFILES_CONF"; then
        info "$TMPFILES_CONF already configured"
    else
        info "Writing $TMPFILES_CONF"
        echo "$TMPFILES_LINE" > "$TMPFILES_CONF"
    fi
else
    warn "$TMPFILES_DIR not found, setting will NOT persist after reboot"
fi

# 5. Verify
run_now=$(cat "$KSM_RUN")
sharing=$(cat "$KSM_DIR/pages_sharing" 2>/dev/null || echo "n/a")
info "Result: run=$run_now, pages_sharing=$sharing"

if [[ "$run_now" != "0" ]]; then
    die "KSM is still active (run=$run_now)"
fi

if [[ "$sharing" != "0" && "$sharing" != "n/a" ]]; then
    info "Note: run=0 keeps already merged pages; they unmerge as they are written or after reboot."
fi

info "Done."
