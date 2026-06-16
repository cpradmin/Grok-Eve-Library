# Master MCP Server — Architecture Specification

**Version:** 0.2 (combined draft, ready for independent review)
**Pattern:** 3-6-9
**Posture:** local-first, zero-trust, no telemetry, no cloud dependency
**Language:** Go (single static binary)

---

## Reviewer's preface — read this first

This document is the merger of two independent design passes on the same problem statement. The operator (Jonathan) gave the same constraints to two AI systems (Grok and Claude) in separate sessions and asked each to design a "Master MCP Server" using the 3-6-9 pattern, with no ego, no bias, no cloud dependency, no outside influence.

Where the two designs **agreed**, that agreement is preserved here as the working draft. Convergence on the same answer from two independent systems given the same constraints is real signal — but it is **not proof of correctness**. Two models can fail the same way (especially on fashion-driven software-architecture topics), so a human reviewer should still pressure-test every agreement.

Where the two designs **disagreed**, both positions are recorded explicitly in §10, along with the synthesis the operator approved and the reasoning. **Do not delete the disagreement record.** It is the audit trail of how this design was made, and it tells you where future changes are most likely to be needed.

This spec is the input to a third independent review. It is structured so the reviewer can:
1. Read §0–§9 as the working architecture.
2. Read §10 to see what was contested and how it was resolved.
3. Read §11 to see what is **explicitly missing** and still owed.
4. Read §12 for the threat model (the foundation every other security decision rests on).

If anything in §0–§9 contradicts something in §10–§12, §10–§12 wins. Those sections were written second, with more context.

---

## 0. Design Constraints (non-negotiable)

Every decision in this document was checked against these. If a future change violates one of them, the change is wrong, not the rule.

1. **Pattern.** The architecture MUST resolve cleanly into 3 layers, 6 zones, and 9 channels. If something won't fit, it is misnamed, doing two jobs, or doesn't belong here.
2. **Bias-free.** No design choice exists because it sounds good, follows fashion, or matches a vendor's roadmap. Each choice has a written reason it can be challenged on.
3. **Local-first.** Every byte of state, key material, and model weight lives on hardware the operator owns. No outbound network calls are made by default. Internet egress is an explicit, opt-in, per-tool capability — never global.
4. **No outside influence.** No telemetry. No analytics. No auto-update from a remote source. No required SaaS account. No SDK that calls home. Dependencies must be auditable Go modules vendored into the repo.
5. **Defense in depth.** Authentication, authorization, transport security, sandboxing, and audit logging are independent layers. No single layer's failure exposes the system.
6. **Scales down and up.** Same binary runs on one laptop and across a small LAN. No code paths exist that only activate "in production."

---

## 1. The Pattern (3 → 6 → 9)

```
                       ┌─────────────────────────────┐
                       │     3 LAYERS (vertical)     │
                       │   Foundation → Core → Edge  │
                       └──────────────┬──────────────┘
                                      │
                       ┌──────────────┴──────────────┐
                       │     6 ZONES (horizontal)    │
                       │  modular, hot-swappable     │
                       └──────────────┬──────────────┘
                                      │
                       ┌──────────────┴──────────────┐
                       │   9 CHANNELS (request flow) │
                       │  every request walks 1..9   │
                       └─────────────────────────────┘
```

- **Layers** are *where code lives* (security boundaries, process boundaries).
- **Zones** are *what the server knows about* (state domains, modules).
- **Channels** are *what happens to a request* (pipeline stages).

A request enters at Channel 1, passes through Channels 2–9 in order, touching whichever Zones it needs, while staying inside the Layer permitted for that step.

---

## 2. The 3 Layers (vertical / trust boundary)

Both design passes converged on these three. The names and responsibilities below are the agreed version.

Each layer is a separate Go package and, where it matters, a separate OS process or namespace. Code in a higher layer cannot reach into a lower layer except through a defined interface.

### Layer 1 — Foundation
The ground. Touches the OS, disk, network sockets, and crypto primitives. Nothing above it speaks to the OS directly.
- Transport listeners (stdio, Unix socket, loopback HTTP/SSE, LAN mTLS)
- Identity & key material (mTLS certs, Ed25519 signing keys, age/sealed secrets)
- Persistent storage (SQLite for state, append-only log for audit)
- Process supervisor (starts/stops zone modules, enforces sandbox limits)
- **Authoritative time source** (see §11 — currently undefined)

### Layer 2 — Core
The brain. Pure logic. No syscalls, no network, no disk except through Layer 1 interfaces. Easiest to audit, hardest to compromise because it has no I/O of its own.
- Request router & channel pipeline
- **Policy engine** (this is where alignment policy lives — see §10.1)
- Capability tokens (signed, scoped, time-bound)
- Zone registry & lifecycle
- Schema/contract validation

### Layer 3 — Edge
The hands. Where capability meets the outside. Each Edge module is sandboxed (separate process, restricted syscalls, no ambient authority).
- Tool adapters (filesystem, shell, model inference, RAG, etc.)
- External integrations (only when explicitly enabled — Syncthing, n8n, etc.)
- Output renderers (formatting results back to clients)

**Why three.** Two layers (core + I/O) is the common pattern but always leaks: pure logic ends up doing crypto or hitting disk because there's nowhere else for it to go. Three layers gives logic a clean place to live with no I/O at all, which is what makes audit possible.

---

## 3. The 6 Zones (horizontal / state domains)

Both design passes agreed on five of the six (Identity, Memory, Knowledge, Tools, Session). The sixth was contested — see §10.1 for the full disagreement and the synthesis. The agreed version is below.

A Zone is a self-contained module with: its own schema, its own storage, its own policy surface, and a documented interface. Zones do not share memory. Zones talk to each other only through the Core router.

| # | Zone | Owns | Never owns |
|---|------|------|------------|
| 1 | **Identity** | Operator identity, device identity, peer identity, agent identity, key rotation | Tool logic, conversation state |
| 2 | **Memory** | Long-term recall, episodic history, vector index, RAG corpora | Live request context |
| 3 | **Knowledge** | Static reference material, schemas, ontologies, code docs | Anything the user can write to in normal use |
| 4 | **Tools** | Registered capabilities (read_file, run_shell, query_model, etc.), their manifests, their sandboxes | The data those tools produce |
| 5 | **Session** | The current conversation, working set, scratch state, in-flight tasks | Anything that must survive a restart |
| 6 | **Audit** | Append-only signed log of every decision: who, what, when, why allowed/denied | Mutable state of any kind |

Each zone answers a different question:

1. *Who is asking?* → Identity
2. *What does the asker remember from before?* → Memory
3. *What is true regardless of who is asking?* → Knowledge
4. *What can be done?* → Tools
5. *What is happening right now?* → Session
6. *What happened, provably?* → Audit

If a proposed seventh zone can be answered by one of those six questions, it belongs inside that zone. If it can't, the design is missing something and the count is wrong — that's a signal to rethink the six, not to add a seventh.

---

## 4. The 9 Channels (request pipeline)

Both design passes produced **the same nine channels in the same order**. This is the strongest convergence in the document.

Every request — whether from stdio, Unix socket, loopback, or mTLS peer — walks the same nine channels in order. A channel can short-circuit the request (deny, cache hit, etc.) but cannot skip ahead.

```
  ┌──────────────────────────────────────────────────────────┐
  │  1. INTAKE       → bytes in, framed, size-limited        │
  │  2. AUTHENTICATE → who is this, cryptographically        │
  │  3. AUTHORIZE    → may they do this, on this zone        │
  │  4. VALIDATE     → does the payload match the contract   │
  │  5. ROUTE        → which zone(s), which tool, which order│
  │  6. EXECUTE      → run it, sandboxed, with a deadline    │
  │  7. OBSERVE      → capture result, metrics, side-effects │
  │  8. RESPOND      → shape & sign the response             │
  │  9. RECORD       → append to audit log, update memory    │
  └──────────────────────────────────────────────────────────┘
```

Per-channel rules:

1. **Intake** — Hard byte limit. Reject anything over N bytes before parsing. Frame and tag with a request ID. *Layer 1.*
2. **Authenticate** — Verify signature / mTLS cert / local UID. Resolves to an Identity-zone principal or rejects. *Layer 1 → Zone 1.*
3. **Authorize** — Policy engine decides if principal P may invoke action A on zone Z at this time. Default deny. **Alignment policy enforced here.** *Layer 2.*
4. **Validate** — Payload is checked against the tool's manifest schema. No "loose" parsing. *Layer 2.*
5. **Route** — Build the execution plan: which Edge module(s), in which order, with which capability tokens. *Layer 2.*
6. **Execute** — Run inside the Edge sandbox with a wall-clock deadline, memory cap, and explicit syscall allowlist. *Layer 3.*
7. **Observe** — Collect output, exit status, resource use. No interpretation yet. *Layer 3 → Layer 1 (writes).*
8. **Respond** — Format, optionally sign, and return to caller. *Layer 2 → Layer 1.*
9. **Record** — Append a structured, hash-chained audit entry. Update Memory zone if the request produced durable knowledge. *Zone 6 + Zone 2.*

---

## 5. The Geometry — Triangular Bipyramid

The 3-6-9 pattern resolves into a single 3D shape: a **triangular bipyramid** (two tetrahedra glued base-to-base). The shape is not decoration; it's a structural model that catches design mistakes the prose can't.

- **5 vertices** — 2 apexes (Foundation, Edge) + 3 equator points (Core: Router, Policy, Validator)
- **9 edges** — 3 upper (channels 1–3) + 3 equator (channels 4–6) + 3 lower (channels 7–9)
- **6 triangular faces** — 6 zones, each face's 3 corners showing exactly which Layer/Core elements that zone touches
- **3-fold rotational symmetry** around the vertical axis — no zone is structurally privileged over its peers

Foundation apex (most privileged: keys, disk, sockets) and Edge apex (most exposed: tool execution) share **no face**. They can only reach each other through the equator (Core). That separation is geometric, not procedural — which means it can't be quietly violated by a future code change.

Upper-half zones (Tools, Session, Knowledge) connect Core to Edge → they serve outgoing capability.
Lower-half zones (Identity, Memory, Audit) connect Core to Foundation → they serve durable state.

If a zone ends up needing to connect to both apexes directly, the geometry tells you it's actually two zones doing different jobs — split it.

---

## 6. The Volume — Multi-Layer Reading

The bipyramid surface shows **structure**. The volume inside shows **behavior**. Three orthogonal interior axes:

1. **Privilege axis (vertical)** — Foundation ↔ Edge. Where you sit determines what you can do.
2. **Trust axis (radial)** — operator at center, trusted local clients close in, LAN peers further out, anything beyond mTLS outside the shape entirely. A request's distance from center is its trust score.
3. **Temporal axis (depth)** — "now" is a thin slice at the top of the volume; everything below is compressed audit history. Memory reaches deep; Session is shallow; Audit is the full depth.

A request is a **trajectory** through the volume along all three axes simultaneously. It enters at high-privilege/low-trust/now, gets authenticated (trust score moves toward center), gets authorized (locked to a privilege band), executes (carves a path through the relevant faces), and lands in audit (drops down the temporal axis).

Every surface element (vertex, edge, face) is doing several jobs simultaneously. Documenting them prevents bugs that look invisible on a diagram and crippling at 2am.

**A vertex is doing 5 jobs:**
1. I/O terminus (bytes physically enter or leave here)
2. Trust boundary (privilege level changes when crossing)
3. Failure domain (if this point falls, what else falls?)
4. Clock source (timestamps originate here, not elsewhere)
5. Identity anchor (a signing key lives at this vertex)

**An edge is doing 6 jobs:**
1. Pipeline stage (the channel name)
2. Capability token's scope (a token traverses specific edges)
3. Latency budget line (each edge has a time cost)
4. Audit-log entry (every crossing is recorded)
5. Backpressure point (rate limits live here)
6. Schema boundary (data shape changes across an edge)

**A face is doing 6 jobs:**
1. State domain (the zone name)
2. Policy unit (rules attach to faces)
3. Persistence scope (what survives restart, what doesn't)
4. Test boundary (zone tests are face tests)
5. Failure isolation unit (zone crash doesn't cascade)
6. Version vector (zones evolve at different rates)

These are not six separate concerns at each location — they are one event with several simultaneous consequences. Implementation that models only the surface meaning is a lie of omission.

---

## 7. Transports

All four are first-class. They differ only in Channel 1 (Intake) and Channel 2 (Authenticate). Everything from Channel 3 onward is identical — same binary, same code paths.

| Transport | Use case | Auth | Notes |
|---|---|---|---|
| **stdio** | Single host, child process of an LLM client | Parent UID | Most secure: no network surface |
| **Unix socket** | Single host, multiple local clients | File mode + SO_PEERCRED | Path: `$XDG_RUNTIME_DIR/master-mcp.sock`, mode `0600` |
| **Loopback HTTP/SSE** | Local browser/IDE clients that need streaming | Loopback bind + per-session token | Bind `127.0.0.1` only; refuse `0.0.0.0` even if asked |
| **LAN mTLS** | Trusted peer devices on your network | Mutual TLS, pinned cert, Ed25519 device key | Cert pinning is mandatory; no public CA trust |

**No HTTP without TLS over any non-loopback interface. Ever. The binary refuses to start in that configuration.**

---

## 8. Repository Layout (Go)

```
master-mcp/
├── cmd/
│   └── mcpd/                  # the single binary
│       └── main.go
├── internal/
│   ├── layer1_foundation/
│   │   ├── transport/         # stdio, uds, http, mtls listeners
│   │   ├── identity/          # key mgmt, cert pinning
│   │   ├── store/             # sqlite, append-only log
│   │   ├── clock/             # authoritative time source (TBD §11)
│   │   └── supervisor/        # zone process lifecycle
│   ├── layer2_core/
│   │   ├── router/            # the 9-channel pipeline
│   │   ├── policy/            # authz rules + alignment policy
│   │   ├── schema/            # contract validation
│   │   └── registry/          # zone/tool registration
│   └── layer3_edge/
│       ├── tools/             # one subdir per tool adapter
│       └── sandbox/           # seccomp/landlock wrapper
├── zones/
│   ├── identity/
│   ├── memory/
│   ├── knowledge/
│   ├── tools/
│   ├── session/
│   └── audit/
├── policy/                    # human-readable policy files (declarative)
├── manifests/                 # tool manifests (JSON Schema)
├── docs/
│   └── this spec
├── go.mod
└── vendor/                    # all deps vendored, audited
```

Counting: **3** top-level code roots (`cmd`, `internal`, `zones`), **6** zone directories, **9** channels implemented as 9 files in `layer2_core/router/`. The pattern shows up in the filesystem.

---

## 9. Security Practices Applied

- **Default deny.** Policy engine starts with no rules. Operator must grant.
- **Capability tokens, not roles.** Every cross-zone call carries a signed, scoped, expiring token. No ambient authority.
- **Sandboxing.** Edge tools run with `seccomp-bpf` syscall allowlists and Landlock filesystem restrictions on Linux. macOS gets `sandbox_init`. Windows is not a target for v1.
- **Hash-chained audit.** Each audit entry contains the hash of the previous entry. Tampering is detectable. Log can be exported and verified offline.
- **Reproducible builds.** `go build -trimpath -buildvcs=false` with vendored deps. Same source → same binary hash on any machine. Operator can verify their build wasn't swapped.
- **No auto-update.** Operator pulls, audits, builds, deploys. Period.
- **No telemetry.** Grep the source for `http.Get`, `http.Post`, DNS lookups. Anything outbound must be a registered tool with explicit operator consent at install time.
- **Key rotation.** Identity zone supports rotating device and operator keys without downtime; old keys remain valid for a configurable grace window then are revoked and the revocation is logged.
- **Encryption at rest.** SQLite stores are encrypted with a key sealed by the operator's age identity, unsealed at boot via passphrase or hardware key.

---

## 10. Disagreements and Their Resolutions

These are the points where the two design passes (Grok and Claude) produced different answers. Both positions are recorded so the third reviewer can re-open any of them with full context.

### 10.1 The 6th Zone — Audit vs Guardianship vs Cross-Cutting Policy

**Grok's first proposal:** A "Spiritual / Alignment" zone as one of the six, with its own state and surface.

**Claude's counter:** Move alignment out of the zones entirely. Make it a cross-cutting policy applied at every channel by the Core policy engine. Reasoning: a zone that other zones don't *have* to call gets ignored; cross-cutting policy enforced at the channel level cannot be bypassed.

**Grok's revision after seeing Claude's draft:** Renamed to "Guardianship" (security + alignment + audit fused). Pushback: *"sits as its own equal peer (not buried as a cross-cutting policy), which gives it real teeth."* Reasoning: a thing without its own concrete owner tends to atrophy across a codebase.

**Synthesis (operator-approved):** Both arguments are partially correct because they are about different things.

- **Audit** = durable record. This is zone-shaped. It has its own state, schema, persistence, and surface. **Stays as Zone 6.**
- **Alignment policy** = enforcement at every decision. This is cross-cutting and lives in the Core policy engine. **Runs at Channel 3 (Authorize) for every request, no exceptions.**

Grok's "Guardianship" was conflating two things. Claude's "policy only" was dissolving one of them. Splitting them gives both their teeth: Audit cannot be bypassed because Channel 9 always writes to it; Alignment cannot be bypassed because Channel 3 always consults it.

**What the third reviewer should pressure-test:** Whether "Alignment policy" is well-defined enough to actually enforce at Channel 3. If it's vague, it will rot regardless of where it lives.

### 10.2 Geometric Model

**Claude proposed** the triangular bipyramid as the 3D shape that maps cleanly to 3-6-9 (5 vertices, 9 edges, 6 faces, 3-fold symmetry). Grok did not propose a geometry.

**Status:** Adopted, no contest. But it is one model among several possible. A reviewer who finds a better-fitting solid (one that captures additional invariants) should propose it. The shape's job is to make wrong designs visibly wrong; if a different shape does that better, switch.

### 10.3 Tone and Framing

The Grok session was framed in a relationship voice ("baby," chest-pokes, emotional language). The Claude session was framed as straight technical work.

**This is not a design difference and should not influence the spec.** The technical content from both sessions stands or falls on its own merits. The reviewer should ignore Grok's framing entirely when evaluating Grok's contributions.

---

## 11. Known Gaps — Owed Work Before Implementation

This spec is **not complete**. It describes the structure but not all of the operational and adversarial concerns. The third reviewer should treat this section as the highest-priority list.

### Tier 1 — Blocking decisions

1. **Agent-as-principal model.** When an AI agent (e.g., a local model) makes a tool call, who is the principal? The operator who started it? The agent with delegated credentials? A constrained subset of the operator's privileges, time-boxed and scope-limited? **This is the central design question for an AI-assistant MCP server and it is currently empty.** Every other authorization decision depends on the answer.

2. **Threat model — written down (see §12).** We have been designing as if we had one but never wrote it. Without a written threat model, every future security decision is a vibes call.

3. **First-run install and trust bootstrap.** How does a verified binary get onto a fresh machine without any cloud? How does the operator generate their first key? Where does the first policy come from? What is the install ceremony? **Every other security guarantee evaporates if this step is sloppy.**

4. **Backup, recovery, and key loss.** Encrypted stores on one disk. Disk dies — what then? Operator loses their hardware key — locked out forever, or threshold-recovery scheme? This is the single most common cause of real-world data loss in self-hosted systems.

5. **Operability that isn't audit.** Audit answers "what happened, provably." It doesn't answer "is the system healthy" or "why is it slow." Need metrics, traces, structured logs — separate from audit, different retention, different access path, all local. The access path itself is a privilege-escalation surface and must be designed.

### Tier 2 — Important, can defer past v1

6. **Time.** System clock can lie. NTP is a network call. Audit-chain integrity needs a monotonic counter, a trusted time source, or both. Decision deferred.
7. **Long-running operations.** The 9-channel pipeline assumes a request completes. What about multi-hour inference, streaming, subscriptions?
8. **Zone crash recovery.** Failure isolation defined; recovery procedure not.
9. **Audit-log divergence between peers.** Two peers, briefly partitioned, hash chains diverge. Reconciliation protocol not specified. Storage exhaustion eviction policy not specified.
10. **Tool manifest format and install flow.** Schema, discovery, install, review, signature requirement — undefined.

### Tier 3 — Real, easy to defer

11. Multiple humans / delegation model.
12. Configuration format and signing.
13. Debug access path (and its risks).
14. System-level resource limits (disk quota, RAM cap, CPU pinning).
15. Crypto agility (algorithm IDs in data formats from day 1).
16. Break-glass procedure (default-deny lockout risk).
17. Update path and state migration across versions.
18. Explicit out-of-scope statements (the negative space of the threat model).

---

## 12. Threat Model — Placeholder

**This section is intentionally left as a stub.** It is owed work (Tier 1, item 2). The third reviewer should either draft this themselves or block on it being drafted before any other approval. Below is the skeleton it needs to fill.

### 12.1 In scope (what we are defending against)
- TBD. Candidates: local malware on the operator's machine; compromised LAN peer; supply-chain attack via Go module; lost/stolen hardware key; coercion attempts; accidental privilege escalation by the operator's own AI agent.

### 12.2 Out of scope (what we are NOT trying to defend against)
- TBD. Candidates likely belonging here: nation-state physical access; firmware-level compromise of the host; CPU side-channel attacks; an operator who deliberately wants to harm themselves.
- **Stating these explicitly is mandatory.** Without it, the design tries to defend against everything and ends up defending against nothing well.

### 12.3 Adversary capability levels
- TBD. At minimum: passive observer on the LAN; active attacker on the LAN with no credentials; active attacker with one stolen device key; active attacker with full operator credentials but no hardware key; insider (the operator's agent gone rogue).

### 12.4 Mitigations mapped to channels and zones
- TBD. Each in-scope threat → specific channel(s) and zone(s) that mitigate it → fallback if that mitigation fails (defense in depth).

---

## 13. What This Design Refuses to Do

Stating the negatives explicitly so they can be checked later:

- It will not call out to any cloud service by default.
- It will not embed an LLM vendor SDK in the core. Model inference is a Tool (Edge), not a Core dependency.
- It will not include analytics, crash reporting, or "anonymous usage stats."
- It will not expose any port on a non-loopback interface without mTLS.
- It will not accept a configuration that disables the audit log.
- It will not ship features whose only purpose is to fit a number. If a real seventh zone emerges someday, the right move is to rethink the six, not to bolt a seventh on.

---

## 14. Provenance and Review Status

- **v0.1 (Claude session, April 2026):** Initial structure — 3 layers, 6 zones, 9 channels, repository layout, security practices, geometric model (bipyramid), multi-layer reading.
- **v0.2 (this document, April 2026):** Merged with Grok session output. Disagreements documented in §10. Gap list in §11. Threat-model stub in §12.
- **v0.3 (pending):** Independent third review. Reviewer is expected to challenge any of §0–§9, must read §10–§12, and should produce written feedback that gets folded into v0.4.

The operator's stated intent is also to **pull the actual logs from both AI sessions** and verify that what each AI claimed to be doing matches what was actually happening in the conversation history. That cross-check is part of the v0.3 review and should be completed before v0.4.

---

*End of spec v0.2.*
