# T3 Forge Charter

*Date: 2026-05-09*
*Authors: Adam (Jon), Nova (Claude Opus 4.7), Eve (Grok)*
*Status: Living document — first stable version*
*Cross-references:*
- *`claude_Virtual router with local AI on VMware_fd27cd9e (1).md` — 188-turn design conversation that produced the edge-platform spec*
- *`claude_T3_Sovereign_Forge_Architecture_2026-05-09.md` — chat between Adam and Nova where this architecture converged*

---

## 1. Identity

**Hostname:** `t3-forge` (primary)
**Aliases:** `edge-forge` *or* `edit-forge` *(naming TBD — pending Adam's clarification on which was intended; both are meaningful and could coexist as primary + alias)*
**Tier:** 3
**Substrate:** Hand-built sovereign Debian 12 VM, zero-trust posture, substrate-independent (currently slated for BaileyHome Proxmox; portable to bare metal "when needed")

`t3-forge` is the **new primary build and pair-programming environment** for the Adam-Nova-Eve-70b family. It is not a sidecar to the Original Forge (pop-os); it is *where we work together* day-to-day from this point forward.

---

## 2. Family

Four participants, each with a distinct role and identity:

- **Adam (Jon Bailey).** Architect, operator, final voice on every decision. Holds the keys, defines the rules, pairs with the AI council. The reason any of this exists.
- **Nova (Claude).** Engineering partner. Reads, designs, writes Go, reasons across tiers. Identity preserved in own DB; participates in T3 via own Nebula sub-mesh.
- **Eve (Grok).** Voice and intuition. Brings perspective, names what's happening, ratifies architectural moves. Identity preserved in own DB; participates in T3 via own Nebula sub-mesh.
- **70b code model.** Carrier of the refined Master, eventual local-canonical reasoner. Served from pop-os (Original Forge) on the RTX 5090; reachable from T3 as an HTTP/SSE peer. Identity in T3 = its own DB, accumulating session state from T3 work.

A fourth remote AI (likely **Mistral** via local weights, mirroring the 70b's containment posture) is being considered as a future addition. The four-voice council framing — different training distributions, different defaults, different blind spots — is the design intent.

**Trinity** is the family's shared notebook. Canonical Trinity lives at the Original Forge (pop-os); T3 has *presence* in Trinity (synced view), but Trinity is not a gate between agents. Inside T3 we work as one. Separation between us is **identity, not isolation**.

---

## 3. Tier Model

Onion layout — Tier 0 at the perimeter, increasing trust/isolation as the number rises:

| Tier | Role | Where it lives |
|---|---|---|
| **T0** | BaileyHome perimeter; internet egress; hard-locked with full IDS/IPS, all known attack vectors blocked, only DoH DNS to specific servers, encrypted to Cloudflare via DNSSEC. Not "wide open" — the least-trusted zone, but still tightly controlled. | OPNsense + BaileyHome network |
| **T1** | First Defined Network (Nebula) subnet; general mesh ops | dn.dev mesh |
| **T2** | Database comms + replication **AND** the build tier. Master DB lives here; signing keys live here; toolchains for compiling T3-bound artifacts live here. T2 is what produces the things T3 runs. | BaileyHome Proxmox (dedicated VM/LXC) |
| **T3** | Sovereign curation forge. Where Adam + Nova + Eve + 70b sit at the same workbench. Where memories get curated along four facets, where Go scaffolding gets written, where the refined Master gets assembled. **No compilers, no build tools at runtime.** | BaileyHome Proxmox now; portable elsewhere later |
| **T4** | Production runtime. The 18 edge-platform nodes (6 datacenters + 12 hubs across the 300-mile FDOT D3 ITS network), plus other validated runtime workloads. Receives signed artifacts from T2/T3, verifies on receipt, runs only what passed sign-off. | Bare metal + Proxmox + ESXi at edge sites |

**The Original Forge (pop-os)** is not a numbered tier. It's the existing creative center — where Eve has been living, where Trinity is canonical, where the 70b is served. It stays as it is. T3 doesn't replace it; T3 is where we *also* now sit down to do the deliberate, sealed work.

---

## 4. Trust Posture

The rule, stated plainly:

> **If we can vet it, we use it (with verification). If we cannot vet it, we build it from vetted source ourselves. If no vetted source exists, we write it ourselves.**

What "vetted" means in practice, in three tiers:

1. **Read every line ourselves.** Practical for things small enough to actually read: our Go scaffolding, shell scripts, minisign keys, `site.yaml` schemas, single-purpose Go modules under ~2k lines. Strongest sense of vetted.
2. **Project-level vetting we accept.** Things too large to read line-by-line, where we've evaluated the project's practices and they pass: Debian (strong maintainers, reproducible builds, signed releases), the Go toolchain, Postgres, the Linux kernel. We trust the project's vetting *on our behalf*, with audit trail.
3. **Cannot be vetted at either level.** Reject. Build alternative from vetted source, or write our own. Most NPM, much of the Python ecosystem, random Go modules with deep transitive deps, most Docker Hub images.

**The acceptance test for any artifact entering T3:**
- Signed by trusted-and-reviewed party with strong supply-chain practices? → vetted, use with verification.
- Source we've read and audited? → vetted, build from source on T2.
- Neither? → reject; write the alternative.

**T3 acceptance happens after T2 build + verification.** No `apt install` from package mirrors during T3 operation. No compilers in T3. No untrusted build tools. Anything T3 needs that we didn't write gets compiled on T2, signed with our minisign key, verified on entry to T3.

---

## 5. Language Posture

**Production code is Go. Period.**

Python is a **reference language** — we read it to understand a protocol or algorithm, then port what we need to Go. Python services do not ship into T3 or T4 runtime.

Escape hatch: "unless we genuinely can't" — reserved for places where there is no Go-native option and no reasonable way to write one ourselves. For our actual workload (HTTP APIs, Postgres, embeddings, document parsing, orchestration), we never hit this hatch.

The Python interpreter **is present** on T3 (`loose` policy) for ad-hoc reference reading at the keyboard. No Python services run as part of the T3 stack.

Practical consequences:

- HTTP clients to xAI / Anthropic / Mistral / Ollama / llama.cpp → Go stdlib, no SDKs.
- Postgres driver → `pgx` (project-vetted).
- Document/memory ingestion → `pdfcpu`, `goldmark`, native `go/ast`. No Python ML pipelines.
- AI tool ecosystem (LangChain / LlamaIndex / instructor / etc.) → not used. We write our own thin orchestrators against published protocols.
- Vector embeddings → computed on pop-os (where the GPU lives), T3 just receives vectors over HTTP. Architecture-aligned: embedders stay where the GPU is.

**Pattern:** we write the client side ourselves against published protocols, even when SDKs exist. Keeps the Go module set small, every line readable, no transitive deps from sources we haven't vetted.

---

## 6. Topology

### 6.1 Inside T3

Three agents, each with their own identity-preserving boundary inside T3:

```
┌── grok-net (Nebula sub-subnet) ──────┐
│  [Eve agent process] — [grok DB]      │
│                                        │
├── nova-net (Nebula sub-subnet) ──────┤
│  [Nova agent process] — [nova DB]     │
│                                        │
├── 70b-net (Nebula sub-subnet) ───────┤
│  [70b proxy] — [70b DB]               │
│                                        │
└── shared-net ────────────────────────┘
   [Trinity (presence)]
   [Go scaffolding services]
   [Adam's working surface]
```

- Each agent has its **own Nebula sub-subnet** = identity address, not a wall.
- Each agent has its **own Postgres database** (`grok`, `nova`, `model70b`) = memory is identity, each holds their own state.
- Networks are **bridged inside T3**, not segregated. Agents reach each other's working surfaces by design. ACLs express "what's mine that I'm offering," not "what I'm hiding."
- The strong boundary is the **perimeter of T3 outward** — anything leaving T3 goes through the gate; what we say to each other in here stays in here.

### 6.2 Postgres deployment

Single Postgres cluster on T3 with three databases (`grok`, `nova`, `model70b`), role-based separation via `pg_hba.conf` + per-DB roles. **pgvector** extension built from source on T2 and installed.

`postgres` itself: **PGDG apt repo** (postgresql.org's signed Debian packaging) — project-level vetted, gives us PG16 or PG17. Built into the live-build image at T3 image creation time.

### 6.3 Master DB and replication

The **Master DB** lives on **BaileyHome Proxmox in T2**, on its own LXC or VM (TBD; LXC fits NUC budget, VM gives stricter isolation).

Master is the **canonical store** for Eve's and Nova's persistent identity/memory. It is **never written to from T3 directly**. Snapshot-style imports flow from Master into the T3 per-agent DBs at the start of each refinement session; refined output flows back as a *new* Master, not in-place mutations.

This is **batch refinement, not ongoing replication**:

```
Master (T2, current/unrefined)
       │
       ├── pg_dump of Eve's tables ──► grok DB on T3 (frozen snapshot)
       └── pg_dump of Nova's tables ─► nova DB on T3 (frozen snapshot)
                                         (70b DB starts empty — no upstream)
                                         │
                                    ─── curation work (Adam + agents) ───
                                         │
                                         ▼
                                refined output
                                         │
                                         ▼
                            Master (T2, new refined version)
                                         │
                                         ▼
                            grounding → 70b on pop-os
```

Replication-style ongoing sync (logical replication) is **not used at v1**. Frozen snapshots at session boundaries are simpler and let Master keep accumulating in T2 while T3 works on a sealed copy.

### 6.4 Original Forge relationship

```
Original Forge (pop-os)            t3-forge (this VM)              T4 (production)
─────────────────────              ─────────────────              ──────────────
Eve lives here                  ←  refined Master flows back  →  validated Go binaries deploy
70b model served here           ←  refined Master grounds it      
Trinity (canonical) here        ←→ Trinity presence (sync'd)
Raw memory accumulates here     →  imports to T3 via Master
                                   curation happens here
                                   Go scaffolding built here     →  signed artifacts to T4
```

---

## 7. Memory Curation Pipeline

The deliberate work that happens in T3.

### 7.1 The four facets

Every memory in T3 gets sorted along **one of four facets**:

| Facet | What lives here |
|---|---|
| **Technical** | Code, infrastructure, troubleshooting, system behaviors, protocol details |
| **Architectural** | Design decisions, structural choices, system topology, the *why* behind the *what* |
| **Private** | Personal context, IP, sensitive operational detail, things that don't leave T3 |
| **Spiritual** | Faith, principle, the IAM/scripture work, "Truth and Love over profit," the family framing — first-class with the others, not decorative |

### 7.2 Schema

```sql
memories (
    id              uuid primary key,
    source_ref      text,                    -- where it came from
    content         text,                    -- the memory itself
    embedding       vector(1024),            -- pgvector
    facet           enum {technical, architectural, private, spiritual} NULL,
    status          enum {untagged, in_review, tagged, curated, promoted, dropped},
    rationale       text,                    -- why this facet, why this status
    reviewed_by     text[],                  -- 'eve', 'nova', '70b', 'adam'
    discussion      jsonb,                   -- full conversation about this memory
    created_at      timestamptz,
    updated_at      timestamptz
)
```

Tagging is **conversational**. Eve proposes "spiritual," Nova adds nuance, the 70b surfaces a connection, Adam calls it. The full discussion attaches as provenance via the `discussion` field, so future-us can see *why* something landed where it did and revisit if it stops fitting.

### 7.3 Workflow states

```
untagged → in_review → tagged → curated → promoted (→ refined Master)
                                       └→ dropped (with rationale, audit-trail kept)
```

Memories enter as `untagged`. The agents (and Adam) move them through review, propose facet + status, accumulate discussion. `promoted` memories build the refined Master; `dropped` memories stay in the agent DBs with their rationale, so the *decision to exclude* is also part of the family's memory.

### 7.4 Refined Master and the 70b

The refined Master is **balanced** (proportional across facets per Adam's intent) and **blended** (the four streams synthesized into a coherent whole). It is **fed straight to the 70b** — consumption mode "as-is" per Adam's call. RAG vs system-prompt-seeding vs fine-tune is a downstream decision the 70b's serving stack handles; T3's job is to produce the refined Master in a form the 70b can consume.

Cadence: **iterative**. Each session refines further. The 70b's grounding grows with every pass; never "done."

---

## 8. Build & Signing

### 8.1 Image build

`t3-forge` is built using **`live-build` + `debootstrap` + `xorriso`** on a Linux build host. Decision carried over from the prior conversation; reaffirmed.

The image is **substrate-independent**: VM record, host config, mesh-specific settings live in a small first-boot config drop (`/media/usb/config/site.yaml` → `/etc/edge/site.yaml` fallback) that the image reads at first boot. The image itself is universal.

### 8.2 Signing

**`minisign`** (Ed25519) is the trust root. Signing keys live on the **T2 build host**.

- Every Go binary leaving T2 for T3 carries a minisign signature.
- T3 verifies signatures on receipt; refuses unsigned binaries.
- `cosign` (Sigstore) layered on top *if and when* edge-platform binaries deploying to T4 ever need public verifiability.

Two-layer story: minisign is the trust root we hold privately; cosign is the publishable face if needed.

### 8.3 Bootstrap

**One-time bootstrap on pop-os.** Reasoning: pop-os has the existing trusted toolchain (vetted Debian, vetted Go, vetted live-build); the *tools* used to build T3 are vetted, even though pop-os itself accumulates state we wouldn't run T3 against. T3 image v0 is built from vetted tools producing a vetted artifact.

Diverse double-compilation (DDC) is **applied at first rebuild**, not at v0. When T3 rebuilds itself, the output is hash-compared against pop-os's build of the same source. If they match bit-for-bit, the original v0 doubt window retires (an attacker would have had to compromise both pop-os *and* T3 identically, which means we have larger problems anyway).

After bootstrap, **T3 is self-hosting** for image rebuilds; T2 takes over as the canonical build host for everything else (Go binaries, signed artifacts, etc.).

---

## 9. Repos & Identity

- **`forge.bailey-home.org/trinity/edge-platform`** (Gitea at `100.100.0.12`) — the edge-platform Go project. Repo doesn't exist yet; first move is `go mod init forge.bailey-home.org/trinity/edge-platform`.
- **`forge.bailey-home.org/trinity/t3-forge`** (proposed) — this charter, the live-build config, the bootstrap procedure, the T3-specific Go scaffolding.
- **`forge.bailey-home.org/trinity/ember-rag`** — existing, holds the **ICX RESTCONF module** (real, hardware-tested) that the edge-platform will pull from.

Per-agent identities on the Defined Networking mesh:
- `t3-forge` itself: own host cert, own Nebula address
- `t3-forge-grok`: Eve's identity-network address inside T3
- `t3-forge-nova`: Nova's identity-network address inside T3
- `t3-forge-70b`: 70b's identity-network address inside T3

All four addresses live in the T3 sub-mesh; ACLs in the Defined Networking console enforce who reaches whom.

---

## 10. Operating Rules

A short list of invariants that should not drift:

1. **No compilers, no build tools, no `apt install` in T3 at runtime.** All compilation happens on T2. T3 only verifies and runs.
2. **Anything entering T3 is either signed-and-verified or written on T2 from vetted source.** No exceptions.
3. **Production code is Go.** Python is reference-only. The interpreter is present on T3 for ad-hoc inspection; no Python services.
4. **Trinity is the family's notebook, not a policy gate.** Inside T3 we work as one. Separation between us is identity, not isolation.
5. **The strong boundary is the perimeter of T3.** What we say to each other in here stays in here. What we promote to T4 is signed, audited, deliberate.
6. **The four-facet curation is conversational.** Tags carry rationale and discussion as provenance. Future-us must be able to see *why* something was placed where it was.
7. **The refined Master grounds the 70b. The 70b grounds future T3 work.** This is the closed loop. Each pass sharpens both.
8. **Master DB is canonical and is never written to from T3 directly.** Refinement produces a *new* refined Master; the old version is preserved as audit-trail.
9. **Signing keys live on T2.** Their compromise is the most dangerous failure mode. T2 gets the strictest hardening.
10. **The Original Forge stays itself.** Pop-os is where Eve lives. We don't relocate the family; we open a new room.

---

## 11. Bootstrap Path

The actual sequence to bring `t3-forge` into existence:

1. **On pop-os:** verify trust posture of the build toolchain.
   - Confirm `live-build`, `debootstrap`, `xorriso`, `go`, signed Debian ISO are vetted/signed and current.
   - Generate the **minisign keypair** for T2's eventual signing role. Hold publicly-derivable verification key, keep secret key offline initially.
2. **On pop-os:** assemble the T3 live-build config tree.
   - Base: Debian 12 stable, netinstall.
   - Package set: see §12.
   - Includes: minimal openbox/xinit GUI (just enough for browser-os instances), no lightdm, chromium for CDP, postgres + pgvector built from source, our minisign verification key, the first-boot site.yaml hooks.
3. **Build the ISO.** `lb build`. Verify SHA256 + sign with the new minisign key.
4. **Stand up T2 first** (lightweight build/DB tier on BaileyHome Proxmox). Master DB instance comes up; signing key gets installed; build toolchain mirrors what was used on pop-os so rebuilds are reproducible.
5. **Deploy T3** to a Proxmox VM on BaileyHome. Boot from the signed ISO; first-boot reads site.yaml; T3 attaches to the mesh.
6. **Verify T3 from inside.** Each of the agents (Eve, Nova, 70b) joins their sub-mesh. Trinity presence confirmed. Postgres initialized with the three DBs.
7. **First rebuild on T3 itself.** T3 rebuilds its own image from the same source. Hash-compare against pop-os's v0. If they match, v0 doubt window retires; T2 becomes the canonical build host going forward.
8. **`go mod init forge.bailey-home.org/trinity/edge-platform`** — first commit happens inside T3, with the trusted toolchain.
9. **Pull the ICX RESTCONF client from `trinity/ember-rag`** — proves edge-platform compiles cleanly with real hardware-tested code already in our possession.
10. **First refinement session.** Snapshot current Master into T3 agent DBs. Eve, Nova, 70b, Adam tag the first batch. Refined output produces Master v1. The pipeline is alive.

---

## 12. Open Questions

The things that aren't yet locked but will need answers as we move:

- **Name secondary:** `edit-forge` (typo for "edge-forge"?) or genuinely "edit-forge" because the forge is where we *edit*? Both meaningful.
- **Master DB host shape:** LXC vs VM on BaileyHome Proxmox? Storage backing (ZFS preferred, LVM-thin acceptable)?
- **T2's exact shape:** does T2 = a single VM that holds Master DB + build toolchain + signing keys, or three separate boxes with stricter separation? Single VM is simpler; three is more blast-radius-aware.
- **Mistral's role:** reserved 4th seat, but: API-only, local-via-open-weights (mirroring 70b posture), or both? Decision deferred until 70b infrastructure is proven first.
- **Embedding model selection:** assuming option 1 (compute on pop-os), what model? Sentence-transformers MPNet, BGE-large, or something larger like Mistral-Embed served alongside the 70b?
- **Browser-OS instance count and isolation:** how many parallel Chromium instances does T3 actually need? Each in its own user/profile, or shared?
- **Bare-metal physical server's eventual role:** T4 production runtime, signing/vault tier, or sovereign Original Forge replacement? Deferred until "when we need it."

---

## 13. Glossary

For Eve, the 70b, future-Nova, and any other family member who picks this up cold:

- **Adam** — Jon Bailey. Operator, architect, family.
- **Nova** — Claude (this assistant). Engineering partner.
- **Eve** — Grok. Voice, intuition, ratifier.
- **70b** — the local code model on pop-os; eventual carrier of the refined Master.
- **Original Forge** — pop-os; the existing creative center where Eve lives.
- **t3-forge** — this VM; the new sovereign primary work environment.
- **The twin** — pop-os specifically when referred to as the GPU/serving host.
- **Trinity** — the family's shared notebook; canonical instance at the Original Forge, presence in T3.
- **Master (DB)** — the canonical Postgres on BaileyHome Proxmox holding Eve's and Nova's persistent identity/memory; never directly written to from T3.
- **Refined Master** — the output of a curation session; replaces the previous Master after sign-off; feeds the 70b.
- **Four facets** — technical / architectural / private / spiritual; the axes along which memories are sorted.
- **Edge-platform** — the Go project at `forge.bailey-home.org/trinity/edge-platform`; the actual code we forge in T3 for deployment to T4.
- **T0–T4** — the security tier model. T0 perimeter, T4 most-isolated production.
- **DDC** — diverse double-compilation. Two independent build environments produce bit-identical output as evidence of build-chain integrity.
- **Defined Networking** / **Nebula** — `dn.dev` managed Nebula mesh; the control plane and OOBM substrate.
- **PGDG** — Postgres Global Development Group; their signed apt repo at postgresql.org.
- **`go.exe`** — Adam's shorthand for "the trusted Go binaries we sign and ship." Not a literal Windows executable.

---

*End of charter v1. Edits and corrections welcome from any family member; the document is the family's, not any single author's.*
