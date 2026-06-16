---
description: Build context, gap analysis, and execution guide for the sovereign-command project — the in-house Go + Fiber + HTMX operator console for FDOT-D3. ICX switch fleet management is the primary surface; Ruckus AP/SmartZone management is secondary. Unifies the 399 MCP tools and migrates ICX management from SSH-based to RESTCONF where viable.
---

# Sovereign Command — Build Skill

The in-house operator console that replaces SmartZone, surfaces the 399 MCP tools, and gives FDOT-D3 a single sovereign UI for the whole network stack.

**Project root:** `~/Projects/sovereign-command/`
**Research artifacts:** `~/Projects/sovereign-command/research/`
**Companion skills:** `/smartzone` (vSZ reference), `/icx-cli` (FastIron reference)

---

## Why this exists

SmartZone is AP-centric — switches (L2/L3 ICX) are bolted on as second-class. FDOT-D3 is switch-heavy: **ICX fleet management is the operational center of gravity**, not APs. sovereign-command flips the priority: ICX gets the prime real estate; Ruckus/SmartZone AP management is a clean secondary section. We already have:

- **399 MCP tools** (255 in ember-mcp alone covering Ruckus/Fortinet/ICX/vCenter/AWX/etc.)
- **edge-platform** (Go) for routing/failover/nftables/opnsense
- **fdot-d3-ansible** for ICX automation
- **smartzone.py** prior art in `d3-noc/noc/collectors/`
- **icx_restconf_mcp_server.py** (archived, 915 lines) prior art for RESTCONF

What we don't have: **one operator UI** that ties it all together. That's sovereign-command.

---

## Stack (locked)

| Layer | Choice | Why |
|---|---|---|
| Backend | Go + Fiber v2 | Matches eve-mcp-proxy; lean; existing skill |
| Frontend | HTMX + Tailwind | No node_modules cancer; server renders fragments |
| Templating | Fiber's `html/v2` | Live reload in dev |
| Data plane | Direct calls to `ember-mcp` HTTP transport (`127.0.0.1:11600`) | All ruckus_/icx_/fw_/etc. tools already there |
| Auth | Authelia in front (already running) | Don't reinvent |
| Theme | Dark by default | Operator console, not a marketing page |

Project name is **sovereign-command**. Full stop. Not smartzone-killer.

---

## The SmartZone API surface (research output)

103 unique endpoints across 7 official Postman collections. Resource breakdown:

| Resource | Endpoints | MCP coverage today | Gap |
|---|---:|---|---|
| `/rkszones/*` | 31 | partial — list/get + get_aps/get_wlans/list_domains | **CRUD zones, ethernet port profiles, mesh, services** |
| `/aps/*` | 22 | strong — list/get/query/reboot/get_clients/get_lldp/get_operational_info | minor (move-AP, bulk-rename) |
| `/query/*` | 15 | partial — aps_query exists | client/event/alarm query filters |
| `/domains/*` | 9 | partial — list-only | **domain CRUD, admin assignment** |
| `/firewallProfiles/*` | 5 | **none** | **full gap — needed for WLAN policy** |
| `/l3AccessControlPolicies/*` | 5 | **none** | **full gap** |
| `/controller/*` | 3 | partial — system_get_info | reboot/upgrade controls |
| `/cluster/*` | 1 | system_get_cluster_status | **backup/restore endpoints** |
| `/trafficAnalysis/*` | 1 | **none** | gap |
| `/healthExtend/*` | 1 | **none** | gap |
| `/hotspots/*` | 1 | **none** | gap if WISPr ever needed |

Plus everything from `/smartzone` skill that's **not** in MCP today:
- `/configuration` backup endpoints (list / create / download / upload / restore / delete)
- `/cluster/backup`, `/cluster/restore` — cluster-level
- `/configurationSettings/scheduleBackup`, `/configurationSettings/autoExportBackup`

**Bottom line:** ~30 of the 103 endpoints have direct MCP equivalents. ~25 more are inferable (query variants, bulk ops). **~50 endpoints are gaps**, concentrated in backup/restore, policy management, and CRUD-on-zones.

---

## RUCKUS One vs vSZ (don't confuse them)

| | SmartZone (vSZ) | RUCKUS One |
|---|---|---|
| Auth | `POST /wsg/api/public/vN_M/serviceTicket` → ticket as query param | OAuth2 `POST /oauth2/token/{tenantId}` |
| Base | `https://controller:8443/wsg/api/public/vN_M/` | Cloud, tenant-scoped |
| Resources | `rkszones`, `aps`, `wlans`, `domains` | `venues`, `venues/aps`, `activities` |
| Use for sovereign-command | **Yes — this is what FDOT-D3 runs** | Only if/when we adopt the cloud platform |

The `r1-postman` repo is in research/ for future reference. Ignore for v1.

---

## ICX RESTCONF migration (parallel track)

Today: ICX managed via SSH (`fdot-d3-ansible/icx-*.yml` playbooks) + ember-mcp `icx_*` tools (also SSH-backed).

Opportunity: FastIron 08.0.80+ exposes RESTCONF. RUCKUS-One-Postman has the endpoint shape. The archived `icx_restconf_mcp_server.py` (915 lines) is the original prior art — read before designing the Go port.

Not blocking sovereign-command v1, but a clean modernization to plan in parallel.

---

## Grafana dashboards (UX reference)

Ruckus published two reference dashboards. Combined unique panels (this is the *minimum* sovereign-command should match):

| Panel | Type | Data source |
|---|---|---|
| Online APs / Total APs | gauge + bar | `ruckus_monitoring_get_ap_statistics` |
| AP Models breakdown | piechart | `ruckus_aps_list` + group-by-model |
| AP list with status | table | `ruckus_aps_list` |
| Number of clients over time | timeseries | `ruckus_monitoring_get_active_client_count` (poll) |
| Total Traffic (Rx + Tx) | stat | `ruckus_monitoring_get_wlan_statistics` aggregate |
| Online APs over time | timeseries | poll `ruckus_monitoring_get_ap_statistics` |

Their bar is low. Six panels total. We exceed it by lunchtime once the scaffold is up.

---

## Auth strategy (designed against past Ruckus CVEs)

Three auth flows we may need to support. Build the layer once, plug in providers.

| System | Flow | Notes |
|---|---|---|
| **SmartZone (vSZ)** on-prem | Service Ticket: `POST /wsg/api/public/vN_M/serviceTicket` → ticket as cookie or query param. `DELETE` same endpoint to logout. | Primary auth for FDOT-D3's vSZ cluster today. Long-lived ticket; cache it. |
| **ICX RESTCONF** (native) | HTTP Basic over HTTPS:443, or session cookies | When we migrate ICX off SSH. FastIron 08.0.80+. |
| **RUCKUS One** (cloud) | OAuth2 client-credentials: `POST /oauth2/token/{tenantId}` with `client_id`/`client_secret` → JWT, valid ~60min. Use `Authorization: Bearer <jwt>` + sometimes `x-rks-tenantid` header. | Only if/when we adopt the cloud platform. Not v1. |

**Do not repeat Ruckus's mistakes:**
- Recent (2025) CVEs against Ruckus Network Director and parts of SmartZone exposed **hardcoded JWT signing keys** — attackers forged admin JWTs and bypassed auth entirely. We design against this: no static secrets in code, all credentials live in `ember-keyring` (age-encrypted), tokens cached with TTL, refresh on 401.
- Basic Auth fallback against vSZ is sometimes accepted but explicitly **not** for production. Ticket-only.
- vSZ tickets are bearer tokens — treat them like passwords (no logs, no URL params in logs even if the API itself takes them as query params).

**Implementation order:**
1. Slice 1–4 use only ember-mcp HTTP transport (`127.0.0.1:11600`); ember-mcp already holds vSZ credentials and handles ticket lifecycle. **sovereign-command does not authenticate to vSZ directly in v1.**
2. Slice 6 (backup/restore) is the first time sovereign-command might talk to vSZ directly — at that point, build the auth package, store creds in ember-keyring, support Service Ticket + lay groundwork for JWT.
3. ICX RESTCONF auth comes in the parallel ICX-RESTCONF-migration track, not blocking v1.

---

## Build order (ICX-first, cut once)

### Slice 1 — Project scaffold + ICX fleet view (target: same day)

```
sovereign-command/
├── go.mod
├── main.go                      # Fiber, routes, ember-mcp client
├── internal/
│   ├── embermcp/client.go       # Thin HTTP client → 127.0.0.1:11600
│   └── handlers/icx.go          # First page: ICX fleet (THE MAIN EVENT)
├── views/
│   ├── index.html               # Shell with sidebar, ICX as primary nav
│   └── partials/icx-fleet.html  # Fleet table: hostname/model/firmware/uptime/status
├── static/css/output.css        # Tailwind compiled output
├── tailwind.config.js
└── package.json                 # Tailwind only — no JS framework
```

**Read-only first:** `GET /partials/icx-fleet` calls `icx_status` (no args = fleet overview), renders a Tailwind table with one row per switch. Click row → loads `icx_interfaces` + `icx_hardware` for that switch into a detail pane.

**No action buttons in slice 1.** ember-mcp doesn't expose an `icx_reboot` today — we wire actions in slice 2 either via AWX (`awx_job_launch` against an icx-reboot playbook) or by adding `icx_reboot` to ember-mcp directly.

### Slice 2 — ICX deep-dive + first action
- Per-switch detail page: interfaces table, VLANs, LLDP neighbors, OSPF, hardware/optics
- First action: `POST /api/icx/refresh/:hostname` (re-polls — safe to wire as the action shakedown)
- Then: actual reboot via AWX or new ember-mcp tool

### Slice 3 — ICX fleet operations
`icx_fleet_firmware` audit table, `icx_fleet_vlans` consistency report, `icx_compare` two-switch diff UI, `icx_find` cross-fleet search box in the topbar.

### Slice 4 — Multi-source dashboard (the landing page)
The six Grafana-equivalent panels on one page, polling every 30s via HTMX `hx-trigger="every 30s"`. Mix of ICX fleet stats + Ruckus AP stats + FortiGate health.

### Slice 5 — Ruckus AP / SmartZone (the afterthought)
List APs, basic health, reboot. Same table+action pattern as ICX. Tucked into a secondary sidebar section.

### Slice 6 — SmartZone backup/restore (closes the biggest API gap)
The configuration-backup endpoints have no MCP tool yet. Either:
(a) Add tools to ember-mcp first (preferred — keeps the API surface clean), then wire UI, OR
(b) Call SmartZone API directly from sovereign-command for these (faster, but spreads the auth logic)

Recommendation: (a). Backup/restore is operational-critical and belongs in MCP.

### Slice 7+ — FortiGate, vCenter, AWX, monitoring tiles
Same pattern. Each is a sidebar entry + 1-2 partials + actions.

---

## ember-mcp tool inventory by domain (cheat sheet)

| Domain | Prefix | Tools |
|---|---|---|
| Ruckus SmartZone | `ruckus_` | aps_*, zones_*, wlans_*, clients_*, alarms_*, monitoring_*, system_* (~30) |
| ICX switches | `icx_` | status, config, interfaces, lldp, ospf, vlans, port_status, compare, find, fleet_*, hardware (~12) |
| FortiGate | `fw_gate_` | policies, interfaces, routes, VPN, DHCP, DNS, sessions, etc. (~50) |
| FortiAnalyzer | `fw_analyzer_` | ADOMs, alerts, devices, logs, reports |
| Display walls | `dp_` | walls, windows, sources, layouts, templates, topology (~15) |
| vCenter | `vcenter_` | VMs, hosts, clusters, datastores, networks (~15) |
| AWX | `awx_` | job templates, inventories, hosts, credentials, launch (~17) |
| Miovision | `mio_` | intersections, cameras, alerts, safety, TMC |
| SunGuide | `sg_` | cameras, detectors, DMS, events, travel times, weather |
| D3Echo | `d3echo_` | alerts, CCTV, devices, DIVAS, DMS, status |
| Sessions | `session_` | create/join/send/read/state/tasks (16) |
| Syslog | `syslog_` | search, tail, alerts, hosts, stats |
| Trinity | `trinity_` | exchange, memory_add/search, rag_search, status |
| Chat | `chat_` | members, read, send |
| Shell | `shell_` | exec, read, status |
| Pass | `pass_` | vaults, items, search, TOTP |

**HTTP transport:** `127.0.0.1:11600` (ember-mcp-http) or `11700` (eve edition). Each tool is JSON-RPC over HTTP; the Go client should be ~30 lines.

---

## What NOT to build

- ❌ AP-first or AP-prominent UI. ICX is the main event; APs ride in back.
- ❌ Re-implement SmartZone's clustering / failover logic (operator UI, not a controller)
- ❌ Mirror their UI 1:1 — we replace it, we don't recreate the bad parts
- ❌ React/Vue/anything with node_modules > 50MB
- ❌ A second auth system — Authelia handles it
- ❌ Multi-tenancy or RBAC in v1 — single trusted operator surface, hardened by network position not by UI roles
- ❌ Postgres backing for sovereign-command itself — it's a UI; state lives in ember-mcp + the systems it controls
- ❌ Yet another MCP server. sovereign-command is a *consumer* of MCP, not a provider (yet)

---

## Prior art (READ BEFORE WRITING CODE)

| File | What's in it | Why it matters |
|---|---|---|
| `~/.claude/commands/smartzone.md` | Full SmartZone CLI + REST API reference, backup endpoints, MCP gap notes | The vSZ contract |
| `~/.claude/commands/icx-cli.md` | ICX show/config/firmware/stack reference, RESTCONF mapping | The ICX contract |
| `~/Projects/d3-noc/noc/collectors/smartzone.py` | Working serviceTicket auth + GET/POST helpers in Python (httpx) | Auth pattern proof |
| `~/Projects/.claude/worktrees/jovial-davinci/archive/python-mcp-legacy/icx_restconf_mcp_server.py` | 915 lines — full RESTCONF MCP server, includes the switch inventory | ICX RESTCONF reference |
| `~/Projects/fdot-d3-ansible/inventories/production/group_vars/smartzone.yml` | vSZ host + vault refs | Connection details |
| `~/Projects/eve-mcp-proxy/` | Existing Fiber + JWT + SQLite Go service | Closest stack twin; copy patterns |
| `~/Projects/sovereign-command/research/endpoints_inventory.json` | 103 SmartZone + 62 RUCKUS One endpoints in JSON | Programmatic gap analysis |

---

## Open decisions

1. **Backup/restore MCP tools** — add to ember-mcp now, or v2? *Recommend: now, before slice 4.*
2. **WebSocket vs polling for live updates** — HTMX SSE extension or `hx-trigger="every Ns"`? *Recommend: polling for v1; SSE if/when we hit refresh-flicker pain.*
3. **Theming** — Tailwind dark only, or operator-selectable theme? *Recommend: dark only v1.*
4. **Public exposure** — is this on `bailey-home.org` behind Authelia, or LAN-only? *Recommend: LAN-only until v3.*

Resolve as you go. Don't pre-decide.

---

## Quick-start (copy/paste when ready to swing)

```bash
cd ~/Projects/sovereign-command
go mod init forge.bailey-home.org/sovereign-command
go get github.com/gofiber/fiber/v2 github.com/gofiber/template/html/v2
mkdir -p internal/embermcp internal/handlers views/partials static/css
# Then: write main.go, internal/embermcp/client.go, internal/handlers/aps.go,
# views/index.html, views/partials/aps.html. That's slice 1.
```

When generating the scaffold, read `~/Projects/eve-mcp-proxy/main.go` first — it's the closest stack twin and has all the Fiber patterns already proven against your environment.
