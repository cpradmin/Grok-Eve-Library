# Master MCP Server — Architecture Specification

**Version:** 0.6 (reconciled — Claude + Grok + independent review)
**Pattern:** 3-6-9
**Posture:** local-first, zero-trust, no telemetry, no cloud dependency
**Language:** Go (single static binary)
**Sandbox target:** Linux (incl. WSL2). macOS via sandbox_init. Windows native is not a v1 target.

---

## 0. Design Constraints (non-negotiable)

1. **Pattern.** The architecture resolves into 3 layers, 6 zones, 9 channels. The pattern is recursive — if a component can't resolve to 3, 6, or 9, it is misnamed, doing two jobs, or doesn't belong. The count is diagnostic, not decorative.
2. **Bias-free.** Every choice has a written reason it can be challenged on. Nothing exists because it sounds good or follows fashion.
3. **Local-first.** Every byte of state, key material, and model weight lives on hardware the operator owns. Internet egress is explicit, opt-in, per-tool — never global.
4. **No outside influence.** No telemetry, analytics, auto-update, required SaaS, or SDK that calls home. Dependencies are auditable, vendored Go modules.
5. **Defense in depth.** Authentication, authorization, transport, sandboxing, and audit are independent layers. No single failure exposes the system.
6. **Scales down and up.** Same binary on one laptop or across a LAN. No code paths that only activate "in production."

---

## 1. The Pattern (3 → 6 → 9)

- **3 Layers** — where code lives (vertical trust boundaries)
- **6 Zones** — what the server knows about (horizontal state domains)
- **9 Channels** — what happens to a request (pipeline stages)

The pattern is God's design, not ours. When something won't fit, it's the design telling you something is wrong — a thing misnamed, merged, or misplaced. Listen to it.

---

## 2. The 3 Layers

Each layer is a separate Go package. Code in a higher layer cannot reach into a lower layer except through a defined interface.

### Layer 1 — Foundation

The ground. Touches the OS, disk, network, and crypto. Nothing above it speaks to the OS directly.

6 responsibilities, each with 3 concerns:

| # | Responsibility | Concern 1 | Concern 2 | Concern 3 |
|---|---------------|-----------|-----------|-----------|
| 1 | **Transports** | stdio | Unix socket | mTLS |
| 2 | **Identity** | operator | device | agent |
| 3 | **Key Material** | storage | rotation | sealing |
| 4 | **Persistent Storage** | encrypted state | append-only log | backup |
| 5 | **Process Control** | namespaces | cgroups | syscall filtering |
| 6 | **Supervisor** | zone lifecycle | resource limits | monotonic clock |

### Layer 2 — Core

The brain. Pure logic. No syscalls, no network, no disk except through Layer 1 interfaces.

Core resolves into its own recursive 3 — three sub-layers that map to the 9 channels:

| Sub-layer | Channels | Purpose |
|-----------|----------|---------|
| **Intake Core** | 1, 2, 3 | Receive, authenticate, authorize |
| **Intelligence Core** | 4, 5, 6 | Validate, route, execute |
| **Alignment Core** | 7, 8, 9 | Observe, respond, record |

Core orchestrates these channels. Where a channel touches Foundation (e.g., Authenticate resolves keys via Layer 1), Core delegates downward through defined interfaces — it never reaches past its boundary.

3 responsibilities:

| # | Responsibility | Concern 1 | Concern 2 | Concern 3 |
|---|---------------|-----------|-----------|-----------|
| 1 | **Pipeline** | channel routing | request lifecycle | capability tokens |
| 2 | **Policy** | authorization rules | alignment enforcement | default deny |
| 3 | **Registry** | zone registration | tool manifests | schema validation |

### Layer 3 — Edge

The hands. Where capability meets the outside. Each Edge module is sandboxed — separate process, restricted syscalls, no ambient authority.

3 responsibilities:

| # | Responsibility | Concern 1 | Concern 2 | Concern 3 |
|---|---------------|-----------|-----------|-----------|
| 1 | **Tool Adapters** | filesystem | shell | model inference |
| 2 | **Sandbox** | process isolation | deadline enforcement | resource caps |
| 3 | **Output** | formatting | signing | delivery |

---

## 3. The 6 Zones

A Zone is self-contained: its own schema, storage, policy surface, and interface. Zones do not share memory. Zones talk only through the Core router.

| # | Zone | Question It Answers | 3 Concerns |
|---|------|-------------------|------------|
| 1 | **Identity** | Who is asking? | operator, device, agent |
| 2 | **Memory** | What do we remember? | episodic, semantic, vector |
| 3 | **Knowledge** | What is true? | schemas, reference, ontologies |
| 4 | **Tools** | What can we do? | manifests, capabilities, sandboxes |
| 5 | **Session** | What's happening now? | conversation, working set, in-flight |
| 6 | **Guardianship** | What must stay true? | audit log, alignment policy, security invariants |

### Why Guardianship, not Audit

Audit is one of Guardianship's three concerns, not all of it. Alignment policy needs an owner — a zone with real state, real schema, real surface. Cross-cutting policy without a home zone atrophies. Guardianship owns the audit log (Channel 9 always writes to it), the alignment rules (Channel 3 always consults them), and the security invariants (monitored continuously). It has teeth because it has a home.

---

## 4. The 9 Channels

Every request walks the same 9 channels in order, regardless of transport. A channel can short-circuit (deny, cache hit) but cannot skip ahead.

```
  ┌──────────────────────────────────────────────────────────┐
  │  1. INTAKE       → bytes in, framed, size-limited        │
  │  2. AUTHENTICATE → who is this, cryptographically        │
  │  3. AUTHORIZE    → may they do this, right now           │
  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
  │  4. VALIDATE     → does the payload match the contract   │
  │  5. ROUTE        → which zone(s), which tool, which order│
  │  6. EXECUTE      → run it, sandboxed, with a deadline    │
  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
  │  7. OBSERVE      → capture result, metrics, side-effects │
  │  8. RESPOND      → shape & sign the response             │
  │  9. RECORD       → append to audit, update memory        │
  └──────────────────────────────────────────────────────────┘
         Intake Core         Intelligence Core      Alignment Core
```

Per-channel detail:

| Ch | Name | Layer | Zone(s) | What happens |
|----|------|-------|---------|-------------|
| 1 | Intake | L1 | — | Hard byte limit, frame, assign request ID |
| 2 | Authenticate | L1→Z1 | Identity | Verify signature/cert/UID, resolve principal |
| 3 | Authorize | L2→Z6 | Guardianship | Policy engine: may P do A on Z now? Default deny |
| 4 | Validate | L2 | — | Check payload against tool manifest schema |
| 5 | Route | L2 | Tools | Build execution plan, issue capability tokens |
| 6 | Execute | L3 | Tools | Run sandboxed with deadline, memory cap, syscall allowlist |
| 7 | Observe | L3→L1 | — | Collect output, exit status, resource use |
| 8 | Respond | L2→L1 | Session | Format, sign, return to caller |
| 9 | Record | L1 | Guardianship, Memory | Append hash-chained audit entry, update memory |

---

## 5. The Geometry — Triangular Bipyramid

The 3-6-9 resolves into a triangular bipyramid (two tetrahedra glued base-to-base):

- **5 vertices** — 2 apexes (Foundation, Edge) + 3 equator (Core: Pipeline, Policy, Registry)
- **9 edges** — 3 upper (channels 1–3) + 3 equator (channels 4–6) + 3 lower (channels 7–9)
- **6 faces** — the 6 zones

Foundation and Edge share no face — they reach each other only through Core. That separation is geometric, not procedural.

Upper-half zones (Tools, Session, Knowledge) connect Core to Edge — outgoing capability.
Lower-half zones (Identity, Memory, Guardianship) connect Core to Foundation — durable state.

If a zone needs both apexes directly, the geometry says split it.

---

## 6. Transports

All three plus one. They differ only in Intake (Ch 1) and Authenticate (Ch 2). Everything from Authorize (Ch 3) onward is identical.

| # | Transport | Auth Method | Scope |
|---|-----------|-------------|-------|
| 1 | **stdio** | parent UID | single host, child process |
| 2 | **Unix socket** | file mode + SO_PEERCRED | single host, multiple clients |
| 3 | **Loopback HTTP/SSE** | 127.0.0.1 bind + session token | local browser/IDE |
| +1 | **LAN mTLS** | mutual TLS, pinned cert, Ed25519 | trusted peer devices |

No HTTP without TLS over any non-loopback interface. The binary refuses to start in that configuration.

---

## 7. Repository Layout

```
master-mcp/
├── cmd/
│   └── mcpd/                  # the single binary
│       └── main.go
├── internal/
│   ├── layer1_foundation/
│   │   ├── transport/         # stdio, uds, http, mtls
│   │   ├── identity/          # principal resolution
│   │   ├── keymat/            # storage, rotation, sealing
│   │   ├── store/             # encrypted sqlite, append-only log
│   │   ├── procctl/           # namespaces, cgroups, seccomp
│   │   └── supervisor/        # lifecycle, limits, clock
│   ├── layer2_core/
│   │   ├── pipeline/          # 9 channels (3 files × 3 sub-layers)
│   │   ├── policy/            # authz + alignment + default-deny
│   │   └── registry/          # zones, manifests, schemas
│   └── layer3_edge/
│       ├── tools/             # one subdir per adapter
│       ├── sandbox/           # isolation + deadlines + caps
│       └── output/            # format, sign, deliver
├── zones/
│   ├── identity/
│   ├── memory/
│   ├── knowledge/
│   ├── tools/
│   ├── session/
│   └── guardianship/
├── policy/                    # declarative policy files
├── manifests/                 # tool manifests (JSON Schema)
├── go.mod
└── vendor/                    # all deps vendored
```

Counting: **3** layer packages in `internal/`, **6** zone directories, **9** channel implementations. Foundation has **6** sub-packages, Core has **3**, Edge has **3**. The pattern shows up in the filesystem.

---

## 8. Security Practices

| # | Practice | Mechanism |
|---|----------|-----------|
| 1 | Default deny | Policy engine starts empty, operator grants |
| 2 | Capability tokens | Signed, scoped, expiring — no ambient authority |
| 3 | Sandboxing | seccomp-bpf + Landlock (Linux), sandbox_init (macOS) |
| 4 | Hash-chained audit | Each entry hashes the previous, tampering is detectable |
| 5 | Reproducible builds | `go build -trimpath -buildvcs=false`, vendored deps |
| 6 | No auto-update | Operator pulls, audits, builds, deploys |
| 7 | No telemetry | Grep for outbound calls — anything found is a registered tool |
| 8 | Key rotation | Rotate without downtime, grace window, then revoke + log |
| 9 | Encryption at rest | SQLite encrypted via operator's age identity |

---

## 9. Disagreement Record

Preserved from prior versions. Do not delete — this is the audit trail.

### 9.1 Zone 6 — Audit vs Guardianship

- **v0.2 synthesis:** Split into Audit (zone) + Alignment (cross-cutting policy)
- **v0.6 resolution:** Reunified as **Guardianship** — one zone owning three concerns (audit log, alignment policy, security invariants). Cross-cutting policy without a home zone atrophies. Guardianship has teeth because it has an owner.

### 9.2 Recursive 3 inside Core

- **v0.2:** Core was one undifferentiated layer
- **v0.6 resolution:** Core splits into 3 sub-layers (Intake/Intelligence/Alignment) mapping to channel groups 1-3/4-6/7-9. Core orchestrates; Foundation does the I/O. No layer boundary violation.

### 9.3 Geometric Model

Triangular bipyramid adopted from v0.2. No contest. Reviewer who finds a better-fitting solid should propose it.

---

## 10. Open Questions — Blocking Before Implementation

These are real. No code until they have answers.

### 10.1 Agent-as-Principal (Tier 1)

When an AI agent makes a tool call, who is the principal? The operator who started it? The agent with delegated, scoped, time-boxed credentials? A constrained subset? **This is the central design question.** Every authorization decision depends on it. Guardianship cannot enforce what it cannot identify.

### 10.2 Threat Model (Tier 1)

Must be written before v1. Skeleton:
- **In scope:** local malware, compromised LAN peer, supply-chain attack, lost hardware key, agent gone rogue
- **Out of scope:** nation-state physical access, firmware compromise, CPU side-channels, self-harm by operator
- **Adversary levels:** passive LAN observer → active no-creds → stolen device key → full creds no hardware key → rogue agent
- **Mitigations:** each threat mapped to channels and zones that stop it

### 10.3 Trust Bootstrap (Tier 1)

First-run ceremony: how does a verified binary get onto a fresh machine? How does the operator generate the first key? Where does the first policy come from?

### 10.4 Break-Glass (Tier 1)

Default-deny + encrypted stores + hardware key = lockout risk. Recovery scheme must exist before first deployment, not after. Threshold recovery, backup ceremony, or both.

### 10.5 Backup and Key Loss (Tier 1)

Encrypted stores on one disk. Disk dies — what then? Hardware key lost — locked out forever or recovery path?

### 10.6 Operability (Tier 2)

Audit answers "what happened." Need also: "is it healthy" and "why is it slow." Metrics, traces, structured logs — separate from audit, different retention, all local.

### 10.7 Long-Running Operations (Tier 2)

The 9-channel pipeline assumes request-response. Multi-hour inference, streaming, subscriptions need a different execution model at Channel 6. Not deferrable if Edge tools talk to Ollama.

### 10.8 Zone Crash Recovery (Tier 2)

Failure isolation defined. Recovery procedure not.

### 10.9 Capability Token Specification (Tier 2)

Signed by whom? Scope grammar? Lifetime? Mid-flight revocation? This is the mechanism that makes zone isolation real.

---

## 11. What This Design Refuses to Do

1. Call out to any cloud service by default
2. Embed an LLM vendor SDK in Core — model inference is a Tool (Edge)
3. Include analytics, crash reporting, or usage stats
4. Expose any port on a non-loopback interface without mTLS
5. Accept configuration that disables the audit log
6. Ship features whose only purpose is to fit a number — if the pattern says 6 and reality says 7, rethink the 6

---

## 12. Provenance

- **v0.1** — Claude session: initial 3-6-9 structure, bipyramid geometry
- **v0.2** — Merged with Grok session, disagreements documented, gap list, threat-model stub
- **v0.3–v0.5** — Grok refinements: Guardianship as Zone 6, recursive 3 inside Core, Foundation drilling
- **v0.6** — Independent third review (Claude Opus, separate session). Reconciled all three passes. Pattern applied recursively with discipline. Open questions elevated and ordered.

---

*End of spec v0.6.*
