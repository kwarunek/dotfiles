#!/bin/bash
# Entry point for jira_helpdesk.py (also used by automation-server, see schema.json).
# exec replaces the shell, and "$@" passes every argument through unchanged:
# no word splitting or globbing of values such as subjects with spaces or "*".

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/jira_helpdesk.py" "$@"
