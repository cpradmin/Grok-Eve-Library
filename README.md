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

## Using the Shared Skills Library

This repo mirrors the central skill library (originally at the internal Forge).

### For local Claude Code or Grok CLI (Eve)
Clone or keep a local copy, then symlink:

```bash
git clone https://github.com/cpradmin/claude-library.git ~/Projects/claude-library
mkdir -p ~/.claude/skills ~/.grok/skills

# Symlink standalone
for skill in ~/Projects/claude-library/standalone/*/; do
  name=$(basename "$skill")
  [ ! -e ~/.claude/skills/"$name" ] && ln -s "$skill" ~/.claude/skills/"$name"
  [ ! -e ~/.grok/skills/"$name" ] && ln -s "$skill" ~/.grok/skills/"$name"
done

# Symlink bundles
for bundle in ~/Projects/claude-library/skills/*/; do
  name=$(basename "$bundle")
  [ ! -e ~/.claude/skills/"$name" ] && ln -s "$bundle" ~/.claude/skills/"$name"
  [ ! -e ~/.grok/skills/"$name" ] && ln -s "$bundle" ~/.grok/skills/"$name"
done
```

To update:
```bash
cd ~/Projects/claude-library && git pull origin main && git push github main
```

### For web Grok (grok.com)
Point Grok to this repo. Instruct it:

"The shared skills are in https://github.com/cpradmin/claude-library

Load on demand:
- Standalone skill 'foo': https://raw.githubusercontent.com/cpradmin/claude-library/main/standalone/foo/SKILL.md
- Skills inside bundles (e.g. nebula inside _ember-skills): https://raw.githubusercontent.com/cpradmin/claude-library/main/skills/_ember-skills/nebula/SKILL.md

Browse the tree for full list: https://github.com/cpradmin/claude-library/tree/main/standalone

Always fetch the raw SKILL.md and follow its rules, workflows, and 'always load' notes exactly when the task matches."

Individual skill pages on GitHub also render the markdown nicely.

