#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""__NAME__ - one line on what this does.

Run directly (`__NAME__ ARG`); uv builds a cached env from the dependencies
block above on first run. Add a dependency with `uv add --script <file> <pkg>`.
"""

from __future__ import annotations

import argparse


def main() -> int:
    """Parse arguments and do the work. Returns the process exit code."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("arg", help="what this argument is")
    args = parser.parse_args()
    print(f"hello from __NAME__ with {args.arg}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
