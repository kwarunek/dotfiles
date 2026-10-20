#!/usr/bin/env python3
"""Jira heldesk

Config:      ~/.automation/jira-helpdesk/config.toml           (plain, created by `init`)
Credentials: env JIRA_TOKEN, or JIRA_USER + JIRA_PASSWORD,
             else ~/.automation/jira-helpdesk/credentials.json.gpg (created by `login`),
             else interactive prompt.
Output:      text by default, `-o json` for scripts. On a terminal issue keys are
             links: `links` in config or env JIRA_HELPDESK_LINKS =
             osc8 (clickable key), url (full URL, for terminals without OSC 8,
             e.g. LXTerminal) or off.

    jira_helpdesk.py init
    jira_helpdesk.py login
    jira_helpdesk.py login --verify -o json
    jira_helpdesk.py fields -T aws-incident
    jira_helpdesk.py products graf
    jira_helpdesk.py issues --for-me --open
    jira_helpdesk.py create -T rfa -s "Subject" -d "Description" -p "Grafana"
    jira_helpdesk.py create -T incident -s "Subject" -d - -p DREAM-241 < body.txt
    source <(jira_helpdesk.py --bash-completion)
"""

import argparse
import getpass
import itertools
import json
import os
import re
import subprocess
import sys
import tomllib

import requests

TOOL_DIR = os.environ.get(
    "JIRA_HELPDESK_DIR",
    os.path.join(os.path.expanduser("~"), ".automation", "jira-helpdesk"),
)
CONFIG_PATH = os.path.join(TOOL_DIR, "config.toml")
CREDENTIALS_PATH = os.path.join(TOOL_DIR, "credentials.json.gpg")
OBJECT_KEY_RE = re.compile(r"^[A-Z][A-Z0-9]*-\d+$")
OUTPUT_FORMATS = ("json", "text")
LINK_MODES = ("osc8", "url", "off")
LINKS = "osc8"  # set in main() from env JIRA_HELPDESK_LINKS or config `links`

# The only request types this tool creates.
REQUEST_TYPES = {
    "rfa": 245,  # Wniosek o konfigurację
    "aws-incident": 249,  # AWS Incident
    "incident": 36,  # Zgłoś awarię dotyczącą usług online
}
TYPE_DEFAULTS = {
    "product_field": "customfield_19006",
    "on_behalf_field": "customfield_14401",
    "fields": {},
}

CONFIG_TEMPLATE = """\
url = "_URL_"
service_desk_id = 4
project_id = 20242
default_type = "rfa"

# Store credentials gpg-encrypted in credentials.json.gpg (`login`).
# false: only env vars (JIRA_TOKEN or JIRA_USER + JIRA_PASSWORD) or the prompt.
use_gpg = __USE_GPG__
# Key the credentials are encrypted to: fingerprint (preferred), key id or email.
# Empty means gpg's default key (--default-recipient-self).
gpg_key = "__GPG_KEY__"
# Encrypt with a passphrase instead of a key (gpg_key is then ignored).
gpg_symmetric = __GPG_SYMMETRIC__

# Issue keys in text output on a terminal: "osc8" (clickable key; needs terminal
# support), "url" (print the full URL, e.g. for LXTerminal) or "off".
links = "osc8"

# Optional per-type overrides; request types themselves are fixed in the script:
#   rfa = 245, aws-incident = 249, incident = 36
# Defaults: product_field = "customfield_19006", on_behalf_field = "customfield_14401".
# `fields` are sent as-is in requestFieldValues (string for text fields,
# {value = "..."} for selects, ...). Check shapes with: jira_helpdesk.py fields -T <type>
# product_code_field / product_code_attribute additionally send the product's
# ProductId attribute (as JiraApi.py does), e.g.:
#   product_code_field = "customfield_16312"
#   product_code_attribute = "ProductId"

[types.rfa.fields]

[types.aws-incident.fields]

[types.incident.fields]
"""


class HelpdeskError(Exception):
    def __init__(self, message: str, **details):
        super().__init__(message)
        self.details = details


def load_config() -> dict:
    if not os.path.exists(CONFIG_PATH):
        raise HelpdeskError(f"No config at {CONFIG_PATH}, run `init` first")
    with open(CONFIG_PATH, "rb") as f:
        return tomllib.load(f)


def type_config(config: dict, name: str | None) -> dict:
    name = name or config.get("default_type", "rfa")
    if name not in REQUEST_TYPES:
        raise HelpdeskError(
            f"Unknown type {name!r}, choose from: {', '.join(REQUEST_TYPES)}"
        )
    return {
        **TYPE_DEFAULTS,
        **config.get("types", {}).get(name, {}),
        "request_type_id": REQUEST_TYPES[name],
    }


def gpg_decrypt(path: str) -> dict:
    r = subprocess.run(
        ["gpg", "--quiet", "--decrypt", path], capture_output=True, check=False
    )
    if r.returncode:
        raise HelpdeskError(f"gpg decrypt failed: {r.stderr.decode().strip()}")
    return json.loads(r.stdout)


def gpg_list(*args: str) -> list[list[str]]:
    r = subprocess.run(
        ["gpg", "--batch", "--with-colons", *args],
        capture_output=True,
        text=True,
        check=False,
    )
    return (
        [line.split(":") for line in r.stdout.splitlines()] if r.returncode == 0 else []
    )


def gpg_key_info(key: str) -> dict | None:
    """Primary fingerprint and first uid of a public key, or None if not in keyring."""
    rows = gpg_list("--list-keys", key)
    if sum(row[0] == "pub" for row in rows) > 1:
        raise HelpdeskError(f"gpg key {key!r} is ambiguous, use the fingerprint")
    fpr = next((row[9] for row in rows if row[0] == "fpr"), None)
    uid = next((row[9] for row in rows if row[0] == "uid"), "")
    return {"fingerprint": fpr, "uid": uid} if fpr else None


def gpg_secret_keys() -> list[dict]:
    rows = gpg_list("--list-secret-keys")
    fprs = [
        row[9]
        for prev, row in itertools.pairwise(rows)
        if prev[0] == "sec" and row[0] == "fpr"
    ]
    return [gpg_key_info(fpr) for fpr in fprs]


def configured_gpg_key(config: dict) -> dict | None:
    """Resolve gpg_key from config; None means symmetric or gpg's default key."""
    key = config.get("gpg_key")
    if config.get("gpg_symmetric") or not key:
        return None
    info = gpg_key_info(key)
    if not info:
        raise HelpdeskError(f"gpg_key {key!r} from {CONFIG_PATH} not found in keyring")
    return info


def gpg_encrypt(path: str, data: dict, config: dict) -> None:
    cmd = ["gpg", "--yes", "--armor", "--output", path]
    if config.get("gpg_symmetric"):
        cmd.append("--symmetric")
    elif key := configured_gpg_key(config):
        cmd += ["--encrypt", "--recipient", key["fingerprint"]]
    else:
        cmd += ["--encrypt", "--default-recipient-self"]
    os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
    r = subprocess.run(
        cmd, input=json.dumps(data).encode(), capture_output=True, check=False
    )
    if r.returncode:
        raise HelpdeskError(
            f"gpg encrypt failed: {r.stderr.decode().strip()}\n"
            f"Set gpg_key or gpg_symmetric = true in {CONFIG_PATH}"
        )
    os.chmod(path, 0o600)


def gpg_recipients(path: str) -> list[dict]:
    """Who can decrypt `path`, without decrypting it."""
    r = subprocess.run(
        ["gpg", "--batch", "--list-packets", "--list-only", path],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode:
        raise HelpdeskError(f"gpg --list-packets failed: {r.stderr.strip()}")
    result = []
    if ":symkey enc packet:" in r.stdout:
        result.append({"type": "passphrase"})
    for keyid in re.findall(r":pubkey enc packet:.*keyid ([0-9A-F]+)", r.stdout):
        info = gpg_key_info(keyid) or {"fingerprint": None, "uid": None}
        result.append(
            {
                "type": "key",
                "keyid": keyid,
                **info,
                "secret_key": bool(gpg_list("--list-secret-keys", keyid)),
            }
        )
    return result


def prompt_input(prompt: str) -> str:
    """input() with the prompt on stderr, reading the tty when stdin is redirected."""
    sys.stderr.write(prompt)
    sys.stderr.flush()
    if sys.stdin.isatty():
        return input()
    with open("/dev/tty") as tty:
        return tty.readline().rstrip("\n")


def prompt_credentials() -> dict:
    token = getpass.getpass(
        "Personal access token (empty to use login/password): "
    ).strip()
    if token:
        return {"token": token}
    default_user = getpass.getuser()
    user = prompt_input(f"Jira login [{default_user}]: ").strip() or default_user
    return {"user": user, "password": getpass.getpass("Jira password: ")}


def env_credentials() -> tuple[str, dict] | None:
    if os.environ.get("JIRA_TOKEN"):
        return "JIRA_TOKEN", {"token": os.environ["JIRA_TOKEN"]}
    if os.environ.get("JIRA_USER") and os.environ.get("JIRA_PASSWORD"):
        return "JIRA_USER/JIRA_PASSWORD", {
            "user": os.environ["JIRA_USER"],
            "password": os.environ["JIRA_PASSWORD"],
        }
    return None


def load_credentials(config: dict) -> dict:
    if env := env_credentials():
        return env[1]
    if config.get("use_gpg", True):
        if os.path.exists(CREDENTIALS_PATH):
            return gpg_decrypt(CREDENTIALS_PATH)
        print(
            f"No credentials in env or {CREDENTIALS_PATH} (run `login` to store them)",
            file=sys.stderr,
        )
    else:
        print("No credentials in env (use_gpg = false)", file=sys.stderr)
    return prompt_credentials()


class Jira:
    def __init__(self, config: dict, credentials: dict):
        self.url = config["url"].rstrip("/")
        self.config = config
        self.s = requests.Session()
        self.s.headers["Accept"] = "application/json"
        if "token" in credentials:
            self.s.headers["Authorization"] = f"Bearer {credentials['token']}"
        else:
            self.s.auth = (credentials["user"], credentials["password"])
        self.username = self._myself()

    def _request(self, method: str, path: str, **kw):
        r = self.s.request(method, f"{self.url}{path}", **kw)
        if r.status_code in (401, 403):
            reason = r.headers.get("X-Authentication-Denied-Reason", "")
            raise HelpdeskError(f"{method} {path}: {r.status_code} {reason}".strip())
        if not r.ok:
            raise HelpdeskError(f"{method} {path}: {r.status_code} {r.text[:2000]}")
        return r.json()

    def _myself(self) -> str:
        return self._request("GET", "/rest/api/2/myself")["name"]

    def request_type_fields(self, request_type_id: int) -> list[dict]:
        sd = self.config["service_desk_id"]
        return self._request(
            "GET",
            f"/rest/servicedeskapi/servicedesk/{sd}/requesttype/{request_type_id}/field",
        )["requestTypeFields"]

    def search_products(self, tc: dict, query: str) -> list[dict]:
        """Same endpoint the customer portal uses for the product picker."""
        project_id = str(self.config["project_id"])
        body = {
            "currentReporter": self.username,
            "query": query,
            "customFieldId": int(tc["product_field"].removeprefix("customfield_")),
            "customFieldRequestFields": [
                {"fieldId": "projectId", "value": project_id},
                {"fieldId": "pid", "value": project_id},
                {"fieldId": "reporter", "value": self.username},
            ],
        }
        data = self._request(
            "POST",
            f"/rest/insight_servicedesk/1.0/servicedesk/customfield/default/{tc['request_type_id']}/objects",
            json=body,
        )
        return [{"key": o["objectKey"], "label": o["label"]} for o in data["objects"]]

    def resolve_product(self, tc: dict, name: str) -> dict:
        found = self.search_products(tc, name)
        if OBJECT_KEY_RE.match(name):
            matches = [p for p in found if p["key"] == name] or [
                {"key": name, "label": name}
            ]
        else:
            matches = [
                p for p in found if p["label"].casefold() == name.casefold()
            ] or found
        if len(matches) == 1:
            return matches[0]
        if not matches:
            raise HelpdeskError(f"Product not found: {name!r}")
        raise HelpdeskError(f"Ambiguous product {name!r}", candidates=matches)

    def product_attribute(self, object_key: str, attribute: str) -> str:
        """Read an Insight attribute (e.g. ProductId) of an object, as JiraApi.get_object_key does in reverse."""
        data = self._request(
            "POST",
            "/rest/insight/1.0/object/navlist/iql",
            json={
                "objectTypeId": "5",
                "objectSchemaId": "1",
                "iql": f'Key = "{object_key}"',
                "page": 1,
                "resultsPerPage": 1,
                "includeAttributes": True,
            },
        )
        entries = data.get("objectEntries", [])
        if not entries:
            raise HelpdeskError(f"Insight object {object_key} not found")
        names = {a["id"]: a["name"] for a in data.get("objectTypeAttributes", [])}
        for attr in entries[0].get("attributes", []):
            if names.get(attr["objectTypeAttributeId"]) == attribute:
                values = attr.get("objectAttributeValues", [])
                if values:
                    return values[0]["value"]
        raise HelpdeskError(f"Attribute {attribute!r} not found on {object_key}")

    def build_request(
        self,
        tc: dict,
        summary: str,
        description: str,
        product: dict,
        extra_fields: dict,
    ) -> dict:
        fields = {
            "summary": summary,
            "description": description,
            tc["product_field"]: [{"key": product["key"]}],
            tc["on_behalf_field"]: {"name": self.username},
            **tc.get("fields", {}),
            **extra_fields,
        }
        if tc.get("product_code_field"):
            fields[tc["product_code_field"]] = self.product_attribute(
                product["key"], tc.get("product_code_attribute", "ProductId")
            )
        return {
            "serviceDeskId": str(self.config["service_desk_id"]),
            "requestTypeId": str(tc["request_type_id"]),
            "requestFieldValues": fields,
        }

    def create_request(self, body: dict) -> str:
        return self._request("POST", "/rest/servicedeskapi/request", json=body)[
            "issueKey"
        ]

    def search_issues(self, jql: str, fields: list[str], limit: int) -> list[dict]:
        return self._request(
            "GET",
            "/rest/api/2/search",
            params={"jql": jql, "fields": ",".join(fields), "maxResults": limit},
        )["issues"]


def ask(question: str, default: str) -> str:
    if not sys.stdin.isatty():
        return default
    return prompt_input(f"{question} [{default}]: ").strip() or default


def choose_gpg() -> tuple[bool, str, bool]:
    """Ask how to store credentials; returns (use_gpg, gpg_key, gpg_symmetric)."""
    if ask("Store credentials gpg-encrypted? (y/n)", "y").lower() not in ("y", "yes"):
        return False, "", False
    secret_keys = gpg_secret_keys()
    for i, key in enumerate(secret_keys, 1):
        print(f"  {i}) {key['fingerprint']}  {key['uid']}", file=sys.stderr)
    print("  p) passphrase (symmetric, no key)", file=sys.stderr)
    default = "1" if secret_keys else "p"
    while True:
        choice = ask("Encrypt with", default).lower()
        if choice == "p":
            return True, "", True
        if choice.isdigit() and 1 <= int(choice) <= len(secret_keys):
            return True, secret_keys[int(choice) - 1]["fingerprint"], False
        hint = f"1-{len(secret_keys)} or p" if secret_keys else "p"
        print(f"  choose {hint}", file=sys.stderr)


def cmd_init(args) -> dict:
    if os.path.exists(CONFIG_PATH) and not args.force:
        raise HelpdeskError(f"{CONFIG_PATH} exists (use --force to overwrite)")
    use_gpg, gpg_key, gpg_symmetric = choose_gpg()
    os.makedirs(TOOL_DIR, mode=0o700, exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        f.write(
            CONFIG_TEMPLATE.replace("__USE_GPG__", str(use_gpg).lower())
            .replace("__GPG_KEY__", gpg_key)
            .replace("__GPG_SYMMETRIC__", str(gpg_symmetric).lower())
        )
    return {
        "config": CONFIG_PATH,
        "use_gpg": use_gpg,
        "gpg_key": gpg_key or None,
        "gpg_symmetric": gpg_symmetric,
    }


def verify_credentials(config: dict) -> dict:
    """Check every credential source independently. Never includes secrets."""
    result = {"ok": True, "env": {}, "gpg": {}, "in_use": None}

    env = result["env"]
    if found := env_credentials():
        name, credentials = found
        env["source"] = name
        try:
            env["user"] = Jira(config, credentials).username
            env["status"] = "ok"
            result["in_use"] = "env"
        except (HelpdeskError, requests.RequestException) as e:
            env.update(status="failed", error=str(e))
            result["ok"] = False
    else:
        env["status"] = "not set"

    gpg = result["gpg"]
    gpg["path"] = CREDENTIALS_PATH
    if not config.get("use_gpg", True):
        gpg["status"] = "disabled"
    elif not os.path.exists(CREDENTIALS_PATH):
        gpg["status"] = "not found"
    else:
        try:
            gpg["encrypted_for"] = recipients = gpg_recipients(CREDENTIALS_PATH)
            if config.get("gpg_symmetric"):
                gpg["configured"] = {"type": "passphrase"}
                gpg["mismatch"] = not any(r["type"] == "passphrase" for r in recipients)
            elif key := configured_gpg_key(config):
                gpg["configured"] = {"type": "key", **key}
                gpg["mismatch"] = key["fingerprint"] not in {
                    r.get("fingerprint") for r in recipients
                }
            if gpg.get("mismatch"):
                result["ok"] = False
            gpg["user"] = Jira(config, gpg_decrypt(CREDENTIALS_PATH)).username
            gpg["status"] = "ok"
            result["in_use"] = result["in_use"] or "gpg"
        except (
            HelpdeskError,
            requests.RequestException,
            json.JSONDecodeError,
            KeyError,
        ) as e:
            gpg.update(status="failed", error=str(e))
            result["ok"] = False

    if not result["in_use"]:
        result["ok"] = False
    return result


def cmd_login(args) -> dict:
    config = load_config()
    if args.verify:
        return verify_credentials(config)
    if not config.get("use_gpg", True):
        jira = Jira(config, prompt_credentials())
        return {"user": jira.username, "saved": None}
    configured_gpg_key(config)  # fail on a bad gpg_key before asking for credentials
    credentials = prompt_credentials()
    jira = Jira(config, credentials)
    gpg_encrypt(CREDENTIALS_PATH, credentials, config)
    return {
        "user": jira.username,
        "saved": CREDENTIALS_PATH,
        "encrypted_for": gpg_recipients(CREDENTIALS_PATH),
    }


def cmd_fields(jira: Jira, args) -> list[dict]:
    tc = type_config(jira.config, args.type)
    return [
        {
            "fieldId": f["fieldId"],
            "name": f["name"],
            "required": f["required"],
            "jiraSchema": f["jiraSchema"],
            "validValues": [
                {"value": v["value"], "label": v["label"]}
                for v in f.get("validValues", [])
            ],
        }
        for f in jira.request_type_fields(tc["request_type_id"])
    ]


def cmd_products(jira: Jira, args) -> list[dict]:
    tc = type_config(jira.config, args.type)
    return jira.search_products(tc, args.query)


def user_name(value) -> str | None:
    """Username from a user field (single or multi user picker)."""
    if isinstance(value, list):
        value = value[0] if value else None
    return value.get("name") if isinstance(value, dict) else None


def cmd_issues(jira: Jira, args) -> list[dict]:
    """Requests in the service desk project reported by me and/or on my behalf."""
    on_behalf = type_config(jira.config, None)["on_behalf_field"]
    on_behalf_jql = f"cf[{on_behalf.removeprefix('customfield_')}]"
    by_me, for_me = args.by_me, args.for_me
    if not by_me and not for_me:
        by_me = for_me = True
    who = []
    if by_me:
        who.append("reporter = currentUser()")
    if for_me:
        who.append(f"{on_behalf_jql} = currentUser()")
    jql = f"project = {jira.config['project_id']} AND ({' OR '.join(who)})"
    if args.open:
        jql += " AND statusCategory != Done"
    jql += " ORDER BY created DESC"

    portal = f"{jira.url}/servicedesk/customer/portal/{jira.config['service_desk_id']}"
    issues = jira.search_issues(
        jql, ["summary", "status", "created", "reporter", on_behalf], args.limit
    )
    result = []
    for issue in issues:
        f = issue["fields"]
        reporter = user_name(f.get("reporter"))
        requested_for = user_name(f.get(on_behalf))
        result.append(
            {
                "key": issue["key"],
                "summary": f["summary"],
                "status": f["status"]["name"],
                "created": f["created"],
                "reporter": reporter,
                "requested_for": requested_for,
                "by_me": reporter == jira.username,
                "for_me": requested_for == jira.username,
                "url": f"{portal}/{issue['key']}",
            }
        )
    return result


def cmd_create(jira: Jira, args) -> dict:
    tc = type_config(jira.config, args.type)
    product = jira.resolve_product(tc, args.product)
    body = jira.build_request(
        tc, args.subject, args.description, product, dict(args.field)
    )
    if args.dry_run:
        return {"dry_run": True, "product": product, "request": body}
    key = jira.create_request(body)
    portal = f"{jira.url}/servicedesk/customer/portal/{jira.config['service_desk_id']}"
    return {"key": key, "url": f"{portal}/{key}", "product": product}


def describe_recipient(r: dict) -> str:
    if r["type"] == "passphrase":
        return "passphrase (symmetric)"
    if not r.get("fingerprint"):
        return f"key {r['keyid']} (not in keyring)"
    secret = "available" if r["secret_key"] else "MISSING"
    return f"{r['fingerprint']} {r['uid']} (subkey {r['keyid']}, secret key {secret})"


def text_init(d: dict) -> str:
    if not d["use_gpg"]:
        gpg = "disabled, use JIRA_TOKEN or JIRA_USER + JIRA_PASSWORD"
    elif d["gpg_symmetric"]:
        gpg = "passphrase (symmetric)"
    else:
        gpg = f"key {d['gpg_key'] or '(gpg default)'}"
    return f"Wrote {d['config']}\ngpg: {gpg}"


def text_login(d: dict) -> str:
    if "env" in d:
        return text_verify(d)
    if not d["saved"]:
        return f"Logged in as {d['user']}; use_gpg = false, credentials not saved"
    lines = [f"Logged in as {d['user']}, credentials saved to {d['saved']}"]
    lines += [f"  encrypted for: {describe_recipient(r)}" for r in d["encrypted_for"]]
    return "\n".join(lines)


def text_verify(d: dict) -> str:
    env, gpg = d["env"], d["gpg"]
    if env["status"] == "not set":
        lines = ["env: not set (JIRA_TOKEN or JIRA_USER + JIRA_PASSWORD)"]
    elif env["status"] == "ok":
        lines = [f"env ({env['source']}): OK, authenticated as {env['user']}"]
    else:
        lines = [f"env ({env['source']}): FAILED: {env['error']}"]

    if gpg["status"] == "disabled":
        lines.append("gpg: disabled in config (use_gpg = false)")
    elif gpg["status"] == "not found":
        lines.append(f"gpg ({gpg['path']}): not found")
    else:
        lines.append(f"gpg ({gpg['path']}):")
        for r in gpg.get("encrypted_for", []):
            lines.append(f"  encrypted for: {describe_recipient(r)}")
        if configured := gpg.get("configured"):
            if configured["type"] == "passphrase":
                lines.append("  configured: passphrase (symmetric)")
            else:
                lines.append(
                    f"  configured gpg_key: {configured['fingerprint']} {configured['uid']}"
                )
        if gpg.get("mismatch"):
            lines.append(
                "  MISMATCH: not encrypted as configured, run `login` to re-encrypt"
            )
        if gpg["status"] == "ok":
            lines.append(f"  OK, authenticated as {gpg['user']}")
        else:
            lines.append(f"  FAILED: {gpg['error']}")

    lines.append(f"in use: {d['in_use'] or 'none, other commands will prompt'}")
    return "\n".join(lines)


def text_fields(fields: list[dict]) -> str:
    lines = []
    for f in fields:
        req = "*" if f["required"] else " "
        lines.append(
            f"{req} {f['fieldId']:<20} {f['name']:<35} {json.dumps(f['jiraSchema'])}"
        )
        for v in f["validValues"][:20]:
            lines.append(f"      {v['value']!r}: {v['label']}")
    return "\n".join(lines)


def text_products(products: list[dict]) -> str:
    return "\n".join(f"{p['key']:<12} {p['label']}" for p in products)


def link_mode() -> str:
    return LINKS if sys.stdout.isatty() else "off"


def link(text: str, url: str, width: int = 0) -> str:
    """Issue key as a terminal link, padded to `width` columns (as if just `text`)."""
    pad = " " * max(0, width - len(text))
    mode = link_mode()
    if mode == "url":
        return url + pad
    if mode == "osc8":
        return f"\033]8;;{url}\033\\{text}\033]8;;\033\\{pad}"
    return text + pad


def text_issues(issues: list[dict]) -> str:
    lines = []
    for i in issues:
        relation = ",".join(
            name
            for name, flag in (("by me", i["by_me"]), ("for me", i["for_me"]))
            if flag
        )
        lines.append(
            f"{link(i['key'], i['url'], 14)} {i['created'][:10]}  {i['status']:<20} "
            f"{relation:<14} {i['summary']}"
        )
    return "\n".join(lines)


def text_create(d: dict) -> str:
    product = f"Product: {d['product']['label']} ({d['product']['key']})"
    if d.get("dry_run"):
        return f"{product}\n{json.dumps(d['request'], indent=2, ensure_ascii=False)}"
    if link_mode() == "url":
        return f"{product}\n{d['url']}"
    return f"{product}\n{link(d['key'], d['url'])}  {d['url']}"


TEXT_OUTPUT = {
    "init": text_init,
    "login": text_login,
    "fields": text_fields,
    "products": text_products,
    "issues": text_issues,
    "create": text_create,
}


def emit(data, output: str, cmd: str) -> None:
    if output == "text":
        text = TEXT_OUTPUT[cmd](data)
        if text:
            print(text)
    else:
        print(json.dumps(data, indent=2, ensure_ascii=False))


def emit_error(e: HelpdeskError | Exception, output: str) -> None:
    details = getattr(e, "details", {})
    if output == "text":
        print(f"error: {e}", file=sys.stderr)
        for c in details.get("candidates", []):
            print(f"  {c['key']:<12} {c['label']}", file=sys.stderr)
    else:
        print(
            json.dumps({"error": str(e), **details}, ensure_ascii=False),
            file=sys.stderr,
        )


def parse_field(arg: str) -> tuple[str, object]:
    key, sep, value = arg.partition("=")
    if not sep:
        raise argparse.ArgumentTypeError(f"expected key=value, got {arg!r}")
    try:
        return key, json.loads(value)
    except json.JSONDecodeError:
        return key, value


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--bash-completion",
        nargs="*",
        metavar="ALIAS",
        help="print a bash completion script for this script and optional aliases "
        "(source <(%(prog)s --bash-completion jh))",
    )
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "-o", "--output", choices=OUTPUT_FORMATS, default="text", help="default: text"
    )
    sub = ap.add_subparsers(dest="cmd")

    p = sub.add_parser("init", parents=[common], help=f"create {CONFIG_PATH}")
    p.add_argument("--force", action="store_true", help="overwrite existing config")
    p = sub.add_parser(
        "login",
        parents=[common],
        help="verify credentials and store them gpg-encrypted",
    )
    p.add_argument(
        "--verify",
        action="store_true",
        help="only check env and stored gpg credentials against Jira, don't prompt",
    )
    p = sub.add_parser("fields", parents=[common], help="show fields of a request type")
    p.add_argument("-T", "--type", choices=REQUEST_TYPES)
    p = sub.add_parser("products", parents=[common], help="search products")
    p.add_argument("query", nargs="?", default="")
    p.add_argument("-T", "--type", choices=REQUEST_TYPES)

    p = sub.add_parser(
        "issues",
        parents=[common],
        help="list my requests (default: created by me or for me)",
    )
    p.add_argument("--by-me", action="store_true", help="reported by me")
    p.add_argument(
        "--for-me",
        action="store_true",
        help="requested on my behalf (Wnioskuję w imieniu)",
    )
    p.add_argument("--open", action="store_true", help="only not resolved")
    p.add_argument("-n", "--limit", type=int, default=20, help="default: 20")

    p = sub.add_parser("create", parents=[common], help="create a request")
    p.add_argument(
        "-T",
        "--type",
        choices=REQUEST_TYPES,
        help="request type (default: default_type from config)",
    )
    p.add_argument("-s", "--subject", required=True)
    p.add_argument(
        "-d", "--description", required=True, help="text, or '-' to read stdin"
    )
    p.add_argument(
        "-p", "--product", required=True, help="product name or key (DREAM-123)"
    )
    p.add_argument(
        "-f",
        "--field",
        type=parse_field,
        action="append",
        default=[],
        metavar="KEY=VALUE",
        help="extra/override field; VALUE parsed as JSON if valid",
    )
    p.add_argument(
        "--dry-run", action="store_true", help="resolve product, print the request body"
    )
    return ap


def bash_completion(ap: argparse.ArgumentParser, prog: str, aliases: list[str]) -> str:
    """Generate a bash completion script from the argparse definition."""
    func = "_automation_" + re.sub(r"\W", "_", prog)
    subparsers = next(
        a for a in ap._actions if isinstance(a, argparse._SubParsersAction)
    ).choices
    root_opts = [s for a in ap._actions for s in a.option_strings]

    value_cases, opt_cases = [], []
    if aliases:
        names = " ".join([*aliases])
    else:
        names = prog
    for name, parser in subparsers.items():
        opts = []
        for action in parser._actions:
            opts += action.option_strings
            if not action.option_strings or action.nargs == 0:
                continue
            pattern = "|".join(f"{name}:{o}" for o in action.option_strings)
            words = " ".join(action.choices) if action.choices else ""
            value_cases.append(
                f'        {pattern}) COMPREPLY=($(compgen -W "{words}" -- "$cur")); return;;'
            )
        opt_cases.append(f'        {name}) opts="{" ".join(opts)}";;')

    return f"""\
{func}() {{
    local cur prev cmd opts i
    cur="${{COMP_WORDS[COMP_CWORD]}}"
    prev="${{COMP_WORDS[COMP_CWORD-1]}}"
    cmd=""
    for ((i=1; i<COMP_CWORD; i++)); do
        case "${{COMP_WORDS[i]}}" in
            {"|".join(subparsers)}) cmd="${{COMP_WORDS[i]}}"; break;;
        esac
    done
    case "$cmd:$prev" in
{chr(10).join(value_cases)}
    esac
    case "$cmd" in
        "") opts="{" ".join(root_opts + list(subparsers))}";;
{chr(10).join(opt_cases)}
    esac
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}}
complete -F {func} {names}
"""


def main() -> int:
    ap = build_parser()
    args = ap.parse_args()
    if args.bash_completion is not None:
        prog = os.path.basename(sys.argv[0])
        print(bash_completion(ap, prog, args.bash_completion), end="")
        return 0
    if not args.cmd:
        ap.print_help()
        return 0
    global LINKS
    LINKS = os.environ.get("JIRA_HELPDESK_LINKS", "")
    if not LINKS and os.path.exists(CONFIG_PATH):
        try:
            LINKS = load_config().get("links", "")
        except tomllib.TOMLDecodeError:
            pass
    if LINKS not in LINK_MODES:
        LINKS = "off" if LINKS == "0" else "osc8"
    try:
        if args.cmd == "init":
            data = cmd_init(args)
        elif args.cmd == "login":
            data = cmd_login(args)
        else:
            if args.cmd == "create" and args.description == "-":
                args.description = sys.stdin.read()
            config = load_config()
            jira = Jira(config, load_credentials(config))
            command = {
                "fields": cmd_fields,
                "products": cmd_products,
                "issues": cmd_issues,
                "create": cmd_create,
            }
            data = command[args.cmd](jira, args)
    except (HelpdeskError, requests.RequestException) as e:
        emit_error(e, args.output)
        return 1
    emit(data, args.output, args.cmd)
    return 0 if not isinstance(data, dict) or data.get("ok", True) else 1


if __name__ == "__main__":
    sys.exit(main())
