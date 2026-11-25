#!/usr/bin/env python3
"""Localization key gate: source keys must exist in the package's xcstrings catalog.

For each package given on the command line (directory name under Packages/ or
Vendor/), collect every key passed to ``pluginLocalization.string("<key>")``
or ``pluginLocalization.count("<singular>", "<plural>", for:)`` in the
package's Sources, and verify it against ``Resources/Localizable.xcstrings``.

Packages without a catalog or without pluginLocalization call sites are
skipped.

Checks per package:
1. Every used key exists in Resources/Localizable.xcstrings.
2. Each used key has a non-empty ``en`` stringUnit value equal to the key
   (English is the source language), except allow-listed semantic keys.
3. Each used key has a non-empty ``zh-Hans`` value (existing translations
   stay).
4. No catalog key contains Chinese characters (keys must be English).

Exit code 1 on any failure.
"""

import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRING_RE = re.compile(r'pluginLocalization\.string\("([^"]*)"')
COUNT_RE = re.compile(r'pluginLocalization\.count\("([^"]*)",\s*"([^"]*)"')

# Legacy semantic-key style (key names a concept; en value is the text).
# These predate the en-key invariant; unify later, do not fail the gate today.
SEMANTIC_KEY_ALLOWLIST = {
    "PluginLLMProviderMiniMax": {
        "Reset time format",
        "Used %lld / %lld",
        "Duration.days",
        "Duration.hours",
        "Duration.minutes",
        "Duration.seconds",
    },
}


def packages_in_use():
    out = subprocess.run(
        ["git", "ls-files"], cwd=REPO, capture_output=True, text=True
    ).stdout
    pkgs = set()
    for line in out.splitlines():
        m = re.match(r"(?:Packages|Vendor)/([^/]+)/", line)
        if m:
            pkgs.add(m.group(1))
    return sorted(pkgs)


def check_pkg(root_name):
    problems = []
    for base in ("Packages", "Vendor"):
        pkg_root = os.path.join(REPO, base, root_name)
        if os.path.isdir(pkg_root):
            break
    else:
        return [f"{root_name}: package directory not found"]

    catalog_path = os.path.join(pkg_root, "Resources", "Localizable.xcstrings")
    if not os.path.exists(catalog_path):
        return None  # no catalog; nothing this gate can check yet

    with open(catalog_path, encoding="utf-8") as f:
        catalog = json.load(f).get("strings", {})

    used = set()
    calls = 0
    for path in glob_swift(os.path.join(pkg_root, "Sources")):
        lines = open(path, encoding="utf-8").readlines()
        # Scan code only — doc comments carry pattern examples like "<English>".
        src = "".join(
            line
            for line in lines
            if not line.lstrip().startswith(("/", "//", "*"))
        )
        n1 = len(STRING_RE.findall(src)) + 2 * len(COUNT_RE.findall(src))
        calls += n1
        used.update(k.replace('\\"', '"') for k in STRING_RE.findall(src))
        used.update(
            k.replace('\\"', '"')
            for pair in COUNT_RE.findall(src)
            for k in pair
        )

    if calls == 0:
        return None  # package does not use pluginLocalization yet

    allowlist = SEMANTIC_KEY_ALLOWLIST.get(root_name, set())

    for key in sorted(used):
        entry = catalog.get(key)
        if entry is None:
            problems.append(f"{root_name}: key not in catalog: {key!r}")
            continue
        locs = entry.get("localizations", {})
        en = locs.get("en", {}).get("stringUnit", {}).get("value")
        zh = locs.get("zh-Hans", {}).get("stringUnit", {}).get("value")
        if not en:
            problems.append(f"{root_name}: missing en value: {key!r}")
        elif en != key and key not in allowlist:
            problems.append(
                f"{root_name}: en value {en!r} != key {key!r} "
                "(en is the source language)"
            )
        if not zh:
            problems.append(f"{root_name}: missing zh-Hans value: {key!r}")

    for key in catalog:
        if re.search(r"[\u4e00-\u9fff]", key) and key not in allowlist:
            problems.append(f"{root_name}: catalog key contains Chinese: {key!r}")

    return problems


def glob_swift(dirpath):
    pattern = os.path.join(dirpath, "**", "*.swift")
    return [p for p in __import__("glob").glob(pattern, recursive=True)]


def main():
    args = sys.argv[1:]
    targets = packages_in_use() if (not args or args == ["all"]) else args
    failures = []
    checked = []
    for name in targets:
        try:
            problems = check_pkg(name)
        except Exception as exc:  # defensive: report, do not crash the gate
            problems = [f"{name}: check crashed: {exc}"]
        if problems:
            failures.extend(problems)
        else:
            checked.append(name)

    print(f"checked {len(checked)} packages with pluginLocalization usage")
    for name in checked:
        print(f"  OK {name}")
    if failures:
        print(f"\n{len(failures)} problem(s):")
        for p in failures:
            print(" ", p)
        sys.exit(1)
    print("all passed ✅")


if __name__ == "__main__":
    main()
