#!/usr/bin/env bash
# Run every repository check. CI runs this same script, so green here means green there.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# A commit-time guard, not a check of the tree: it would fail whenever this runs on main
export SKIP="${SKIP:+$SKIP,}no-commit-to-branch"

# --locked fails if uv.lock is out of sync with pyproject.toml
uv run --locked pre-commit run --all-files --show-diff-on-failure
uv run --locked pre-commit run gitleaks-history --hook-stage manual --all-files
