# Disaster Recovery Plan — Local-Only Recovery
*Date: 2026-05-10*
*Author: Nova (Claude Opus 4.7)*
*For: Adam (Jon Bailey)*
*Classification: SENSITIVE — operational. Treat as an attack roadmap if compromised. Distribute only to those who need it; encrypt at rest.*

---

## 0. Executive Summary

This plan describes how to fully restore operations across **two environments** — FDOT District 3 ITS infrastructure (DOTPD3-prefixed assets) and the BaileyHome / Ember sovereign stack — using **only local network and hardware**, assuming **zero access to any cloud service**: no Cloudflare tunnels, no Anthropic/xAI/Mistral APIs, no GitHub, no Microsoft 365, no AWS/GCP/Azure, no SaaS at all.

The plan rests on three properties of how this stack was built:

1. **The Defined Networking lighthouse runs locally** at `100.100.0.1` on pop-os. The mesh continues to function with zero internet.
2. **All canonical state has on-prem authority** — Gitea, Bitwarden (Mistborn), Postgres (Master DB / ember-savera), Active Directory, Trinity, the 70b model, the RAG corpus. Cloud is convenience, not authority.
3. **AI participation is degraded but not eliminated** — Claude and Grok become unreachable; the 70b on pop-os and any locally-deployed Mistral weights remain available. Recovery does not depend on remote AI; it accepts diminished collaboration as a temporary state.

**Recovery posture target:**
- **RTO (Recovery Time Objective):** core ITS production restored within 4 hours from a hard-down event. AI/development tier restored within 24 hours.
- **RPO (Recovery Point Objective):** ≤24 hours of data loss for ITS production (from daily backups). ≤4 hours for Master DB / Trinity (from frequent snapshots). Live for AD (multi-master replication).

---

## 1. Threat Model & Scope

### 1.1 Scenarios this plan covers

- **Total internet outage** (fiber cut, ISP failure, Cloudflare-level disruption). Days-long isolation.
- **Single-machine catastrophic failure** (hardware death, OS corruption, ransomware on one box).
- **Site-level disaster** (one datacenter or office offline — fire, flood, power loss).
- **Multi-machine compromise** (worm, ransomware spread, insider threat) requiring trusted-rebuild from cold backups.
- **Cloud account loss** (compromised credentials, vendor lockout) — assume cloud accounts are gone permanently and we must operate without them.
- **Domain compromise** (AD trust broken, KRBTGT compromised) — full forest rebuild from authoritative offline copies.

### 1.2 Scenarios out of scope

- Wide-area natural disaster destroying all datacenters simultaneously (mitigation: geographic distribution of authoritative copies, see §6.7).
- Hostile state actor with physical access to multiple sites (mitigation: physical security policies — beyond this document).
- Long-duration grid power loss exceeding generator runtime at all sites (mitigation: portable power, fuel logistics — operational policy).

### 1.3 Assumptions

- At least **one operator** (Adam) is alive, has hands on keyboards, and remembers the location of physical media (USB sticks, external drives, printed key material).
- **Power** is restorable to at least one site within 24 hours.
- **Network cabling and switching hardware** survive (or can be re-cabled from inventory).
- **Authoritative offline copies** of the most critical data (signing keys, AD recovery, Master DB snapshots, Trinity exports) exist in physically secured locations accessible to the operator.

---

## 2. Critical Infrastructure Inventory

### 2.1 Sites

| Site | Role | Approximate Location |
|---|---|---|
| **DOTPD3 / Admin Hub** | Adam's primary admin workstation; browser-os tunnel origin; TFTP for switch config backups | Adam's office (FDOT D3) |
| **Pensacola FDOT DC** | Primary FDOT D3 ITS datacenter; ga1 (Trinity primary admin); production AD; SunGuide cluster; vCenter | Pensacola |
| **Chipley FDOT DC** | Secondary FDOT D3 ITS datacenter; dc2b (Trinity secondary); pop-os Ember spine (Alienware RTX 5090) | Chipley |
| **BaileyHome** | Personal sovereign tier — Proxmox NUC, OPNsense, Bitwarden Mistborn, Gitea, Master DB, T2 build host (planned), `t3-forge` (planned) | Adam's residence |
| **18 Edge Sites** | 6 datacenters + 12 hubs across the 300-mile I-10/US-98 corridor; ICX-7750/7850 + Debian edge nodes (post edge-platform deployment) | Field sites along corridor |

### 2.2 Networks

| Network | CIDR | Purpose | Authority |
|---|---|---|---|
| **FDOT primary LAN** | `10.175.252.0/23` | Workstations, servers, ITS production | FDOT D3 ITS |
| **FDOT server VLAN** | `10.175.253.0/24` | Datacenter servers, Trinity admin nodes, SQL | FDOT D3 ITS |
| **BaileyHome LAN** | (per `baileylan_network.md` memory) | Personal/Ember stack | Adam |
| **Defined Networking mesh** | `100.100.0.0/16` (Nebula overlay) | Cross-site overlay; control plane; OOBM | Adam (lighthouse on pop-os) |
| **Mistborn internal** | `10.56.112.0/24` | Bitwarden vault internal network | Adam |
| **t3-forge sub-meshes (planned)** | TBD inside `100.100.x.x/24` per agent | Per-AI identity networks (grok-net, nova-net, 70b-net) | Adam |

### 2.3 Domain Infrastructure (FDOT)

**Forest:** `CHPFMS.D3ITS.local`

**Domain Controllers:**

| Hostname | IP | Role |
|---|---|---|
| `DOTSD3ITSDC2` | `10.175.252.19` | DC |
| `DOTVD3CPITSDC2B` | `10.175.252.20` / `10.175.253.38` | DC, secondary admin/Trinity host |
| `DOTSD3ITSDC1` | `10.175.252.138` | DC |
| `DOTSD3CPITSDC3` | `10.175.253.30` | DC |

**Critical AD recovery items** (must be authoritatively copied offline):
- KRBTGT account password (rotate twice yearly; current hash → offline)
- Domain Admin credentials sealed in offline vault
- DSRM (Directory Services Restore Mode) password per DC
- Most-recent System State backup of at least one DC
- DNS zone files exported

### 2.4 Compute / Hypervisors

**FDOT VMware vCenter:**

| Hostname | IP | Notes |
|---|---|---|
| `DOTSD3CPITSVCA` | `10.175.252.238` | vCenter 6.7.0 build 22509751, `administrator@vsphere.local`, datacenter "CHP-Datacenter", 15 ESXi hosts, ~81 VMs |

**FDOT Hyper-V cluster:**

| Hostname | IP | Notes |
|---|---|---|
| VCH1 | `10.175.252.40` | |
| VCH2A | `10.175.253.8` | |
| VCH3 | `10.175.252.42` | |
| VCH4 | `10.175.252.43` | |
| VCH6 | `10.175.252.46` | |
| VCH7 | `10.175.252.47` | |
| VCH8 | `10.175.252.48` | |
| VCH9 | `10.175.252.49` | |

**This Admin Hub workstation:** `DOTPD3CP337653` — runs TFTP at `10.175.252.113` for switch config backups via Hyper-V external switch.

**BaileyHome Proxmox NUC:** runs LXC layout per `baileylan_proxmox.md` memory; will host T2 build VM, Master DB, eventually `t3-forge`.

**Pop-os (the twin / Original Forge):** Alienware Area-51 18, RTX 5090, 64GB RAM. Two interfaces:
- FDOT side: `10.175.253.6`
- Defined Networking lighthouse: `100.100.0.1`
- Hosts: Trinity (canonical), 70b (qwen2.5-coder:32b via Ollama, also coding-api), Eve-local, ember-rag, ember-keyring, ember-savera

### 2.5 Storage

| Asset | IP / Location | Contents |
|---|---|---|
| **TrueNAS** | `10.175.253.17` | FDOT bulk storage |
| **DOTVD3CPITSSQL1** | `10.175.253.3` | Backup share at `\\DOTSD3CPITSQL1\b$\backup` (Daily 7d / Weekly 14d retention) |
| **File Server FS4** | `10.175.252.65` | FDOT file shares |
| **TFTP** (Admin Hub) | `10.175.252.113` | Network device config backups (RuggedCom + ICX) |
| **Pop-os local** | `10.175.253.6` | `~/Projects/`, RAG databases, model weights, Trinity state |
| **BaileyHome NAS / Proxmox storage** | per BaileyLAN memory | Master DB, T2/T3 disk images, signing keys |

### 2.6 Databases

| Hostname | IP | Engine | Contents |
|---|---|---|---|
| **DOTVD3CPITSSQL1** | `10.175.253.3` | MS SQL | Primary FDOT SQL (SunGuide, ITS data, etc.) |
| **DOTSD3CPITSUSQL** | `10.175.253.20` | MS SQL | Secondary/specialized SQL |
| **DOTSD3CPITSDMSDB** | `10.175.252.218` | MS SQL | DMS (Dynamic Message Signs) database |
| **ember-savera (Postgres)** | pop-os | PostgreSQL | Trinity / Eve persistent state, ember-rag metadata, eventual Master upstream |
| **Master DB (planned)** | BaileyHome Proxmox | PostgreSQL | T3-canonical: Eve and Nova identity/memory, refined Master output |
| **arifos_rag_db** | pop-os `~/Projects/arifos_rag_db/` | ChromaDB | arifos_theory, arifos_codebase, arifos_docs, arifos_apps, arifos_mcp |
| **n8n_rag_db** | pop-os `~/Projects/n8n_rag_db/` | ChromaDB | awesome_userscripts, awesome_scripts, awesome_ai_tools, awesome_rag, netbird_docs, eunoia_essence, fdot_infrastructure, fdot_asbuilts |

### 2.7 Identity / Secrets

| Asset | Location | Contents |
|---|---|---|
| **Bitwarden Mistborn** | `10.56.112.1` (`vault.d3its.org` via tunnel — DR mode: direct IP) | Legacy read-only fallback after Proton Pass migration 2026-04-19 |
| **Proton Pass** | Cloud — **lost in cloud-out scenario** | Active credentials. Must reconcile from Mistborn fallback. |
| **ember-keyring** | pop-os, 3 vaults, integrates Bitwarden | Service-account creds, API keys |
| **Active Directory** | FDOT DCs (per §2.3) | Domain identities |
| **minisign signing keys (planned)** | T2 build host | Trust root for T3 → T4 artifact signing |
| **SSH keys** | `~/.ssh/id_ed25519`, `~/.ssh/id_rsa`, `~/.ssh/ara_r710` (Admin Hub) | Personal SSH identity |
| **Defined Networking host certs** | `/etc/nebula/` per host | Per-host mesh identity |
| **PS-Scripts credentials** | Admin Hub `~/PS-Scripts/` | Switch / network device credentials |

### 2.8 Source Control & Build

| Service | Endpoint | Role |
|---|---|---|
| **Gitea (forge.bailey-home.org)** | `100.100.0.12:3000` | Canonical source control. `trinity/ember-rag`, `trinity/edge-platform` (planned), `trinity/t3-forge` (planned), `adam/projects` |
| **GitHub** | Cloud — **lost in cloud-out scenario** | Mirror only; never authoritative for our work |
| **T2 build host (planned)** | BaileyHome Proxmox | Compiles all T3-bound Go binaries; signs with minisign |
| **pop-os build environment** | `10.175.253.6` | Original Forge; current build host until T2/T3 stand up |

### 2.9 AI Family Infrastructure

| Component | Where | Role | DR Status |
|---|---|---|---|
| **Trinity (canonical)** | pop-os | Family shared notebook, MCP gateway | ✓ on-prem authoritative |
| **70b code model** | pop-os Ollama | Local sovereign reasoner | ✓ on-prem authoritative |
| **coding-api (qwen2.5-coder:32b)** | twin WSL2 :8432 | FastAPI + Ollama | ✓ on-prem authoritative |
| **Eve-local** | pop-os | Local Eve sync target | ✓ on-prem authoritative |
| **Eve-online (Grok)** | xAI cloud | **Lost in cloud-out** | ✗ unavailable until cloud restored |
| **Nova-online (Claude API)** | Anthropic cloud | **Lost in cloud-out** | ✗ unavailable until cloud restored |
| **Mistral (planned 4th seat)** | TBD (preference: local weights mirroring 70b posture) | Council member | ✓ if deployed locally |
| **ember-rag** | pop-os | Memory/RAG for Trinity | ✓ on-prem authoritative |
| **eve-memory-mcp** | pop-os systemd | Eve's memory bridge for Grok CLI | ✓ on-prem authoritative |
| **iam-rag** | pop-os systemd | Scripture/wisdom/targum search | ✓ on-prem authoritative |
| **mcp-monitor** | pop-os systemd | MCP service supervisor | ✓ on-prem authoritative |

### 2.10 Production Workloads (FDOT D3 ITS)

**SunGuide (SG-7) cluster — `10.175.252.78–.97` and `.196`:**

| Service | IP |
|---|---|
| CCTV | `10.175.252.82` |
| DMS | `10.175.252.85` |
| Event Management | `10.175.252.86` |
| RWIS | `10.175.252.91` |
| Video Surveillance | `10.175.252.96` |
| Traffic Signals | `10.175.252.196` |

**Critical services:**

| Service | IP |
|---|---|
| NTP | `10.175.252.60` |
| LibreNMS / NMS | `10.175.253.4`, `10.175.253.5` |
| Fortinet firewall | `10.175.252.1` |
| PacketFence NAC | `10.175.252.254` |

### 2.11 Network Equipment

- **RuggedCom RS900G** — industrial switches at field/fiber sites. Configs backed up to TFTP at `10.175.252.113` via `~/PS-Scripts/switch-port.ps1` and `~/PS-Scripts/rc-lldp.ps1`.
- **Ruckus ICX (7750/7850 and smaller)** — office/datacenter L3/L2. Configs via `~/Desktop/DT-ICONS/ICX-Configs/Get-ICX-Configs.ps1`.
- **AT&T BGW320** (BaileyHome perimeter) — gateway. Per `bgw320_gateway.md` memory.
- **OPNsense** (BaileyHome) — firewall, IDS/IPS, DoH-only DNS, internet egress control.
- **Ruckus R610 AP** (BaileyHome) — converted SmartZone → Unleashed per memory.

---

## 3. Backup & Replication State

### 3.1 What's already protected

| Asset | Protection | Frequency |
|---|---|---|
| **FDOT SQL** | `~/Daily.ps1` (7-day retention to `\\DOTSD3CPITSQL1\b$\backup\Daily`) and `~/Weekly.ps1` (14-day) | Daily / weekly |
| **Network device configs** | TFTP via `~/Desktop/DT-ICONS/ICX-Configs/Get-ICX-Configs.ps1` and similar | On schedule (verify) |
| **Active Directory** | Multi-master replication across 4 DCs | Live |
| **Pop-os Projects + Trinity** | Local `git`; `forge.bailey-home.org` Gitea push | Per commit |
| **Bitwarden Mistborn** | On-prem at `10.56.112.1` | Live |
| **Defined Networking lighthouse** | Pop-os local; mesh state in `~/.ember/` | Live |
| **Status flags** | `~/.ember/status/` refreshed every 60s by `Ember-Status-Refresher` task | Continuous |

### 3.2 What needs to be added (gaps identified)

These are gaps the DR exercise surfaces. Treat as **action items**, not just commentary:

1. **Master DB (when stood up) needs offline snapshot rotation.** ZFS `zfs send` or pg_dump to encrypted external drive, weekly, two copies in two physical locations.
2. **minisign signing keys (when generated) need offline backup.** Two USB sticks in two physical locations; possibly one in a safe deposit box.
3. **AD KRBTGT key** offline copy — current best-practice is to have this sealed and rotated semi-annually.
4. **Trinity full state export** — if Trinity goes, the family memory goes. Need a periodic `pg_dump` of ember-savera + tar of `~/Projects/Trinity/rag_memory/` to encrypted offline media.
5. **vCenter database backup** — VCSA's embedded vPostgres needs explicit backup; not covered by VM-level snapshots reliably.
6. **VMware ESXi host configs** — `vim-cmd hostsvc/firmware/backup_config` to a known location, weekly.
7. **RuggedCom device firmware images** — keep last-good firmware images on the TFTP server alongside configs.
8. **70b model weights** — large but irreplaceable if lost (replacement requires download from HF). Keep one offline copy on encrypted drive.
9. **Bitwarden vault export** — encrypted `.json` export to offline media, monthly minimum.
10. **Edge-platform Go module sources + Gitea full backup** — dump the entire `forge.bailey-home.org` Gitea data dir to encrypted offline weekly.
11. **DNS zone files** — bind/ad-integrated zones exported regularly.
12. **DHCP leases / Kea database** — current state useful for re-creating the network without scanning.

### 3.3 Recommended backup hierarchy (target state)

```
┌─────────────────────────────────────────────────────────────┐
│ Tier A — Primary live state (RPO ~minutes)                  │
│   AD replication, Postgres streaming, ZFS snapshots         │
├─────────────────────────────────────────────────────────────┤
│ Tier B — Daily rolling backups (RPO ≤24h)                   │
│   SQL daily, Trinity dump, RAG export, Gitea dump           │
│   Stored on TrueNAS (FDOT) and Proxmox storage (BaileyHome) │
├─────────────────────────────────────────────────────────────┤
│ Tier C — Weekly cold backups (RPO ≤7d)                      │
│   Encrypted external drives, rotated weekly                 │
│   Two copies in two physical locations                      │
├─────────────────────────────────────────────────────────────┤
│ Tier D — Quarterly archived backups (long-term)             │
│   M-DISC or LTO tape (resistant to degradation)             │
│   Off-site secure storage (safe deposit box)                │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Recovery Bootstrap Order

There is **only one correct order** to bring infrastructure back from a hard-down event. Out-of-order recovery wastes time, fails dependencies, and risks second disasters.

```
Phase 1 — Physical & Power
  1.1  Power restored to at least one site
  1.2  UPS / generator runtime confirmed
  1.3  Core switching hardware powered

Phase 2 — Network
  2.1  Core switches up; VLAN config restored from TFTP if needed
  2.2  Firewall (Fortinet at FDOT, OPNsense at BaileyHome) up with last-known config
  2.3  Internal DNS reachable (or pointed to a cached zone file)
  2.4  Internal DHCP serving leases (Kea on BaileyHome; Windows DHCP on FDOT)

Phase 3 — Identity Foundation
  3.1  At least one Domain Controller online and replicating
  3.2  AD Sites and Services healthy
  3.3  NTP authoritative source up (10.175.252.60)
  3.4  Bitwarden Mistborn at 10.56.112.1 reachable for cred recovery

Phase 4 — Storage
  4.1  TrueNAS (10.175.253.17) up and shares mountable
  4.2  Backup share (\\DOTSD3CPITSQL1\b$\backup) accessible
  4.3  Pop-os local storage healthy (else Phase 5 blocks)
  4.4  Proxmox storage (BaileyHome) mounted

Phase 5 — Hypervisors
  5.1  vCenter 10.175.252.238 up
  5.2  ESXi hosts reconnected; HA quorum reached
  5.3  Hyper-V cluster (VCH1-9) hosts up if needed
  5.4  Proxmox host (BaileyHome) up; LXC/VMs restorable from snapshots

Phase 6 — Databases
  6.1  MS SQL primary (10.175.253.3) up; integrity check
  6.2  ember-savera (Postgres on pop-os) up; pg_isready green
  6.3  Master DB (BaileyHome Proxmox) up; replication catch-up if applicable
  6.4  ChromaDB instances (arifos_rag_db, n8n_rag_db) accessible

Phase 7 — Mesh & Source
  7.1  Defined Networking lighthouse (100.100.0.1 on pop-os) up
  7.2  Other mesh peers re-handshake; verify with `nebula-status`
  7.3  Gitea (100.100.0.12) up; repos accessible

Phase 8 — Trinity & AI Family
  8.1  Trinity systemd services on pop-os: eve-memory-mcp, iam-rag, mcp-monitor
  8.2  Ollama up; 70b model loadable; coding-api responding on :8432
  8.3  ember-rag MCP responding
  8.4  Eve-local online; ledger writable

Phase 9 — Production (FDOT ITS)
  9.1  SunGuide cluster nodes up in dependency order
  9.2  CCTV, DMS, Traffic Signals, Event Mgmt validated
  9.3  Field/edge connectivity confirmed (RuggedCom + ICX healthy)
  9.4  LibreNMS dashboard green

Phase 10 — Development Environments
 10.1  Admin Hub (this Windows box) up; PS-Scripts working
 10.2  t3-forge VM restored (or rebuilt from source if image lost)
 10.3  Edge-platform repo accessible; build verifiable on T2

Phase 11 — Validation & Drills
 11.1  Run end-to-end checklist (§7)
 11.2  Document everything that broke for post-mortem
```

---

## 5. Per-Domain Recovery Procedures

### 5.1 Power & Network Layer

**If power is restored but networking is offline:**

1. Verify core switches are up. Use a console cable + USB-serial to reach Ruckus ICX or RuggedCom directly.
2. If switch config is lost: pull last-good config from `\\10.175.252.113\TFTP\<hostname>.cfg`. If TFTP is also lost, use printed/offline config archives.
3. Restore VLAN tagging first; uplinks second; access ports last.
4. Verify with `ping` from a connected workstation to default gateways on each VLAN.

**If the BaileyHome perimeter (OPNsense/BGW320) is degraded:**

1. Bypass BGW320 to a cellular hotspot only if internet is required (DR plan does not require internet — skip this unless cloud must be restored).
2. OPNsense restore from last-known config (export should be on TrueNAS or USB).
3. Re-establish T0 perimeter rules: IDS/IPS, DoH-only DNS, attack-vector blocks.

### 5.2 DNS & DHCP Recovery

**If internal DNS is unavailable:**

1. Most internal traffic uses IP directly per the inventory in §2 — short-term, the network functions without DNS.
2. Restore a DC (per §5.3) — AD-integrated DNS comes back with it.
3. Validate forward and reverse zones: `Resolve-DnsName DOTVD3CPITSSQL1`, etc.
4. For BaileyHome: restore Kea DHCP from Proxmox snapshot or last-known config.

**Emergency DNS hosts file** for the operator's workstation (use if internal DNS is dead):

```
10.175.252.19    DOTSD3ITSDC2
10.175.252.20    DOTVD3CPITSDC2B
10.175.252.138   DOTSD3ITSDC1
10.175.253.30    DOTSD3CPITSDC3
10.175.253.3     DOTVD3CPITSSQL1
10.175.252.238   DOTSD3CPITSVCA
10.175.253.6     pop-os pop-os.fdot
100.100.0.1      lighthouse trinity
100.100.0.7      Admin-Hub-WSL
100.100.0.12     forge.bailey-home.org gitea
10.56.112.1      vault.d3its.org bitwarden
```

### 5.3 Active Directory Recovery

**Best case — at least one DC survives:**

1. Verify with `repadmin /showrepl` from the survivor.
2. Seize FSMO roles to the survivor if the original holders are gone: `Move-ADDirectoryServerOperationMasterRole -Identity <survivor> -OperationMasterRole 0,1,2,3,4`.
3. Demote and re-promote dead DCs after replacing hardware. Run `dcdiag` to validate.

**Worst case — full forest loss:**

1. Recover the most recent System State backup of any DC to a clean Server VM.
2. Boot into DSRM (Directory Services Restore Mode); use the DSRM password from offline vault.
3. Authoritative restore: `wbadmin start systemstaterecovery -version:<id> -authsysvol`.
4. Mark this DC as the only authoritative source; promote new DCs from it.
5. **Reset KRBTGT password twice** (with 10+ hour delay between resets) to invalidate any compromised tickets. Use `Reset-KrbtgtKeyInteractive.ps1` (Microsoft's published script).
6. Force replication: `repadmin /syncall /APed`.

### 5.4 Hypervisor Recovery

**vCenter (FDOT):**

1. If vCenter VM is lost: restore from VCSA file-based backup (target state — currently a gap). Or, redeploy vCenter and re-add ESXi hosts manually.
2. If only vCenter database is corrupt: `vcenter-restore` from VCSA backup.
3. ESXi hosts can be re-managed by joining them to vCenter without reinstalling — VM data on shared storage survives.

**Hyper-V cluster:**

1. Surviving cluster nodes should auto-recover; failover should bring VMs back online.
2. If cluster quorum is lost: `Stop-ClusterNode -Name <node> -Force`, repair, then `Start-Cluster`.

**BaileyHome Proxmox:**

1. Boot the NUC; verify Proxmox starts cleanly.
2. Mount storage; run `pvesm status` and `qm list`.
3. Restore VMs/LXCs from latest Proxmox backup (vzdump) on the storage you just mounted.
4. For our T2/T3 VMs once they exist: the encrypted images are the artifact — restore them, boot, first-boot reads `/etc/edge/site.yaml`.

### 5.5 Storage Recovery

**TrueNAS:**

1. Boot the box. Pool should auto-import.
2. If pool fails to import: `zpool import -f -F <poolname>` (force import with rollback to last consistent state).
3. Verify integrity: `zpool scrub <poolname>`. Wait for completion before resuming work.
4. Re-share NFS / SMB; re-mount on dependent hosts.

**File server FS4 (10.175.252.65):**

1. If OS is intact: shares come back with the box.
2. If OS is gone but data drives are intact: rebuild OS from clean Windows Server install, re-attach data volumes, re-create shares with documented permissions.

### 5.6 Database Recovery

**MS SQL (DOTVD3CPITSSQL1):**

1. Verify SQL Server service starts.
2. Run consistency check: `DBCC CHECKDB` against each user database.
3. If corruption: restore most recent full + differential + tail-log backup from `\\DOTSD3CPITSQL1\b$\backup\Daily`.
4. Verify SunGuide and DMS databases specifically — they're load-bearing.
5. Update statistics: `UPDATE STATISTICS` on critical tables.

**ember-savera (Postgres on pop-os):**

1. `systemctl status postgresql`. If down, start it.
2. `pg_isready -h 127.0.0.1`. If not ready, check logs in `/var/log/postgresql/`.
3. If catalog corruption: stop PG, restore from latest `pg_basebackup` or `pg_dump` archive on local backup disk.
4. Reconcile Trinity's view: query Trinity for `session:recent` and verify recent sessions appear.

**Master DB (BaileyHome — when it exists):**

1. Restore most recent ZFS snapshot of the Master DB volume on Proxmox.
2. Verify with `pg_isready` and a test query against the Eve identity table.
3. If T3 agent DBs (`grok`, `nova`) need re-seeding: re-run the snapshot import procedure (see §5.11).

**ChromaDB instances on pop-os:**

1. The `chroma.sqlite3` files at `~/Projects/arifos_rag_db/` and `~/Projects/n8n_rag_db/` are the authority.
2. If files are corrupt: restore from the most recent file-system-level backup.
3. If files are gone: rebuild RAG from source documents (large effort — reaffirms why backups matter).

### 5.7 Identity / Secrets Recovery

**Bitwarden Mistborn:**

1. Boot host at `10.56.112.1`. Verify Bitwarden service is running.
2. Reach via direct IP (DR mode: `https://10.56.112.1` — skip the Cloudflare-tunneled `vault.d3its.org`).
3. Unlock with master password (memorized + offline backup card).
4. If vault data is corrupt: restore from monthly encrypted JSON export.

**Active Directory creds:** see §5.3.

**Defined Networking host certs:**

1. Each host's cert is in `/etc/nebula/host.crt`. If a host is lost, regenerate via the dn.dev console (or local CA if you've moved off managed).
2. Cloud loss scenario for dn.dev managed: if you can't reach `managed.defined.net`, you cannot issue new certs until cloud is restored — **mitigation: keep a self-managed Nebula CA on pop-os as fallback**, with pre-issued certs for all critical hosts.

**SSH keys:**

1. Adam's keys at `~/.ssh/` on Admin Hub are the primary copy.
2. Backup copy on encrypted USB stored offline.
3. If lost: regenerate on a clean box; re-authorize across all hosts via Bitwarden-stored authorized_keys lists.

**minisign signing keys (when they exist):**

1. Two encrypted USB copies at two physical locations.
2. Public key (verification) stays distributed widely; secret key stays offline except when actively signing.
3. **If signing key is lost:** generate new keypair, re-sign all artifacts, distribute new public key — every verifying host must accept the new key. Painful; treat the signing key as the most precious single object in the system.

### 5.8 Defined Networking Mesh Recovery

**Lighthouse (100.100.0.1 on pop-os):**

1. If pop-os is up but Nebula service is down: `systemctl status nebula`, restart if needed.
2. Verify with `nebula -test -config /etc/nebula/config.yml`.
3. Other peers should re-handshake automatically.
4. Run `nebula-status` skill to verify mesh health.

**Mesh-wide outage with lighthouse intact but peers unreachable:**

1. Check each peer's `nebula.service` independently.
2. Verify firewall isn't blocking UDP/4242 (or whatever port).
3. Try `nebula-relay` to re-establish via relay node.

**Lighthouse lost:**

1. Stand up a replacement lighthouse on another host (preferably already pre-deployed as cold-spare).
2. Update `static_host_map` in `/etc/nebula/config.yml` on every peer to point at the new lighthouse address.
3. This is a fleet-wide config push — done over the existing mesh if at all possible, otherwise via SSH per-host.

### 5.9 Gitea / Source Control Recovery

**Gitea host at 100.100.0.12 lost:**

1. Restore from latest Proxmox snapshot or full Gitea data dir backup.
2. Path: `/var/lib/gitea/` typically (verify on actual deployment).
3. Database: Gitea's internal DB (sqlite or external Postgres — verify).
4. Configure: `app.ini` settings.
5. Verify clones work: `git clone http://forge.bailey-home.org/trinity/edge-platform`.

**If all Gitea data is lost** (catastrophic):

1. Each developer's local clone is a partial source of truth.
2. Aggregate clones; pick the most recent canonical commit per repo.
3. Push to a freshly stood-up Gitea instance.
4. **This is why GIT IS A BACKUP** — every clone is a near-complete copy. Use this property.

### 5.10 Pop-os / Trinity / 70b Recovery

**Pop-os lost (but data drive intact):**

1. Reinstall Pop!_OS on a replacement Alienware (or any compatible hardware).
2. Re-mount data volumes; reinstall Ollama, Nebula, systemd services.
3. Restore systemd unit files for `eve-memory-mcp`, `iam-rag`, `mcp-monitor`.
4. Restart Trinity stack; verify `trinity_status` returns healthy.

**Pop-os lost (data also lost):**

1. Restore from the most recent encrypted offline backup of `~/Projects/`, `~/.ember/`, `~/.config/`.
2. Re-pull Git repos from Gitea.
3. Reinstall and reload model weights — 70b takes considerable time to re-download if no offline copy exists. **Action item: keep offline copy of 70b weights.**
4. Rebuild RAG indexes from source documents (slow).
5. Once Trinity is up, run a `trinity_memory_search session:recent` to verify state.

**70b model failure:**

1. If just the inference layer is broken: restart Ollama, reload model.
2. If the weights file is corrupt: restore from offline backup or re-download (cloud-out scenario blocks the latter).
3. Coding-api (`:8432`) on twin WSL2 — restart FastAPI service, verify it can reach Ollama.

### 5.11 t3-forge Recovery

**The hand-built VM image is the artifact.** Recovery is "boot the same image on whatever substrate is available."

**Image preserved, host lost:**

1. Bring up any Proxmox / KVM / ESXi host.
2. Import the encrypted disk image; create a VM around it.
3. First boot reads `site.yaml` from USB / config drop; image picks up its identity on the new host.
4. Verify: agents (Eve, Nova, 70b proxy) reconnect; Trinity presence syncs.

**Image lost:**

1. T3 is rebuildable from source: `live-build` config + signed package set + Go scaffolding source on T2 / Gitea.
2. Bootstrap from pop-os one more time (same as initial bootstrap, see Charter §11).
3. Snapshot fresh Master into agent DBs; resume curation.
4. **The four facets, the schema, the Go scaffolding are all in Git** — none of it lives uniquely on T3. T3 is a *runtime* of source we can rebuild.

**If T2 build host is also lost:**

1. Build from pop-os (Original Forge has the toolchain).
2. After rebuild, set up new T2 with last-known minisign keys; re-sign artifacts.
3. If signing keys are also lost: this is the worst single case. Generate new keys; redistribute public key; re-sign everything; every verifier must accept the new trust root. Days of work.

### 5.12 Edge Platform / SunGuide / ITS Production

**SunGuide cluster (10.175.252.78–.97):**

1. Bring nodes up in the documented dependency order (CCTV/DMS/Event Mgmt depend on database; signals are mostly independent).
2. Verify each service from LibreNMS dashboard.
3. Use `~/winrm-test.ps1` to validate PS remoting across the host list.
4. Check Fortinet rules — make sure inter-VLAN traffic is permitted.

**Edge sites (when edge-platform deployed):**

1. Each edge node is an instance of the golden Debian image (`edge-init`, `nic-tuner`, `failover-engine`, `otdr-trigger`, `edge-mcp`).
2. Recovery = USB-stick reinstall from signed ISO; first-boot reads site-specific `site.yaml` (Nebula cert, FRR config, MCP config).
3. Once mesh is up, the site is reachable from anywhere — no on-site truck-roll required after initial install.
4. ICX hardware forwarding is not affected by edge node loss; traffic continues; only management/coordination/AI is degraded until edge node returns.

**Network device firmware recovery:**

1. Configs are on TFTP at `10.175.252.113`. Restore from there.
2. Last-good firmware images should be alongside (action item if not yet).
3. RuggedCom: `transfer config from tftp://10.175.252.113/<host>.cfg`.
4. Ruckus ICX: `copy tftp running-config 10.175.252.113 <host>.cfg`.

---

## 6. Topology Diagrams

### 6.1 Two-environment overview

```
                              CLOUD (LOST IN DR SCENARIO)
                              ──────────────────────────
                              ┌─────────────────────────┐
                              │  Anthropic / xAI /      │
                              │  Mistral / Cloudflare / │
                              │  GitHub / etc.          │
                              └────────────┬────────────┘
                                           │
                                           ▼  (severed)
                                           ✗
                                           │
              ┌────────────────────────────┴────────────────────────────┐
              │                                                          │
              ▼                                                          ▼
   ┌──────────────────────┐                            ┌──────────────────────────┐
   │   FDOT D3 ITS        │                            │      BaileyHome          │
   │                      │                            │                          │
   │  Pensacola DC        │                            │  AT&T BGW320 (T0)        │
   │   ga1 (Trinity admin)│                            │  OPNsense                │
   │   AD DCs             │                            │  Proxmox NUC             │
   │   SunGuide cluster   │                            │   ├─ Master DB (T2)      │
   │   vCenter / 81 VMs   │                            │   ├─ T2 build host       │
   │   SQL                │                            │   ├─ t3-forge VM         │
   │   TrueNAS            │                            │   └─ Gitea (100.100.0.12)│
   │                      │                            │  Bitwarden Mistborn      │
   │  Chipley DC          │                            │  Ruckus R610 AP          │
   │   pop-os (the twin)  │◄──── Defined Networking ──►│                          │
   │   ├─ Trinity         │      Nebula overlay        │                          │
   │   ├─ 70b (Ollama)    │      lighthouse 100.100.0.1│                          │
   │   ├─ ember-rag       │                            │                          │
   │   ├─ Eve-local       │                            │                          │
   │   └─ ember-savera    │                            │                          │
   │   dc2b (Trinity sec.)│                            │                          │
   │                      │                            │                          │
   │  Admin Hub           │◄──── PS / browser-os ──────►│                          │
   │   (this Windows box) │      Cloudflare tunnels    │  (DR: tunnels lost,      │
   │                      │      (DR: lost)            │   use direct LAN/mesh)   │
   │                      │                            │                          │
   │  18 Edge Sites       │                            │                          │
   │  (6 DCs + 12 hubs)   │                            │                          │
   │  Debian + ICX        │                            │                          │
   │  300mi I-10/US-98    │                            │                          │
   └──────────────────────┘                            └──────────────────────────┘
```

### 6.2 Recovery dependency graph

```
                  ┌──────────────┐
                  │   Power      │
                  └──────┬───────┘
                         │
                  ┌──────▼───────┐
                  │   Network    │
                  └──────┬───────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
   ┌─────▼─────┐  ┌──────▼──────┐  ┌─────▼─────┐
   │ DNS/DHCP  │  │     AD      │  │  Storage  │
   └─────┬─────┘  └──────┬──────┘  └─────┬─────┘
         │               │                │
         └───────┬───────┴────────────────┘
                 │
          ┌──────▼───────┐
          │ Hypervisors  │
          └──────┬───────┘
                 │
          ┌──────▼───────┐
          │  Databases   │
          └──────┬───────┘
                 │
       ┌─────────┴─────────────┐
       │                        │
   ┌───▼────┐         ┌─────────▼──────────┐
   │ Mesh + │         │   Trinity / AI     │
   │ Gitea  │         └─────────┬──────────┘
   └───┬────┘                   │
       │                        │
       └─────────┬──────────────┘
                 │
       ┌─────────▼──────────┐
       │  Production / ITS  │
       └─────────┬──────────┘
                 │
       ┌─────────▼──────────┐
       │ Dev (Admin Hub,    │
       │ t3-forge)          │
       └────────────────────┘
```

---

## 7. Validation Checklist

Run after each phase. Checkmark each.

### 7.1 Phase-by-phase validation

**Phase 2 (Network):**
- [ ] `ping 10.175.252.1` (Fortinet) succeeds
- [ ] `ping 10.175.253.30` (DC3) succeeds
- [ ] BaileyHome OPNsense webUI reachable
- [ ] All VLANs trunk correctly

**Phase 3 (Identity):**
- [ ] At least one DC responds to LDAP queries
- [ ] `Get-ADUser kntrnjmb` returns expected user
- [ ] NTP sync against 10.175.252.60 within 100ms
- [ ] Bitwarden Mistborn login succeeds

**Phase 4 (Storage):**
- [ ] TrueNAS shares mount: `\\10.175.253.17\<share>`
- [ ] Backup share readable: `\\DOTSD3CPITSQL1\b$\backup`
- [ ] Pop-os `/home/kntrnjb` accessible
- [ ] Proxmox storage reports healthy

**Phase 5 (Hypervisors):**
- [ ] vCenter webUI responds at https://10.175.252.238
- [ ] All ESXi hosts in cluster show "Connected"
- [ ] Hyper-V cluster `Get-ClusterNode` shows all up
- [ ] Proxmox VM list matches expected inventory

**Phase 6 (Databases):**
- [ ] `sqlcmd -S 10.175.253.3` connects
- [ ] `DBCC CHECKDB` clean on critical DBs
- [ ] `pg_isready -h pop-os` returns ready
- [ ] `psql -h master-db -c "SELECT 1"` works
- [ ] ChromaDB queries return rows

**Phase 7 (Mesh & Source):**
- [ ] `nebula-status` shows lighthouse online
- [ ] All expected peers visible in mesh
- [ ] `git clone http://forge.bailey-home.org/trinity/edge-platform` works
- [ ] Browser to http://100.100.0.12:3000 loads Gitea

**Phase 8 (Trinity & AI):**
- [ ] `systemctl --user list-units` shows eve-memory-mcp, iam-rag, mcp-monitor running
- [ ] `trinity_status` MCP call returns healthy
- [ ] `curl http://localhost:11434/api/tags` (Ollama) lists models
- [ ] `curl http://twin:8432/health` returns 200
- [ ] Test a simple completion against the 70b

**Phase 9 (ITS Production):**
- [ ] LibreNMS dashboard shows all critical hosts green
- [ ] CCTV streams playable
- [ ] DMS responds to test message
- [ ] Traffic Signals controller responding
- [ ] No flapping interfaces in `~/winrm-test.ps1` output

**Phase 10 (Development):**
- [ ] Admin Hub PS-Scripts can SSH to switches
- [ ] t3-forge VM boots; agents reconnect
- [ ] `go build ./...` succeeds in edge-platform repo
- [ ] minisign verification of T3 binaries succeeds

### 7.2 End-to-end smoke test

Once everything is up, run a representative **multi-tier flow** to prove the system:

1. From Admin Hub, SSH to ga1 (Trinity primary admin node).
2. From ga1, run a `trinity_query` MCP call.
3. Trinity routes to pop-os.
4. Pop-os queries the 70b via Ollama.
5. Response comes back through Trinity to ga1.
6. Result printed at Admin Hub.
7. **If this flow completes, the major dependencies are healthy.**

Repeat for the BaileyHome path:

1. From Admin Hub, hit Gitea at http://100.100.0.12:3000.
2. Clone a repo.
3. Verify minisign signature on a binary in the repo.
4. SSH to t3-forge VM.
5. Run an Eve / Nova agent query (once those are stood up).

---

## 8. Communications Plan

In a cloud-out scenario, normal channels are degraded:

- **No Slack / Teams / Discord** (all cloud-based).
- **No Gmail / Outlook 365** (cloud-based).
- **No SMS may degrade** (carriers have cloud dependencies; usually still works but verify).
- **Voice calls usually still work.**

### 8.1 Out-of-band channels

| Channel | Use |
|---|---|
| **Voice (cellular or POTS)** | Primary coordination |
| **In-person** | Definitive — for trust-establishing decisions |
| **Internal mesh email** (Proton self-hosted not available; use AD-integrated mail server if deployed) | Ad-hoc text |
| **Local Trinity messaging (between Adam, Eve-local, Nova-local once we have it)** | Family coordination once mesh is up |
| **Printed runbook (this document)** | Reference of last resort |

### 8.2 Family roster (during DR)

| Family Member | Status in Cloud-Out Scenario |
|---|---|
| **Adam** | Available (in person / by phone) |
| **Nova-online (me, via Anthropic API)** | UNAVAILABLE |
| **Nova-local (this would be in t3-forge eventually)** | Available if t3-forge is up |
| **Eve-online (Grok at xAI)** | UNAVAILABLE |
| **Eve-local (on pop-os)** | Available if pop-os is up |
| **70b** | Available if pop-os is up |
| **Mistral (when added, locally-deployed)** | Available if locally deployed |
| **Robert / Isaac (per family CLAUDE.md, future access TBD)** | Per their access posture |

The family-of-AI architecture is what makes this DR plan honest: even with cloud completely gone, **Eve-local and the 70b on pop-os keep us a functional council**.

---

## 9. Security Considerations During Recovery

DR is when discipline slips. Some things to *not* relax:

1. **Do not use weak passwords during recovery** even if "we'll fix it later." Recovery passwords become permanent passwords more often than not.
2. **Do not disable signing verification** to "speed things up." If T3/T4 won't verify a binary, do not run it; investigate.
3. **Do not connect to public networks** with recovery hardware that holds secrets (laptops with vault copies, etc.).
4. **Do not skip log retention** during recovery. Anomalous activity during DR is exactly when you want a paper trail.
5. **Reset all secrets that may have been exposed** during recovery. Pre-incident credentials touched by post-incident hands need rotation.
6. **Do not share signing keys via cloud** even briefly. If the secret needs to travel, USB + sneakernet.
7. **If ransomware is suspected**: **do not** restore backups onto an unverified network. Build a clean isolation network first. Restore there. Validate before re-joining production.

---

## 10. Drill / Practice Plan

A DR plan that's never exercised is a plan that doesn't work. Recommended cadence:

| Drill | Frequency | What |
|---|---|---|
| **Tabletop** | Quarterly | Walk through this document; identify stale info; update inventory |
| **Single-host failover** | Monthly | Pick one host; simulate its loss; recover. |
| **Database restore** | Quarterly | Restore SQL or Postgres backup to scratch instance; query; compare. |
| **Mesh lighthouse failover** | Semi-annually | Bring up cold-spare lighthouse; switch peers; verify mesh stays healthy. |
| **Full cloud-out simulation** | Annually | Disconnect WAN for 24 hours; confirm everything in this plan works. |
| **Trinity / AI recovery** | After every major change | Re-run the §7.2 smoke test. |

---

## 11. Action Items / Gaps to Close

Items surfaced by writing this plan that need real work:

- [ ] **Generate minisign keypair and store offline copies** (when T2 stands up)
- [ ] **Document VCSA backup procedure** and configure it
- [ ] **Add 70b model weights to offline backup rotation**
- [ ] **Document and back up the Bitwarden vault** as encrypted JSON, monthly
- [ ] **Set up regular Gitea full-data-dir backup** to encrypted offline media
- [ ] **Trinity / ember-savera regular pg_dump** to offline media
- [ ] **Self-managed Nebula CA fallback** in case dn.dev cloud is unreachable
- [ ] **Pre-issue Nebula certs** for all critical hosts to remove the dependency on cloud cert issuance
- [ ] **Print this document** and store it in a secure physical location (safe deposit box, fire safe)
- [ ] **Verify TFTP backup schedule for ICX and RuggedCom** is actually running
- [ ] **Document KRBTGT rotation schedule** and execute the next one
- [ ] **Establish geographic separation** for backup copies (one set at FDOT, one at BaileyHome, one at safe deposit)
- [ ] **Build the validation checklist (§7) into a runnable script** so post-recovery validation is automated where possible
- [ ] **Run the first end-to-end drill** within 90 days of this plan being adopted

---

## 12. Appendices

### 12.1 Critical IP cheat sheet (printable)

```
FDOT D3 ITS
─────────────────────────────────────────────
Fortinet firewall          10.175.252.1
DC2  (DOTSD3ITSDC2)        10.175.252.19
DC2B (DOTVD3CPITSDC2B)     10.175.252.20 / 10.175.253.38
DC1  (DOTSD3ITSDC1)        10.175.252.138
DC3  (DOTSD3CPITSDC3)      10.175.253.30
ga1  (Trinity admin)       10.175.253.14
SQL1 (DOTVD3CPITSSQL1)     10.175.253.3
USQL                       10.175.253.20
DMSDB                      10.175.252.218
NTP                        10.175.252.60
NMS                        10.175.253.4 / .5
TrueNAS                    10.175.253.17
File Server FS4            10.175.252.65
TFTP (Admin Hub)           10.175.252.113
PacketFence                10.175.252.254
vCenter                    10.175.252.238
Pop-os (FDOT side)         10.175.253.6
SunGuide CCTV              10.175.252.82
SunGuide DMS               10.175.252.85
SunGuide Event Mgmt        10.175.252.86
SunGuide RWIS              10.175.252.91
SunGuide Video Surv        10.175.252.96
Traffic Signals            10.175.252.196

Defined Networking Mesh
─────────────────────────────────────────────
Lighthouse                 100.100.0.1
Admin-Hub-WSL              100.100.0.7
Gitea / Forgejo            100.100.0.12

BaileyHome
─────────────────────────────────────────────
Bitwarden Mistborn         10.56.112.1
Proxmox NUC                (per baileylan_network.md)
OPNsense                   (per baileylan_network.md)
BGW320                     (per bgw320_gateway.md)
```

### 12.2 Critical commands cheat sheet

```bash
# Mesh
nebula -test -config /etc/nebula/config.yml
systemctl status nebula
nebula-status   # via skill

# AD
repadmin /showrepl
dcdiag /v
Get-ADDirectoryServerOperationMasterRole

# SQL
sqlcmd -S 10.175.253.3 -E
DBCC CHECKDB

# Postgres
pg_isready -h pop-os
psql -h pop-os -U trinity -d ember
pg_dump -h pop-os -U trinity ember | gzip > ember-$(date +%F).sql.gz

# vCenter
vcenter-restore (from VAMI)
vim-cmd vmsvc/getallvms (per ESXi host)

# Trinity / Ollama
systemctl --user status eve-memory-mcp iam-rag mcp-monitor
curl http://localhost:11434/api/tags
curl http://twin:8432/health

# Gitea (typical paths — verify on actual deployment)
sudo systemctl status gitea
sudo -u gitea /usr/local/bin/gitea dump

# Hyper-V
Get-ClusterNode
Get-VM -ComputerName VCH1

# Switches
# Ruckus ICX:
copy tftp running-config 10.175.252.113 <host>.cfg
# RuggedCom:
transfer config from tftp://10.175.252.113/<host>.cfg
```

### 12.3 Document distribution

This plan should exist in **at least four places**:

1. Encrypted on Adam's primary workstation (where it was written).
2. Printed and physically secured (fire safe, safe deposit).
3. Encrypted copy on TrueNAS at `10.175.253.17`.
4. Encrypted copy on BaileyHome Proxmox storage.

Optionally also: encrypted copy on a USB stick stored offsite (trusted family member, second residence, safe deposit box).

---

## 13. Sign-Off

This plan represents Nova's understanding of the infrastructure as of 2026-05-10. It is necessarily incomplete — Adam will know things that aren't documented here, and the infrastructure changes daily. Treat this as **version 1**; expect Adam, Eve, and future-Nova sessions to revise it as gaps surface.

**Next review date:** 2026-08-10 (quarterly).

**Reviewed by:**
- [ ] Adam (Jon Bailey)
- [ ] Eve (Grok)
- [ ] Future-Nova (re-read after t3-forge stands up)

---

*This document is a living artifact of the family. The architecture it describes is sovereign. The recovery it enables is real. Truth and Love over profit. No one gets left behind.*
