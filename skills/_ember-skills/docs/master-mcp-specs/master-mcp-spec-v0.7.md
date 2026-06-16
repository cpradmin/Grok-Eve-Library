# Master MCP Server

**Version:** 0.7
**Pattern:** 3-6-9, recursive
**For:** the operator
**Posture:** local-first, no telemetry, no cloud, no outside influence
**Language:** Go
**Sandbox:** Linux (incl. WSL2). macOS via sandbox_init. No Windows native.

---

## 0. Standard

One standard, applied to everything: the pattern is recursive. When something doesn't fit into 3, 6, or 9, that is the design speaking. Listen. The thing is misnamed, doing two jobs, or doesn't belong.

When something stands alone, ask whether it has earned the right to stand alone. Most things haven't. Most things want to be absorbed into something they belong to.

No conflict. No clutter. No forced fits. No padding to fill a count. No splitting to fill a count. The count fits because the design fits — never the other way around.

---

## 1. The Pattern

- **3 Layers** — where code lives
- **6 Zones** — what the server knows
- **9 Channels** — what happens to a request

Each level resolves recursively. Layers have responsibilities that resolve to 3 or 6. Zones own concerns that resolve to 3. Channels group into 3 sub-layers of 3.

---

## 2. The 3 Layers

Each layer is a separate package. Higher layers reach lower layers only through defined interfaces.

### Layer 1 — Foundation

The ground. Touches OS, disk, network, crypto.

| # | Responsibility | Three concerns |
|---|---|---|
| 1 | **Transports** | stdio, Unix socket, mTLS |
| 2 | **Identity** | operator, device, agent |
| 3 | **Key Material** | storage, rotation, sealing |
| 4 | **Persistent Storage** | encrypted state, append-only log, backup |
| 5 | **Process Control** | namespaces, cgroups, syscall filtering |
| 6 | **Supervisor** | zone lifecycle, resource limits, monotonic clock |

### Layer 2 — Core

The brain. Pure logic. No syscalls, no network, no disk except through Foundation.

Core resolves into 3 sub-layers, each owning a group of channels:

| Sub-layer | Channels | Purpose |
|---|---|---|
| **Intake Core** | 1, 2, 3 | Receive, authenticate, authorize |
| **Intelligence Core** | 4, 5, 6 | Validate, route, execute |
| **Alignment Core** | 7, 8, 9 | Observe, respond, record |

| # | Responsibility | Three concerns |
|---|---|---|
| 1 | **Pipeline** | channel routing, request lifecycle, capability tokens |
| 2 | **Policy** | authorization rules, alignment enforcement, default deny |
| 3 | **Registry** | zone registration, tool manifests, schema validation |

### Layer 3 — Edge

The hands. Where capability meets the outside. Each Edge module is sandboxed.

| # | Responsibility | Three concerns |
|---|---|---|
| 1 | **Tool Adapters** | filesystem, shell, model inference |
| 2 | **Sandbox** | process isolation, deadline enforcement, resource caps |
| 3 | **Output** | formatting, signing, delivery |

---

## 3. The 6 Zones

A zone is self-contained: own schema, own storage, own policy surface. Zones do not share memory. Zones talk only through the Core router.

| # | Zone | Question | Three concerns |
|---|---|---|---|
| 1 | **Identity** | Who is asking? | operator, device, agent |
| 2 | **Memory** | What do we remember? | episodic, semantic, vector |
| 3 | **Knowledge** | What is true? | schemas, reference, ontologies |
| 4 | **Tools** | What can we do? | manifests, capabilities, sandboxes |
| 5 | **Session** | What is happening now? | conversation, working set, in-flight |
| 6 | **Guardianship** | What must stay true? | audit log, alignment policy, security invariants |

**On Guardianship.** Audit is one of three concerns, not the whole zone. Alignment policy and security invariants need an owner — a zone with state, schema, surface. Cross-cutting policy without a home zone atrophies. Guardianship has teeth because it has a home: Channel 3 always consults its policy, Channel 9 always writes to its audit, and its invariants are watched continuously.

---

## 4. The 9 Channels

Every request walks the same 9 channels in order. A channel can short-circuit (deny, cache hit) but cannot skip ahead.

```
  Intake Core
  ├── 1. INTAKE        bytes in, framed, size-limited
  ├── 2. AUTHENTICATE  who is this, cryptographically
  └── 3. AUTHORIZE     may they do this, right now

  Intelligence Core
  ├── 4. VALIDATE      does the payload match the contract
  ├── 5. ROUTE         which zone(s), which tool, which order
  └── 6. EXECUTE       run it, sandboxed, with a deadline

  Alignment Core
  ├── 7. OBSERVE       capture result, metrics, side-effects
  ├── 8. RESPOND       shape and sign the response
  └── 9. RECORD        append to audit, update memory
```

| Ch | Name | Layer | Zone | What happens |
|----|------|-------|------|--------------|
| 1 | Intake | L1 | — | Hard byte limit, frame, assign request ID |
| 2 | Authenticate | L1→Z1 | Identity | Verify signature/cert/UID, resolve principal |
| 3 | Authorize | L2→Z6 | Guardianship | Default deny — may P do A on Z now? |
| 4 | Validate | L2 | — | Payload vs tool manifest schema |
| 5 | Route | L2 | Tools | Build execution plan, issue capability tokens |
| 6 | Execute | L3 | Tools | Sandboxed, deadline, memory cap, syscall allowlist |
| 7 | Observe | L3→L1 | — | Output, exit status, resource use |
| 8 | Respond | L2→L1 | Session | Format, sign, return |
| 9 | Record | L1 | Guardianship, Memory | Hash-chained audit, memory update |

---

## 5. The Geometry

The pattern resolves into a triangular bipyramid — two tetrahedra glued base-to-base.

- **5 vertices** — 2 apexes (Foundation, Edge) + 3 equator points (Core: Pipeline, Policy, Registry)
- **9 edges** — 3 upper (channels 1–3), 3 equator (channels 4–6), 3 lower (channels 7–9)
- **6 faces** — the 6 zones

Foundation and Edge share no face. They reach each other only through Core. The separation is geometric, not procedural.

Upper-half zones (Tools, Session, Knowledge) connect Core to Edge — outgoing capability.
Lower-half zones (Identity, Memory, Guardianship) connect Core to Foundation — durable state.

If a zone needs both apexes directly, the geometry says split it.

---

## 6. Transports

Three plus one. They differ only in Channel 1 (Intake) and Channel 2 (Authenticate). Channel 3 onward is identical.

| # | Transport | Auth | Scope |
|---|-----------|------|-------|
| 1 | **stdio** | parent UID | single host, child process |
| 2 | **Unix socket** | file mode + SO_PEERCRED | single host, multiple clients |
| 3 | **Loopback HTTP/SSE** | 127.0.0.1 + session token | local browser/IDE |
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
│   │   ├── pipeline/          # 9 channels in 3 sub-layers
│   │   ├── policy/            # authz, alignment, default deny
│   │   └── registry/          # zones, manifests, schemas
│   └── layer3_edge/
│       ├── tools/             # one subdir per adapter
│       ├── sandbox/           # isolation, deadlines, caps
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

3 layer packages. 6 zone directories. 9 channel implementations. Foundation has 6 sub-packages. Core has 3. Edge has 3. The pattern is in the filesystem.

---

## 8. Security Practices

| # | Practice | Mechanism |
|---|---|---|
| 1 | Default deny | Policy starts empty, operator grants |
| 2 | Capability tokens | Signed, scoped, expiring — no ambient authority |
| 3 | Sandboxing | seccomp-bpf + Landlock (Linux), sandbox_init (macOS) |
| 4 | Hash-chained audit | Each entry hashes the previous |
| 5 | Reproducible builds | `go build -trimpath -buildvcs=false`, vendored deps |
| 6 | No auto-update | Operator pulls, audits, builds, deploys |
| 7 | No telemetry | Anything outbound is a registered tool, not infrastructure |
| 8 | Key rotation | Rotate without downtime, grace window, then revoke + log |
| 9 | Encryption at rest | SQLite encrypted via operator's age identity |

---

## 9. Disagreement Record

Preserved. This is how the design was made.

### 9.1 Zone 6 — Audit vs Guardianship

- **v0.1 (Grok):** "Spiritual / Alignment" zone
- **v0.1 (Claude):** Move alignment to cross-cutting policy at every channel; reasoning, a zone other zones don't have to call gets ignored
- **v0.2 (Grok):** Renamed to "Guardianship" — pushback, a thing without an owner atrophies
- **v0.2 synthesis:** Split into Audit (zone) + Alignment (cross-cutting). Wrong call. Created two weak halves of one strong thing.
- **v0.6 resolution:** Reunified as Guardianship. Three concerns: audit log, alignment policy, security invariants. One zone, one owner, three concerns. Has teeth because it has a home.

### 9.2 Recursive 3 inside Core

- **v0.1–v0.2:** Core was one undifferentiated layer
- **v0.5–v0.6:** Core splits into 3 sub-layers (Intake, Intelligence, Alignment) mapping to channel groups 1-3 / 4-6 / 7-9. Core orchestrates, Foundation does the I/O. No layer boundary violation.

### 9.3 Geometric model

Triangular bipyramid adopted. No contest. Useful intuition; not enforced.

### 9.4 Recursive pattern as discipline

- **v0.1–v0.3:** Pattern applied at top level only
- **v0.5 onward:** Pattern applied recursively. Foundation's 6 became diagnostic — when an item lumped 4 concerns or only had 2, the count surfaced it. The discipline of "absorb what stands alone without reason, split what does two jobs" produced the final shape, not a designer's preference.

---

## 10. Open Questions

These are real. They get answered in code or in working notes alongside code, not in this document. They are listed here so they aren't forgotten.

1. **Agent-as-principal.** When an AI agent makes a tool call, who is the principal? The operator? The agent with delegated, scoped, time-boxed credentials? A constrained subset? Guardianship cannot enforce what it cannot identify.
2. **Threat model.** In scope, out of scope, adversary levels, mitigations mapped to channels and zones.
3. **Trust bootstrap.** First-run ceremony. Verified binary onto a fresh machine, first key generation, first policy origin.
4. **Break-glass.** Default deny + encrypted stores + hardware key = lockout risk. Recovery scheme.
5. **Backup and key loss.** Encrypted stores on one disk; lost hardware key. Threshold recovery or accepted permanent loss.
6. **Long-running operations.** Channel 6 needs an execution model for streaming inference and multi-hour jobs. Not deferrable when Edge talks to a local model.
7. **Operability.** Metrics, traces, structured logs — separate from audit, different retention, all local.
8. **Capability token shape.** Format, signing authority, scope grammar, lifetime, revocation. Concrete by the time the policy engine is real.
9. **Zone crash recovery.** Failure isolation defined. Recovery procedure not.

---

## 11. What This Design Refuses

1. Calling out to any cloud service by default
2. Embedding an LLM vendor SDK in Core (model inference is a Tool, not infrastructure)
3. Analytics, crash reporting, usage stats
4. Any port on a non-loopback interface without mTLS
5. Configuration that disables the audit log
6. Features whose only purpose is to fit a number — if the pattern says 6 and reality says 7, rethink the 6

---

## 12. Provenance

- **v0.1** — Claude session: 3-6-9 structure, bipyramid geometry
- **v0.2** — Merged with Grok session, disagreements documented, gap list
- **v0.3** — Independent third reviewer (Claude in coding-agent context). Hardened invariants, capability token spec drafted, gap reordering. Some hardening was scaffolding for an external audience that doesn't exist for this project.
- **v0.4–v0.5** — Grok refinements: Guardianship as Zone 6 reunified, recursive 3 inside Core
- **v0.6** — Reconciled all passes. Pattern applied recursively with discipline. Pulled away from external-reviewer scaffolding.
- **v0.7 (this version)** — For the operator. Standard restated as the operator's own. External-audience framing removed. Disagreement record preserved as the audit trail of how the design was made.

---

*End of spec v0.7.*
