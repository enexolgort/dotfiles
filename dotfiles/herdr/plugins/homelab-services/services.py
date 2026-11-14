#!/usr/bin/env python3
"""herdr board of every homelab service.

The list comes from nixOS/common/homepage.nix in the dotfiles repo on Forgejo,
the same tiles the Homepage dashboard shows. Each service is then checked
directly from this machine with Homepage's rule: HTTP status 1..403 is up.
The last list fetched is cached, so the board still works when Forgejo is down.

Env overrides: DOTFILES_RAW_URL, SERVICES_REFRESH (seconds).
"""

import concurrent.futures as cf
import json
import os
import re
import select
import shutil
import subprocess
import sys
import termios
import time
import tty
import urllib.error
import urllib.request

RAW_URL = os.environ.get(
    "DOTFILES_RAW_URL",
    "http://mnemosyne:3000/enexolgort/dotfiles/raw/branch/main/nixOS/common/homepage.nix",
)
REFRESH = int(os.environ.get("SERVICES_REFRESH", "30"))
STATE_DIR = os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.expanduser(
    "~/.cache/herdr-homelab-services"
)
CACHE = os.path.join(STATE_DIR, "services.json")

# catppuccin-mocha, to match the herdr theme
GREEN, RED, PEACH, BLUE, SUBTEXT, OVERLAY, MAUVE, TEXT = (
    "\033[38;2;166;227;161m",
    "\033[38;2;243;139;168m",
    "\033[38;2;250;179;135m",
    "\033[38;2;137;180;250m",
    "\033[38;2;166;173;200m",
    "\033[38;2;108;112;134m",
    "\033[38;2;203;166;247m",
    "\033[38;2;205;214;244m",
)
BOLD, REV, RESET = "\033[1m", "\033[7m", "\033[0m"


# ---------------------------------------------------------------- the list

GROUP_RE = re.compile(r"^\s*([A-Za-z_][\w-]*)\s*=\s*\[\s*$")
TILE_RE = re.compile(r"\(tile\s*\{(.*?)\}\s*\)")
FIELD_RE = re.compile(r'(\w+)\s*=\s*(?:"((?:[^"\\]|\\.)*)"|(\d+))\s*;')


def parse_homepage_nix(src):
    """Tiles under `services = [ { <host> = [ (tile { ... }) ... ]; } ]`."""
    services, group = [], None
    in_services = False
    for line in src.splitlines():
        if re.match(r"^\s*services\s*=\s*\[", line):
            in_services = True
            continue
        if not in_services:
            continue
        m = GROUP_RE.match(line)
        if m:
            group = m.group(1)
            continue
        for tile in TILE_RE.finditer(line):
            f = {k: (int(n) if n else s) for k, s, n in FIELD_RE.findall(tile.group(1))}
            if "name" not in f or "host" not in f or "port" not in f:
                continue
            path = f.get("path", "/")
            base = f"http://{f['host']}:{f['port']}"
            services.append(
                {
                    "group": group or f["host"],
                    "name": f["name"],
                    "description": f.get("description", ""),
                    "href": base + path,
                    "monitor": base + f.get("monitorPath", path),
                }
            )
    return services


def load_services():
    """(services, note): fresh from Forgejo, else the cached copy."""
    try:
        with urllib.request.urlopen(RAW_URL, timeout=5) as r:
            services = parse_homepage_nix(r.read().decode())
        if not services:
            raise ValueError("no tiles found in homepage.nix")
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(CACHE, "w") as f:
            json.dump(services, f)
        return services, None
    except Exception as e:  # noqa: BLE001 - any failure falls back to cache
        try:
            with open(CACHE) as f:
                return json.load(f), f"Forgejo unreachable ({e}); showing cached list"
        except OSError:
            return [], f"Forgejo unreachable ({e}) and no cached list"


# ---------------------------------------------------------------- checks

class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


_opener = urllib.request.build_opener(_NoRedirect)


def check(svc):
    start = time.monotonic()
    try:
        with _opener.open(urllib.request.Request(svc["monitor"], method="GET"), timeout=5) as r:
            status = r.status
    except urllib.error.HTTPError as e:
        status = e.code
    except Exception as e:  # noqa: BLE001
        return {"up": False, "status": None, "error": _short_error(e)}
    ms = (time.monotonic() - start) * 1000
    return {"up": 0 < status <= 403, "status": status, "ms": ms}


def _short_error(e):
    reason = getattr(e, "reason", e)
    text = str(reason)
    if "timed out" in text:
        return "timeout"
    if "refused" in text:
        return "refused"
    if "Name or service" in text or "resolve" in text:
        return "no DNS"
    return text[:24]


def check_all(services):
    with cf.ThreadPoolExecutor(max_workers=16) as pool:
        return list(pool.map(check, services))


# ---------------------------------------------------------------- drawing

def link(url, text):
    """OSC 8 hyperlink, so a Ctrl-click in herdr opens it."""
    return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"


def build_lines(services, results, selected, note, checked_at, width, interactive):
    up = sum(1 for r in results if r and r["up"])
    total = len(services)
    colour = GREEN if total and up == total else (RED if up == 0 else PEACH)
    lines = [
        f"{BOLD}{MAUVE}󰒍 Homelab services{RESET}  {colour}{up}/{total} up{RESET}"
        + (f"  {OVERLAY}checked {time.strftime('%H:%M:%S', time.localtime(checked_at))}{RESET}" if checked_at else ""),
        "",
    ]
    if note:
        lines += [f"{PEACH}{note}{RESET}", ""]

    name_w = max([len(s["name"]) for s in services] + [8])
    group = None
    for i, (svc, res) in enumerate(zip(services, results)):
        if svc["group"] != group:
            if group is not None:
                lines.append("")
            group = svc["group"]
            lines.append(f"{BOLD}{BLUE}{group}{RESET}")
        if res is None:
            dot, state = f"{OVERLAY}○{RESET}", f"{OVERLAY}checking…{RESET}"
        elif res["up"]:
            dot, state = f"{GREEN}●{RESET}", f"{SUBTEXT}{res['ms']:>5.0f} ms{RESET}"
        else:
            why = f"HTTP {res['status']}" if res["status"] else res.get("error", "down")
            dot, state = f"{RED}●{RESET}", f"{RED}{why:>8}{RESET}"
        name = svc["name"].ljust(name_w)
        if interactive and i == selected:
            name = f"{REV}{name}{RESET}"
        else:
            name = f"{TEXT}{name}{RESET}"
        url = link(svc["href"], svc["href"])
        desc = svc["description"]
        lines.append(f"  {dot} {name}  {state}  {BLUE}{url}{RESET}  {OVERLAY}{desc}{RESET}")

    if interactive:
        lines += [
            "",
            f"{OVERLAY}↑/↓ j/k move · enter open · r refresh · q/esc close · "
            f"auto-refresh {REFRESH}s · ctrl-click a URL to open it{RESET}",
        ]
    return lines


def draw(lines):
    cols, rows = shutil.get_terminal_size((100, 30))
    out = ["\033[H"]
    for line in lines[:rows]:
        out.append(line + "\033[K\r\n")
    out.append("\033[J")
    sys.stdout.write("".join(out))
    sys.stdout.flush()


# ---------------------------------------------------------------- opening

def open_url(url):
    for cmd in (["xdg-open"], ["wslview"], ["open"], ["explorer.exe"]):
        if shutil.which(cmd[0]):
            subprocess.Popen(cmd + [url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
            return True
    return False


# ---------------------------------------------------------------- main

def read_key(fd, timeout):
    r, _, _ = select.select([fd], [], [], timeout)
    if not r:
        return None
    data = os.read(fd, 32).decode(errors="ignore")
    return data


def run_once():
    services, note = load_services()
    results = check_all(services)
    for line in build_lines(services, results, -1, note, time.time(), 120, False):
        print(line)
    return 0 if all(r["up"] for r in results) else 1


def run_board():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    sys.stdout.write("\033[?1049h\033[?25l")  # alt screen, hide cursor
    selected = 0
    try:
        tty.setcbreak(fd)
        while True:
            services, note = load_services()
            results = [None] * len(services)
            selected = min(selected, max(len(services) - 1, 0))
            draw(build_lines(services, results, selected, note, None, 0, True))

            # Check in the background, redrawing as results arrive.
            pool = cf.ThreadPoolExecutor(max_workers=16)
            futures = {pool.submit(check, s): i for i, s in enumerate(services)}
            pending = set(futures)
            checked_at = None
            deadline = time.monotonic() + REFRESH
            action = None
            while action is None:
                done = {f for f in pending if f.done()}
                for f in done:
                    results[futures[f]] = f.result()
                pending -= done
                if not pending and checked_at is None:
                    checked_at = time.time()
                if done or checked_at:
                    draw(build_lines(services, results, selected, note, checked_at, 0, True))
                if not pending and time.monotonic() >= deadline:
                    action = "refresh"
                    break
                key = read_key(fd, 0.1 if pending else 1.0)
                if key is None:
                    continue
                if key in ("q", "\x1b", "\x03"):
                    action = "quit"
                elif key == "r":
                    action = "refresh"
                elif key in ("j", "\x1b[B") and services:
                    selected = (selected + 1) % len(services)
                elif key in ("k", "\x1b[A") and services:
                    selected = (selected - 1) % len(services)
                elif key in ("\r", "\n") and services:
                    if not open_url(services[selected]["href"]):
                        note = "No URL opener here (xdg-open/wslview); ctrl-click the URL instead"
                draw(build_lines(services, results, selected, note, checked_at, 0, True))
            pool.shutdown(wait=False, cancel_futures=True)
            if action == "quit":
                return 0
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write("\033[?25h\033[?1049l")
        sys.stdout.flush()


if __name__ == "__main__":
    if "--once" in sys.argv or not sys.stdin.isatty():
        sys.exit(run_once())
    sys.exit(run_board())
