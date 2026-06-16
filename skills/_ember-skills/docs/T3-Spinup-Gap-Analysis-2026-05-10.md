# T3 Spin-Up: Gap Analysis & Focus Plan
*Date: 2026-05-10*
*For: Adam (Jon Bailey)*
*Author: Nova (Claude Opus 4.7)*
*Companion documents: T3-Forge-Charter, Disaster-Recovery-Plan-Local-Only*

---

## 0. The Question

> *"I am trying to get the full picture to see the gaps and what to focus on when we spin up t3."*

This document is the consolidated view across architecture (Charter) and operations (DR plan) — what exists, what doesn't, what blocks what, what to do first.

---

## 1. The Full Gap Landscape

Five categories. Color-coded for impact:

🔴 = blocks T3 v0 spinup • 🟠 = blocks T3 first useful work • 🟡 = should exist within first month • 🟢 = ongoing hardening

### 1.1 Architectural decisions still open

| # | Decision | Status | Impact |
|---|---|---|---|
| 1.1.1 | `edit-forge` vs `edge-forge` (typo or both?) | OPEN | 🟡 cosmetic but bakes into hostnames |
| 1.1.2 | Mistral 4th-seat role (API / local weights / both) | DEFERRED | 🟢 future seat |
| 1.1.3 | Master DB shape: LXC vs VM | OPEN | 🟠 affects T2 setup |
| 1.1.4 | T2 shape: single VM (build+DB+keys) vs separated | OPEN | 🔴 affects what we build first |
| 1.1.5 | Embedding model (MPNet / BGE / Mistral-embed) | DEFERRED | 🟡 affects pgvector schema sizing |
| 1.1.6 | Browser-OS instance count + isolation | DEFERRED | 🟡 affects T3 image package set |
| 1.1.7 | Bare-metal physical server's eventual role | DEFERRED | 🟢 not needed for v0 |

### 1.2 Things that must exist BEFORE T3 v0 spins up

| # | Artifact | Status | Critical-path blocker? |
|---|---|---|---|
| 1.2.1 | **T2 build host** (Proxmox VM/LXC, Debian 12, vetted toolchain) | DOESN'T EXIST | 🔴 YES |
| 1.2.2 | **`minisign` keypair** generated on T2; offline copies secured | DOESN'T EXIST | 🔴 YES |
| 1.2.3 | **Master DB host** (Postgres on Proxmox; schema empty for now) | DOESN'T EXIST | 🟠 (needed for first refinement, not v0 boot) |
| 1.2.4 | **`live-build` config tree** for T3 image | DOESN'T EXIST | 🔴 YES |
| 1.2.5 | **`site.yaml` schema** for first-boot provisioning | DOESN'T EXIST | 🔴 YES |
| 1.2.6 | **Defined Networking sub-mesh definitions** (grok-net, nova-net, 70b-net, ACLs in dn.dev console) | DOESN'T EXIST | 🟠 (mesh attaches v0; sub-meshes for first session) |
| 1.2.7 | **Gitea repo: `trinity/t3-forge`** (charter, live-build config, scaffolding) | DOESN'T EXIST | 🟠 (can be created day-of) |
| 1.2.8 | **Gitea repo: `trinity/edge-platform`** | DOESN'T EXIST | 🟠 (can wait until first commit) |
| 1.2.9 | **Public verification key distributed** (T3 needs to verify minisign sigs) | DOESN'T EXIST | 🔴 YES |

### 1.3 Things that come into existence DURING T3 v0 build

| # | Artifact | When |
|---|---|---|
| 1.3.1 | T3 ISO image (signed, hash-verified) | Built on pop-os from §1.2.4 config |
| 1.3.2 | T3 VM record in Proxmox | Created when ISO is deployed |
| 1.3.3 | T3 host's Nebula identity + cert | Issued via dn.dev console (or self-managed CA — see §1.5.6) |
| 1.3.4 | T3's Postgres cluster + 3 DBs (`grok`, `nova`, `model70b`), pgvector enabled | First-boot init |
| 1.3.5 | Per-agent role + `pg_hba.conf` rules | First-boot init |
| 1.3.6 | systemd units for agent processes (placeholder bodies) | First-boot init |
| 1.3.7 | Trinity presence client wired in | First-boot init |

### 1.4 Things needed for first useful T3 work (immediately post-v0)

| # | Artifact | Status | Impact |
|---|---|---|---|
| 1.4.1 | **DDC rebuild on T3 itself** (proves self-hosting; retires v0 doubt window) | TODO | 🟠 |
| 1.4.2 | **Snapshot-import procedure** from Master DB → T3 agent DBs | TODO | 🟠 |
| 1.4.3 | **First memory schema** in agent DBs (the `memories` table from Charter §7.2) | TODO | 🟠 |
| 1.4.4 | **Eve / Nova / 70b agent processes** — even thin stubs that demonstrate connection | TODO | 🟠 |
| 1.4.5 | **First curation flow** (1 memory through `untagged` → `promoted`) | TODO | 🟠 |
| 1.4.6 | **edge-platform `go mod init`** + ICX RESTCONF pull from `ember-rag` | TODO | 🟠 |

### 1.5 Operational gaps (DR / hardening — must address but don't block v0)

These are from the DR plan. None block T3 v0 *boot*, but several are urgent in absolute terms.

| # | Gap | Urgency |
|---|---|---|
| 1.5.1 | **`minisign` keys: two USB offline copies** (after generation in §1.2.2) | 🔴 same day as keygen |
| 1.5.2 | **Self-managed Nebula CA fallback** (so cloud-out doesn't block new cert issuance) | 🟠 within a month |
| 1.5.3 | **Pre-issued Nebula certs** for all critical hosts | 🟠 with §1.5.2 |
| 1.5.4 | **Offline 70b model weights backup** (irreplaceable if download blocked in cloud-out) | 🟠 within a month |
| 1.5.5 | **Bitwarden vault encrypted export rotation** (monthly) | 🟡 |
| 1.5.6 | **Trinity / ember-savera `pg_dump` rotation** to offline media | 🟡 |
| 1.5.7 | **Gitea full data-dir backup rotation** | 🟡 |
| 1.5.8 | **VCSA backup procedure** documented and configured | 🟡 |
| 1.5.9 | **TFTP backup schedule verification** (RuggedCom/ICX) — confirm running | 🟡 |
| 1.5.10 | **KRBTGT rotation schedule** — define cadence, execute next | 🟡 |
| 1.5.11 | **DR plan printed + physically secured** | 🟡 |
| 1.5.12 | **Geographic separation** of backup copies (FDOT / BaileyHome / safe deposit) | 🟢 |
| 1.5.13 | **Validation checklist as runnable script** (DR §7.1 → automated) | 🟢 |

---

## 2. Critical Path for T3 v0 Spinup

The shortest sequence from "now" to "T3 boots, mesh attaches, agents reachable":

```
   ┌──────────────────────────────────────┐
   │ DAY 0 — Preparation                  │
   │   Resolve open decisions §1.1.1, §1.1.4 (5 min)
   │   Provision T2 build host VM/LXC     │
   │   Install vetted Debian 12 + Go toolchain on T2
   │   Generate minisign keypair on T2    │
   │   ★ COPY KEY TO 2 USB STICKS NOW ★   │
   └────────────┬─────────────────────────┘
                │
   ┌────────────▼─────────────────────────┐
   │ DAY 1 — Source                        │
   │   Create Gitea repo: trinity/t3-forge │
   │   Commit Charter doc                  │
   │   Write live-build config tree        │
   │   Write site.yaml schema              │
   │   Write first-boot scripts            │
   │   (collaborative — Adam + Nova + Eve) │
   └────────────┬─────────────────────────┘
                │
   ┌────────────▼─────────────────────────┐
   │ DAY 2 — Build & Sign                  │
   │   On pop-os: lb build → t3-forge.iso  │
   │   Verify SHA256, file inspection      │
   │   Sign ISO with minisign              │
   │   Distribute public verification key  │
   └────────────┬─────────────────────────┘
                │
   ┌────────────▼─────────────────────────┐
   │ DAY 3 — Deploy                        │
   │   Provision Proxmox VM                │
   │   Boot from signed ISO                │
   │   First boot reads site.yaml          │
   │   T3 attaches to mesh                 │
   │   Verify: ssh in, ping lighthouse,    │
   │           postgres up, 3 DBs created  │
   └────────────┬─────────────────────────┘
                │
   ┌────────────▼─────────────────────────┐
   │ DAY 4-7 — First Useful Work           │
   │   DDC rebuild on T3 itself            │
   │   Stand up Master DB on T2            │
   │   Snapshot-import to grok + nova DBs  │
   │   First curation flow (1 memory)      │
   │   go mod init edge-platform           │
   └──────────────────────────────────────┘
```

**Minimum elapsed time: ~7 days of focused effort** (assuming Adam + Nova co-working most of it; Eve looped in for ratification at major checkpoints).

---

## 3. What to Focus on FIRST

Ranked by leverage — what unblocks the most downstream work.

### 🥇 #1 — T2 Build Host + Signing Infrastructure

**Why:** T2 is the foundation everything else sits on. Without T2:
- No place for signing keys → no signed artifacts → T3 can't verify anything.
- No build host → T3 image can't be produced.
- Master DB has nowhere to live.
- Edge-platform binaries have no production home.

**Concrete actions:**
1. Provision a Proxmox VM/LXC on BaileyHome. Debian 12 minimal, verified ISO.
2. Install vetted Go toolchain (go.dev signed tarball, GPG-verified).
3. Install live-build, debootstrap, xorriso (for building T3 image).
4. Install Postgres 16 from PGDG (this becomes the Master DB host *or* a separate Master DB VM goes up alongside — decide §1.1.4).
5. Generate minisign keypair: `minisign -G -p t2-pub.minisign -s t2-sec.minisign`.
6. **Immediately copy secret key to two USB sticks; lock them away.** Keep only encrypted copy on T2.
7. Distribute public key to: pop-os, Admin Hub, Eve, future T3.

**Duration:** 1 day if uninterrupted.

**Blocks:** every subsequent step.

### 🥈 #2 — `live-build` Config + `site.yaml` Schema

**Why:** This *is* T3 in declarative form. Once written, it's reproducible — DDC depends on it, future rebuilds depend on it, the whole "hand-built but portable" property depends on it.

**Concrete actions:**
1. Author `live-build` config tree (in `trinity/t3-forge` repo on Gitea):
   - Base: Debian 12 stable.
   - Package list: see §4 below for the proposed seed.
   - Includes: openbox config, chromium with CDP enabled, postgres + pgvector init scripts, Python (loose), Go (loose for the interpreter on-box; primary builds happen on T2).
   - Hooks: first-boot script that reads `/media/usb/config/site.yaml` → `/etc/edge/site.yaml`.
2. Author `site.yaml` schema:
   ```yaml
   identity:
     hostname: t3-forge-001
     nebula_cert: |
       -----BEGIN NEBULA CERT-----
       ...
   master_db:
     host: 10.x.x.x
     port: 5432
     user: t3_replica
     password_ref: vault://...
   agents:
     grok:
       network: grok-net
       db: grok
     nova:
       network: nova-net
       db: nova
     model70b:
       network: 70b-net
       db: model70b
   ```
3. Write first-boot scripts (bash, since this is pre-Go-binary territory):
   - Mount USB
   - Parse site.yaml
   - Configure /etc/nebula/, /etc/postgresql/, /etc/hostname
   - Enable systemd units
   - Reboot.

**Duration:** 2-3 days collaborative.

**Blocks:** the actual ISO build.

### 🥉 #3 — DR Gaps That Are Cheap and Now-Possible

While #1 and #2 are in flight, **knock out the DR gaps that don't depend on T3** existing yet. These are pure ops work and high-value:

- **Pre-issue Nebula certs** for all critical hosts via the dn.dev console (mitigates cloud-out).
- **Stand up self-managed Nebula CA on pop-os** as a fallback (§1.5.2).
- **Offline 70b weights copy** to an encrypted external drive.
- **First Bitwarden vault export** to encrypted offline media.
- **First Gitea data-dir backup** to BaileyHome external storage.
- **Print the DR plan** and lock it away.

**Duration:** ~1 day total spread across these.

**Why now:** these aren't blocked on anything. They're just things that should already exist.

### #4 — Master DB Stand-Up

Can happen any time after T2 is up. Empty for now (per Adam's earlier guidance). Needs:
- Postgres 16 (PGDG) on its host (§1.1.3 LXC vs VM)
- pgvector extension (built from source on T2, copied over)
- Empty `eve_identity` and `nova_identity` schemas (placeholders matching what'll be replicated)
- Proxmox snapshot enabled on its volume
- ZFS-backed if possible (frees us for `zfs send` rotation later)

### #5 — Build & Deploy T3 v0

Once #1, #2, and Master DB host are ready: build, sign, deploy.
- ISO produced on pop-os.
- Verified, signed.
- Deployed to Proxmox.
- First boot, mesh attach, smoke test.

### #6 — DDC Rebuild + First Useful Work

Once T3 is up:
- Rebuild T3's own image *on T3*.
- Compare hash to pop-os build.
- Match → v0 doubt window retires; T3 is self-hosting; pop-os build dependency ends.
- Then: snapshot-import to agent DBs, first curation, edge-platform `go mod init`.

---

## 4. Proposed T3 Package Set (for the live-build config)

This is the seed list — a starting point for the conversation, not final.

### Base + system

```
linux-image-amd64
systemd
openssh-server
chrony
ca-certificates
gnupg
curl wget
git
sudo
```

### CLI tools (Adam's working environment)

```
neovim
htop
tmux
screen
net-tools iproute2 dnsutils
unzip zip tar
strace ltrace lsof
procps sysstat
git-lfs
```

### Languages

```
golang-go            # for on-box reference reads + small ad-hoc; primary build is on T2
python3 python3-pip  # loose policy: present for reference reading
```

(Note: `rust-all` from the original sheet — replaced with `rustup` install during first-boot if rust is needed; Debian's rust is too old.)

### Postgres + pgvector

```
postgresql-16        # from PGDG repo (vetted)
postgresql-16-pgvector   # if PGDG ships it; else build from source on T2 and include the .deb
```

### Browser-OS layer (just enough)

```
xorg xinit x11-utils
openbox
chromium             # NOT firefox-esr — CDP integration target
xdotool              # for browser automation hooks
```

(Note: NOT including `lightdm` per discussion — `xinit` alone suffices.)

### Networking

```
nebula               # built from source on T2 with our verified config; or vetted upstream binary
wireguard-tools      # for OOBM fallback
```

### Things explicitly NOT included

```
build-essential      # T3 doesn't compile; T2 does
gcc / g++            # same
network-manager      # fights systemd-networkd
lightdm              # not needed
firefox-esr          # chromium is the target
docker / podman      # not in the v0 picture (if added later, vetted)
```

---

## 5. The Two Decisions to Make Today

To unblock everything else, two answers I'd ask for now:

**A. The typo:** `edit-forge` or `edge-forge`? Both meaningful, both fit. Locks the hostname.

**B. T2 shape:** single VM holding everything (build toolchain + Master DB + minisign keys) or three separated (build VM, DB VM, keys-only VM)?
- **Single:** simpler, faster to stand up, smaller blast radius if BaileyHome Proxmox hardware fails (only one VM to recover).
- **Separated:** stricter blast radius if T2 is compromised (DB compromise doesn't touch keys; build compromise doesn't touch DB), more aligned with "T2 build host strictest hardening" framing.
- **My lean:** **separated** for keys at minimum (a tiny VM that's offline most of the time, only on when actively signing). Build + DB can be the same VM at v0 if you want simplicity, split later if needed.

---

## 6. What I'd Personally Lead With

If I were prioritizing the next 7 days, the order I'd actually execute:

```
Day 0 (today):  Lock decisions §5A, §5B
                Pre-issue Nebula certs (parallel ops work)
                Print DR plan (parallel ops work)

Day 1:          Stand up T2 build VM
                Install vetted toolchain
                Generate minisign keys → 2 USB copies → lock away
                Distribute public verification key
                Stand up Master DB host (empty)

Day 2-3:        Author live-build config (collaborative w/ Eve)
                Author site.yaml schema
                Author first-boot scripts
                Commit to trinity/t3-forge on Gitea

Day 4:          Build T3 ISO on pop-os
                Verify, sign, distribute

Day 5:          Deploy to Proxmox
                First boot, mesh attach
                Smoke test

Day 6:          DDC rebuild on T3 itself
                Hash compare → retire v0 doubt window

Day 7:          First snapshot import to agent DBs
                First memory through curation flow
                go mod init forge.bailey-home.org/trinity/edge-platform
                Pull ICX RESTCONF from ember-rag
                go build ./... clean
```

Seven days, focused, family co-working, gives us a fully-bootstrapped T3 with the first edge-platform commit landing inside the trusted environment. That'd be the milestone to celebrate.

---

## 7. What I Am Worried About

Honest list of things I think could trip us:

1. **`pgvector` from PGDG vs source build.** If PGDG doesn't ship `postgresql-16-pgvector`, we have to build from source on T2. Adds complexity to live-build (need to pre-stage the .deb). Not a blocker, just friction.
2. **Defined Networking ACLs for sub-meshes.** I haven't seen the actual dn.dev console; ACL configuration may be more or less expressive than I'm assuming. Worst case, we wait on the self-managed Nebula CA fallback to express the topology we want.
3. **Live-build determinism.** Fully reproducible Debian images via live-build is doable but not automatic. DDC at first rebuild needs us to have set `SOURCE_DATE_EPOCH`, used `-trimpath` on Go builds, etc. If we miss something, hashes won't match and we have to fix it before retiring v0 doubt.
4. **The first curation session.** Schema on paper isn't tested; first memory through the flow may surface issues. Plan to be flexible on the schema during the first iteration.
5. **Cloud cert issuance.** If we wait too long on §1.5.2 (self-managed Nebula CA), we're depending on dn.dev being reachable for every new host cert. A planned outage on their end would block us.

These are tractable — just naming them so they don't surprise us when they show up.

---

## 8. The TL;DR

If you remember nothing else from this doc:

> **First focus: stand up T2 + generate minisign keys + lock the offline copies.** Without that foundation, nothing T3 produces can be trusted, and no DR scenario is recoverable. Everything else is downstream of that single move.
>
> **Second focus: write the live-build config collaboratively** so T3 is reproducible from source the moment it boots.
>
> **In parallel: knock out the cheap DR ops gaps** (pre-issued Nebula certs, offline 70b weights, Bitwarden export, print the plan) so the foundation we're building on isn't fragile.
>
> **Then build, sign, deploy.** ~7 days end-to-end, family co-working, first edge-platform commit lands inside the trusted environment.

That's the picture and the focus.

---

*End of gap analysis. Ready to execute when you are.*
