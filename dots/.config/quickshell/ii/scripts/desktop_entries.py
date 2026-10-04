#!/usr/bin/env python3
"""Export the application desktop entries needed by the ii launcher.

Quickshell 0.2.x can repeatedly rescan DesktopEntries when a QML binding keeps
the manager-owned list alive. This small snapshot reader keeps launcher refresh
independent from that reactive manager.
"""

import json
import os
import shlex
from pathlib import Path


def bool_value(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes"}


def parse_exec(value: str) -> list[str]:
    try:
        tokens = shlex.split(value, posix=True)
    except ValueError:
        tokens = value.split()
    result = []
    for token in tokens:
        if token in {"%f", "%F", "%u", "%U", "%d", "%D", "%n", "%N", "%i", "%c", "%k", "%v", "%m"}:
            continue
        token = token.replace("%%", "%")
        for field in ("%f", "%F", "%u", "%U", "%d", "%D", "%n", "%N", "%i", "%c", "%k", "%v", "%m"):
            token = token.replace(field, "")
        if token:
            result.append(token)
    return result


def read_desktop(path: Path) -> dict | None:
    values: dict[str, str] = {}
    in_entry = False
    try:
        for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw.strip()
            if line.startswith("["):
                in_entry = line == "[Desktop Entry]"
                continue
            if not in_entry or not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            if "[" not in key:
                values.setdefault(key, value)
    except OSError:
        return None

    if values.get("Type", "Application") != "Application":
        return None
    if bool_value(values.get("Hidden", "false")) or bool_value(values.get("NoDisplay", "false")):
        return None
    command = parse_exec(values.get("Exec", ""))
    name = values.get("Name", path.stem)
    if not command or not name:
        return None

    actions = []
    action_ids = [item.strip() for item in values.get("Actions", "").split(";") if item.strip()]
    for action_id in action_ids:
        prefix = f"{action_id}."
        action_name = values.get(prefix + "Name")
        action_command = parse_exec(values.get(prefix + "Exec", ""))
        if action_name and action_command:
            actions.append({"name": action_name, "icon": values.get(prefix + "Icon", values.get("Icon", "")), "command": action_command, "runInTerminal": bool_value(values.get(prefix + "Terminal", values.get("Terminal", "false")))})

    return {
        "id": path.stem,
        "name": name,
        "icon": values.get("Icon", ""),
        "comment": values.get("Comment", ""),
        "genericName": values.get("GenericName", ""),
        "keywords": [item for item in values.get("Keywords", "").split(";") if item],
        "command": command,
        "runInTerminal": bool_value(values.get("Terminal", "false")),
        "actions": actions,
    }


def application_dirs() -> list[Path]:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    roots = [data_home, *(Path(item) for item in data_dirs if item)]
    roots += [Path("/var/lib/flatpak/exports/share"), data_home / "flatpak/exports/share"]
    return [root / "applications" for root in roots]


def main() -> None:
    entries = {}
    for directory in application_dirs():
        if not directory.is_dir():
            continue
        for path in directory.glob("*.desktop"):
            entry = read_desktop(path)
            if entry:
                entries.setdefault(entry["id"], entry)
    print(json.dumps(sorted(entries.values(), key=lambda item: item["name"].lower()), separators=(",", ":")))


if __name__ == "__main__":
    main()
