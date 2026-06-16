# Claude Library

Central skill and plugin library for Claude Code. Shared across all machines via Forgejo.

## Structure

- `skills/` — Source bundles (underscore-prefixed = marketplace installs)
- `plugins/` — Plugin source bundles
- `standalone/` — Custom/standalone skill installs

## Usage

Each machine symlinks `~/.claude/skills/_*` and `~/.claude/plugins/_*` into this repo.
Individual skill symlinks (e.g. `~/.claude/skills/docx`) point into the source bundles
and resolve through the chain automatically.

## Machines

- admin-hub (nova) — primary
- pop-os (nova) — FDOT workstation
