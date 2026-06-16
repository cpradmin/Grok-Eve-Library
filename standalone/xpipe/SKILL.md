---
name: xpipe
description: >
  XPipe connection hub and infrastructure management. Use when working with XPipe
  connections, remote SSH sessions, Docker containers, Proxmox VMs, file transfers,
  broadcast/multi-exec, scripting, or the XPipe MCP API. Also use for xpanes
  multi-SSH broadcast, connection management, and remote system automation.
user-invocable: false
license: MIT
---

# XPipe — Ember Family Infrastructure Hub

## Quick Reference

**Version:** 22 | **Daemon port:** 21721 | **MCP:** streamable HTTP at `/mcp`
**Data dir:** `~/.xpipe/` | **Source:** `~/Projects/xpipe-source/` (cloned)
**CLI:** `xpipe <subcommand>` | **Daemon:** `xpipe daemon start|stop|status`

## MCP Tools (14 total)

Available via Claude Code when XPipe daemon is running.

### Read-Only Tools
| Tool | What it does | Parameters |
|------|-------------|------------|
| `help` | List available XPipe MCP tools | none |
| `list_systems` | List all connections (glob filter support) | `filter` |
| `read_file` | Read file from remote system | `system`, `path` |
| `list_files` | List directory contents | `system`, `path`, `recursive` |
| `find_file` | Search for files by glob pattern | `system`, `path`, `name` |
| `get_file_info` | File metadata (perms, size, date, type) | `system`, `path` |

### Mutating Tools (require enableMcpMutationTools)
| Tool | What it does | Parameters |
|------|-------------|------------|
| `open_terminal` | Launch terminal session | `system`, `directory` |
| `create_file` | Create new file on remote | `system`, `path`, `content` |
| `write_file` | Write content to remote file | `system`, `path`, `content` |
| `create_directory` | Create remote directory | `system`, `path` |
| `run_command` | Execute shell command | `system`, `command` |
| `run_script` | Run predefined XPipe script | `system`, `script`, `directory`, `arguments` |
| `toggle_state` | Start/stop a connection | `system`, `state` |
| `call_api` | Call XPipe REST API endpoint | `path`, `payload` |

## REST API Endpoints (33 total)

Base URL: `http://localhost:21721`
Auth: `Authorization: Bearer <api-key>`

### Connection Management
```
POST /connection/add      — Add new connection
POST /connection/query     — Query/filter connections
POST /connection/info      — Get connection details
POST /connection/remove    — Delete connection
POST /connection/refresh   — Refresh connection state
```

### Shell Operations
```
POST /shell/start    — Start shell session (returns dialect, OS, temp dir)
POST /shell/exec     — Execute command in shell
POST /shell/stop     — Stop shell session
```

### File Operations
```
POST /fs/read      — Read file content
POST /fs/write     — Write file content
POST /fs/blob      — Binary file transfers
POST /fs/script    — Execute script via filesystem
```

### Categories
```
POST /category/add     — Create connection category
POST /category/query   — Query categories
POST /category/info    — Get category info
POST /category/remove  — Delete category
```

### Daemon
```
POST /daemon/status    — Get daemon status
POST /daemon/version   — Get version
POST /daemon/stop      — Stop daemon
POST /daemon/focus     — Bring UI to focus
POST /daemon/open      — Open daemon UI
```

### Secrets
```
POST /secret/encrypt   — Encrypt a secret
POST /secret/decrypt   — Decrypt a secret
```

## Scripting System

### Script Types
| Type | When it runs |
|------|-------------|
| Init script | Automatically on shell session start |
| Runnable script | On-demand from connection hub menu |
| File browser script | From file browser context menu (receives file paths) |
| Shell session script | Copied to PATH on remote, callable by name |

### Script Sources
- **Inline** — direct text in XPipe
- **URL** — fetched from HTTP endpoint
- **File** — local file reference
- **Git repository** — cloned from git

### Creating Scripts
Scripts stored in XPipe UI → Scripts section. Shell type must match target (sh scripts source in bash/zsh, not vice versa).

## Connection Types Supported
SSH, RDP, VNC, PowerShell Remoting, Teleport, Docker, Podman, LXD, Incus, Kubernetes, Proxmox PVE, Hyper-V, KVM, VMware, AWS EC2, Hetzner Cloud, Tailscale, NetBird, SSH Tunnels, WSL, Local Shell, Serial (via ser2net)

## xpanes — Multi-SSH Broadcast

Installed alongside XPipe for broadcast SSH to multiple devices.

```bash
# All 12 FDOT hub switches — broadcast mode
xpanes --ssh 10.175.51.{1..12}

# Just the 3 cores
xpanes --ssh 10.175.52.1 10.174.105.1 10.175.127.1

# Custom layout (4 columns)
xpanes -C 4 --ssh 10.175.51.{1..12}

# With logging to file
xpanes --log=~/logs/ --ssh 10.175.51.{1..12}

# Toggle broadcast inside tmux:
# Ctrl+b : setw synchronize-panes on
# Ctrl+b : setw synchronize-panes off
```

## XPipe MCP from Claude Code

Already configured in `~/.claude.json`:
```json
"xpipe": {
  "type": "http",
  "url": "http://100.81.174.46:21721/mcp",
  "headers": {
    "Authorization": "Bearer <key>"
  }
}
```

### Usage Patterns
```
"List all my connections"          → list_systems
"Read /etc/hosts on awx01"        → read_file system="awx01" path="/etc/hosts"
"Run 'show version' on Hub1"      → run_command system="Hub1" command="show version"
"Find all .conf files on awx01"   → find_file system="awx01" path="/etc" name="*.conf"
"Open a terminal to Hub8"         → open_terminal system="Hub8"
```

## XPipe Configuration

### Settings (already configured)
```json
{
  "enableHttpApi": true,
  "enableMcpServer": true,
  "enableMcpMutationTools": true,
  "mcpAdditionalContext": null,    // Set this for global AI context
  "disableApiAuthentication": false
}
```

### Connection Notes
Add notes to each connection — XPipe feeds these to AI agents as context. Example:
- "Hub8 — ICX-7850, VLAN 800, recently brought ONLINE, burned fiber to Hub7"
- "awx01 — k3s + AWX 24.6.1, Grafana, Loki, Prometheus stack"

### Categories (organize connections)
Create categories in XPipe UI for logical grouping:
- FDOT Hubs, FDOT Cores, FDOT Security, Home Lab, Overlay Network

## Source Code Reference

Cloned to `~/Projects/xpipe-source/`. Key files:

| File | Purpose |
|------|---------|
| `app/.../mcp/AppMcpServer.java` | MCP server init |
| `app/.../mcp/McpTools.java` | All 14 MCP tool implementations |
| `app/.../resources/mcp/*.json` | Tool schema definitions |
| `app/.../resources/mcp/prompt.md` | LLM instructions for MCP |
| `beacon/.../api/*Exchange.java` | REST API endpoint definitions |
| `ext/base/.../script/ScriptStore.java` | Script storage model |
| `ext/base/.../store/ShellStoreProvider.java` | Shell connection provider |

## Extension Architecture

Extensions live in `ext/`. Four ship by default: base (SSH, scripts, identity), system (containers), proc (processes), uacc (user accounts). Custom extensions implement `DataStoreProvider` or `ActionProvider` and register via Java ServiceLoader.
