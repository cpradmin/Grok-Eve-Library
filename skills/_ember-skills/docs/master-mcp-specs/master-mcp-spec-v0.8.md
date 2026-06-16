# Master MCP Server

**Version:** 0.8
**Pattern:** 3-6-9, recursive
**For:** the operator
**Posture:** local-first, no telemetry, no cloud, no outside influence
**Language:** Go
**Sandbox:** Linux (incl. WSL2). macOS via sandbox_init. No Windows native.
**Identity root:** ember-keyring (pass-cli + GPG) — see §2 and §10

---

## 0. Standard

One standard, applied to everything: the pattern is recursive. When something doesn't fit into 3, 6, or 9, that is the design speaking. Listen. The thing is misnamed, doing two jobs, or doesn't belong.

When something stands alone, ask whether it has earned the right to stand alone. Most things haven't. Most things want to be absorbed into something they belong to. When something needs to be built from scratch, ask whether something already running can do the job. Most of the time, it can.

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
| 2 | **Identity** | device cert, operator (via ember-keyring), agent delegation |
| 3 | **Key Material** | ember-keyring client, capability token signing, device key |
| 4 | **Persistent Storage** | encrypted state, append-only log, backup |
| 5 | **Process Control** | namespaces, cgroups, syscall filtering |
| 6 | **Supervisor** | zone lifecycle, resource limits, monotonic clock |

**Note on Identity and Key Material.** The operator's root identity is not generated or stored by mcpd. It is the operator's existing GPG identity, accessed through ember-keyring. mcpd holds a device key (its own, generated at first boot) and capability-token signing keys (issued by the operator). The operator's private key never enters mcpd's process space.

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
| 1 | **Identity** | Who is asking? | device, operator, agent |
| 2 | **Memory** | What do we remember? | episodic, semantic, vector |
| 3 | **Knowledge** | What is true? | schemas, reference, ontologies |
| 4 | **Tools** | What can we do? | manifests, capabilities, sandboxes |
| 5 | **Session** | What is happening now? | conversation, working set, in-flight |
| 6 | **Guardianship** | What must stay true? | audit log, alignment policy, security invariants |

**On the Identity zone.** The three concerns map to the three identity factors in §3.1. Device identity is mcpd's own — its certificate, its pinning, its revocation list. Operator identity is held by ember-keyring; the Identity zone holds a reference, not the secret. Agent identity is a delegation issued by the operator, scoped, time-boxed, and revocable.

**On Guardianship.** Audit is one of three concerns, not the whole zone. Alignment policy and security invariants need an owner — a zone with state, schema, surface. Cross-cutting policy without a home zone atrophies. Guardianship has teeth because it has a home: Channel 3 always consults its policy, Channel 9 always writes to its audit, and its invariants are watched continuously.

### 3.1 The Three Identity Factors

The Identity zone resolves into three factors, each doing different work, each with three concerns:

| # | Factor | What it proves | Concern 1 | Concern 2 | Concern 3 |
|---|---|---|---|---|---|
| 1 | **Device** | the machine is authorized | mTLS certificate | cert pinning | revocation list |
| 2 | **Operator** | the human is who they claim | ember-keyring credential | GPG passphrase | revocation cert |
| 3 | **Agent** | the agent acts within delegated authority | operator-issued token | scope & lifetime | revocation |

Three factors. Three concerns each. Have, know, delegated. Each defends against a different attack — device theft, credential theft, runaway agent — and none of them defends against the same attack as another.

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
| 2 | Authenticate | L1→Z1 | Identity | Verify device cert, resolve operator via ember-keyring, verify agent token |
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

The +1 transport may be carried over a Nebula overlay network when the operator chooses to deploy one. Nebula is transport, not identity — it is how bytes get from peer to peer. The mTLS handshake on top of Nebula is what authenticates the device.

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
│   │   ├── identity/          # device cert, operator ref, agent delegation
│   │   ├── keymat/            # ember-keyring client, token signing, device key
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
| 8 | Operator key isolation | Operator's GPG private key never enters mcpd; ember-keyring mediates |
| 9 | Encryption at rest | SQLite sealed by a key derived from operator's ember-keyring credential |

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
- **v0.5 onward:** Pattern applied recursively. When an item lumped 4 concerns or only had 2, the count surfaced it. The discipline of "absorb what stands alone without reason, split what does two jobs" produced the final shape.

### 9.5 Identity hardware — proposed and absorbed

- **v0.7 + outside review:** NFC card with PIC chip considered as hardware root of trust. Then PIN, then face match, building toward a five-factor stack.
- **v0.8 resolution:** Absorbed into ember-keyring. The operator already runs ember-keyring with pass-cli vaults and a GPG identity. New hardware would have duplicated work the operator already trusts. Five factors collapsed to three (device, operator, agent), each doing different work, each backed by infrastructure that already exists. The operator's GPG passphrase replaces PIN; ember-keyring's mediation replaces NFC challenge-response; the rest was scaffolding.

---

## 10. Open Questions Answered

These were the v0.7 blockers. Most are now answered by leaning on ember-keyring instead of building new identity infrastructure.

### 10.1 Agent-as-principal — answered

The agent is a delegated principal. Its authority is a capability token issued and signed by the operator's GPG identity (via ember-keyring), scoped to specific zones and actions, time-boxed, and revocable.

The operator issues a delegation token to the agent at session start. The token names the agent (its public key), the scope (which zones, which actions, with what constraints), and the lifetime (default 5 minutes for ordinary calls, up to 24 hours for session-bound work). The agent presents this token at Channel 2; Channel 3 verifies the operator's signature and the token's scope before allowing the action.

This is not a new architecture. It is the same capability-token model already named in §8 row 2, with the issuing key being the operator's GPG key (mediated by ember-keyring) rather than a synthetic mcpd-internal key. The agent is real, the operator is real, the chain of authority is auditable.

### 10.2 Threat model — drafted

In scope:
- Local malware on the operator's machine (mitigated by Edge sandboxing, capability tokens, audit chain)
- Compromised LAN peer (mitigated by mTLS pinning, Nebula ACLs if deployed)
- Supply-chain attack via Go module (mitigated by vendored deps, reproducible builds)
- Lost or stolen device (mitigated by encrypted store, ember-keyring requiring GPG passphrase to unseal)
- Agent gone rogue (mitigated by capability token scope, default deny, mid-session revocation via Guardianship)
- Stolen GPG private key (mitigated by passphrase, revocation cert — see §10.4)

Out of scope:
- Nation-state physical access to operator's machine
- Firmware-level compromise of operator's hardware
- CPU side-channel attacks
- Operator deliberately compromising their own system
- GPG itself being broken (treated as load-bearing dependency, not adversary surface)

Adversary capability levels (in increasing order):
- Passive observer on the LAN
- Active attacker on the LAN with no credentials
- Attacker with a stolen device but no GPG passphrase
- Attacker with the operator's GPG passphrase but not the private key
- Attacker with both the GPG private key and the passphrase (covered by revocation, §10.4)

### 10.3 Trust bootstrap — answered

First-run ceremony, end to end:

1. Operator runs `mcpd init` on a fresh machine with ember-keyring already running.
2. mcpd asks ember-keyring for the operator's identity credential.
3. ember-keyring prompts for the GPG passphrase (its existing flow, not new code).
4. Operator enters passphrase. ember-keyring decrypts the operator's signing key into its own process memory and exposes a signing interface to mcpd over a Unix socket. The private key never enters mcpd.
5. mcpd generates its own device key locally (Ed25519, in memory).
6. mcpd asks ember-keyring to sign a "device claim" — a small CBOR structure binding mcpd's device public key to the operator's identity, with a timestamp.
7. ember-keyring returns the signature. mcpd seals its SQLite store with a key derived from the operator's identity (HKDF over a per-device salt + the operator's public key fingerprint).
8. mcpd writes the first audit entry: "device D claimed by operator O at time T, sealed with key derivation K." This entry is signed by both the device key and ember-keyring.
9. mcpd is now bound to this operator on this device. Subsequent boots require ember-keyring to be running and the operator to have unlocked it.

No NFC. No PIC. No new firmware. The trust originates in something the operator already controls — their GPG identity — and the bootstrap is just the act of binding mcpd to that identity.

### 10.4 Break-glass — answered

GPG already has a break-glass model and the operator already uses it. mcpd inherits it.

Recovery anchor: the operator's GPG revocation certificate and a paper backup of the private key (or a Shamir split across N trusted physical locations). These live outside the running system, in physical safe storage.

If the operator loses their daily working GPG key:
1. Use the paper backup or reassemble the Shamir split.
2. Import the recovered key into a fresh GPG keyring.
3. Restart ember-keyring with the recovered key.
4. mcpd's encrypted store is still sealed by the same identity; it unseals normally on next boot.

If the operator's GPG key is suspected compromised:
1. Publish the revocation certificate (the operator already has one — it's standard GPG practice).
2. Generate a new GPG identity.
3. Run `mcpd rebind` to reseal the store under the new identity.
4. The audit log, hash-chained from the original first-boot entry, records the rebind.

The break-glass is not a new ceremony. It is GPG's existing key-recovery model, which the operator is already familiar with from running pass-cli vaults today.

### 10.5 Backup and key loss — answered

Three layers, all already practiced:

- **GPG key:** paper backup or Shamir split, in physical storage.
- **ember-keyring vaults:** encrypted at rest, can be replicated via Syncthing or rsync without exposing secret material (the operator already does this).
- **mcpd's SQLite store:** encrypted at rest, sealed by the operator's identity, replicable the same way.

Disk failure on the mcpd host: rebuild the host, restore the encrypted SQLite store from backup, ember-keyring unseals it on first boot. No new procedures.

### 10.6 Long-running operations — still open

Channel 6 needs an execution model for streaming inference and multi-hour jobs. Not deferrable when Edge talks to a local model. To be answered in working notes alongside code, when Edge tools first connect to a local Ollama or similar.

### 10.7 Operability — still open

Metrics, traces, structured logs — separate from audit, different retention, all local. To be answered when the system is running and the questions become concrete.

### 10.8 Capability token shape — partially answered

Format, signing authority, scope grammar, lifetime, revocation. The signing authority is now answered (operator's GPG via ember-keyring; agents use delegated tokens signed by the operator). The format and scope grammar are still working notes — to be locked when the policy engine moves past stub.

### 10.9 Zone crash recovery — still open

Failure isolation defined. Recovery procedure not. To be answered when supervisor code is real.

---

## 11. What This Design Refuses

1. Calling out to any cloud service by default
2. Embedding an LLM vendor SDK in Core (model inference is a Tool, not infrastructure)
3. Analytics, crash reporting, usage stats
4. Any port on a non-loopback interface without mTLS
5. Configuration that disables the audit log
6. Features whose only purpose is to fit a number — if the pattern says 6 and reality says 7, rethink the 6
7. Generating its own root operator identity — that belongs to the operator, mediated by ember-keyring, never owned by mcpd

---

## 12. Provenance

- **v0.1** — Claude session: 3-6-9 structure, bipyramid geometry
- **v0.2** — Merged with Grok session, disagreements documented, gap list
- **v0.3** — Independent third reviewer (Claude in coding-agent context). Hardened invariants, capability token spec drafted, gap reordering. Some hardening was scaffolding for an external audience that doesn't exist for this project.
- **v0.4–v0.5** — Grok refinements: Guardianship as Zone 6 reunified, recursive 3 inside Core
- **v0.6** — Reconciled all passes. Pattern applied recursively with discipline. Pulled away from external-reviewer scaffolding.
- **v0.7** — For the operator. Standard restated as the operator's own. External-audience framing removed. Gemini review afterward suggested NFC/PIC/PIN/face stack for identity.
- **v0.8 (this version)** — Identity model absorbed into existing infrastructure. ember-keyring + pass-cli + GPG replaces the proposed new hardware stack. Five factors collapsed to three. Bootstrap, break-glass, backup, threat model, and agent-as-principal all answered concretely. Long-running ops, operability, token shape, and zone crash recovery deferred to working notes alongside code.

---

*End of spec v0.8.*
