---
description: Defined Networking (dn.dev) and Nebula overlay mesh operations — config management, unsafe_routes, firewall rules, cert lifecycle, dnclient troubleshooting, and multi-network architecture for the D3 ITS mesh.
---

# Defined Networking / Nebula Operations

## Architecture

4 Nebula networks managed via dn.dev (api.defined.net):

| Network | CIDR | Purpose |
|---------|------|---------|
| Network1 | 100.100.0.0/22 | FDOT D3 production — lighthouse on pop-os |
| AI/OOBM | 100.64.3.0/24 | Home + AI services |
| Transit | 100.64.6.0/24 | Inter-network routing |
| Backup/DR | 100.64.9.0/24 | Disaster recovery |

## Key Hosts (Network1)

| Host | Overlay IP | Role |
|------|-----------|------|
| RTMC-PopOS (pop-os) | 100.100.0.1 | Lighthouse, route gateway to FDOT |
| Admin-Hub (DOTPD3CP337653) | 100.100.0.2 | Windows 10, dual-homed (Net1 + AI/OOBM) |
| d3-frr-router | 100.100.0.3 | FRR router, GRE tunnels |
| ember-lighthouse | 100.100.0.16 | Secondary lighthouse |
| ember-forge | 100.100.0.19 | Forgejo, dev VM |

## API Access

```bash
# API key in ember-keyring vault
age -d -i ~/.config/ember-keyring/identity.age \
  ~/.config/ember-keyring/vaults/ember.vault.age 2>/dev/null | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d['secrets']['svc:api.defined.net:api-key']['key'])"

# List networks
curl -s -H "Authorization: Bearer $DN_KEY" "https://api.defined.net/v2/networks" | python3 -m json.tool

# List hosts on a network
curl -s -H "Authorization: Bearer $DN_KEY" "https://api.defined.net/v2/hosts?networkID=network-YOZDU6FABM7U4TKUU36QKRVYXE"

# MCP tools also available: defined-nebula__list-hosts, get-host, get-firewall-rules, etc.
```

## Config Paths

| Platform | Config | Service |
|----------|--------|---------|
| Linux (pop-os) | `/etc/defined/config.yml` | `dnclient` (systemd) |
| Linux (AI/OOBM) | `/etc/defined/dnclient-ai/config.yml` | `dnclient.dnclient-ai` |
| Windows (Network1) | `C:\Program Files\Defined Networking\DNClient Desktop\config\host-*\config.yml` | `dnclientd` |
| Windows (AI/OOBM) | `C:\Program Files\Defined Networking\DNClient Desktop\config-ai\dnclient-ai\config.yml` | `dnclient.dnclient-ai` |

## Override Scripts (pop-os)

dnclient rewrites config.yml from dn.dev on every restart. Overrides are applied via systemd hooks:

- `/etc/defined/pre-start-overrides.sh` — patches BEFORE dnclient starts (punchy, MTU)
- `/etc/defined/apply-overrides.sh` — patches AFTER config download (profile-aware IP, punch, inactivity timeout), then sends SIGHUP

Pattern: `sed -i 's/old/new/' /etc/defined/config.yml` then `kill -HUP <pid>`

## unsafe_routes

Nebula only tunnels overlay-addressed traffic by default. To route non-overlay CIDRs through a Nebula peer:

```yaml
tun:
  unsafe_routes:
    - route: 10.175.0.0/16
      via: 100.100.0.1      # overlay IP of the gateway peer
      install: false         # let route-sync manage OS routes
```

**Critical:** When unsafe_routes exist and `default_local_cidr_any: false`, firewall rules without explicit `local_cidr` will NOT match traffic to unsafe_route CIDRs. Either set `default_local_cidr_any: true` or add `local_cidr` to each firewall rule.

## Firewall Rules

dn.dev manages firewall via API. Rules match on tags, NOT roles (despite the naming — see [[feedback_nebula_tags_roles]]).

```bash
# Get current rules
curl -s -H "Authorization: Bearer $DN_KEY" \
  "https://api.defined.net/v2/firewallRules?networkID=network-YOZDU6FABM7U4TKUU36QKRVYXE"

# MCP: defined-nebula__get-firewall-rules --networkID <id>
```

## Common Operations

### Restart dnclient
```bash
# Linux
sudo systemctl restart dnclient    # Network1
sudo systemctl restart dnclient.dnclient-ai  # AI/OOBM

# Windows (via nebula-admin or SSH)
Restart-Service -Name dnclientd -Force
```

### Check peer connectivity
```bash
# From any enrolled host
ping 100.100.0.1     # lighthouse
ping 100.100.0.2     # Admin-Hub

# dnclient status (if CLI available)
dnclient status --json
```

### Enroll a new host
```bash
# 1. Create host + enrollment code via API or MCP
# MCP: defined-nebula__create-host-and-enrollment-code

# 2. Install dnclient on the target
# Linux: curl -sL https://dl.defined.net/install | sudo bash
# Windows: download from https://dl.defined.net/windows/dnclient-desktop-latest.msi

# 3. Enroll
dnclient enroll <code>
```

### Block/unblock a host
```bash
# MCP: defined-nebula__block-host --hostID <id>
# MCP: defined-nebula__unblock-host --hostID <id>
```

## Troubleshooting

### "Invalid certificate from host — certificate is in the block list"
Host cert was revoked via dn.dev. Check `pki.blocklist` in config.yml. Re-enroll the host if needed.

### Tunnel established but no traffic
1. Check firewall rules allow the traffic (tags must match cert tags)
2. Check `default_local_cidr_any` if using unsafe_routes
3. Check MTU — dn.dev floors `tun.mtu` at 1300, but WSL/some underlays need lower (see [[project_wsl_mtu]])

### High latency / jitter spikes
1. Check punchy is enabled: `punch: true`, `respond: true` in config
2. Check `target_all_remotes: true` for direct peer connections
3. Check underlay MTU — if tunnel MTU > underlay MTU, fragmentation kills performance

### dnclient crashes on restart
Check Windows Event Log: `Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Service Control Manager'} -MaxEvents 5`

### Config keeps reverting
dn.dev pushes config on every dnclient restart. Use override scripts (Linux) or route-sync config patching (Windows) for persistent local changes.

## nebula-admin Route Tools

Custom Go binary at `~/Projects/nebula/cmd/nebula-admin/`:

| Command | Platform | Purpose |
|---------|----------|---------|
| `route-serve` | Linux | HTTP server advertising routable CIDRs (port 8844) |
| `route-sync` | Windows | Polls route-serve, installs OS routes + patches unsafe_routes |
| `route-svc-install` | Windows | Install route-sync as Windows service |
| `dn-status` | Remote | dnclient status via WinRM/SSH |
| `dn-restart` | Remote | Restart dnclient service |

## MTU Reference

| Scenario | tun.mtu | Notes |
|----------|---------|-------|
| Standard | 1300 | dn.dev default |
| WSL underlay | 1240 | WSL eth0 is only 1240, override via apply-overrides.sh |
| GRE-over-Nebula | 1200 | GRE adds 24 bytes overhead |
