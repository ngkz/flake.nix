#!/usr/bin/env python3
"""
merge-preferences.py

Merge key-value pairs into Ghidra's ghidra.preferences file.
Existing values are preserved and overridden by new values.

Usage:
  merge-preferences.py <pref_file> <key1>=<value1> [<key2>=<value2> ...]
"""

import os
import sys


def main():
    if len(sys.argv) < 3:
        print("Usage: merge-preferences.py <pref_file> <key1>=<value1> [...]", file=sys.stderr)
        sys.exit(1)

    pref_file = sys.argv[1]
    pairs = sys.argv[2:]

    # Ensure parent directory exists
    os.makedirs(os.path.dirname(pref_file), exist_ok=True)

    # Read existing preferences
    existing = {}
    if os.path.exists(pref_file):
        with open(pref_file, "r") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, _, value = line.partition("=")
                    existing[key] = value

    # Merge new values
    merged = {**existing, **dict(pair.split("=", 1) for pair in pairs)}

    # Generate new content
    new_content = "".join(f"{key}={value}\n" for key, value in merged.items())

    # Only write if content changed
    if os.path.exists(pref_file):
        with open(pref_file, "r") as f:
            existing_content = f.read()
        if new_content == existing_content:
            return

    # Write back
    with open(pref_file, "w") as f:
        f.write(new_content)


if __name__ == "__main__":
    main()
