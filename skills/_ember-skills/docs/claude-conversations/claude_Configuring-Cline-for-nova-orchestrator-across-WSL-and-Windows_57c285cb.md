# Configuring Cline for nova-orchestrator across WSL and Windows
*Created: 5/4/2026, 7:05:14 PM*
*Exported: 5/15/2026, 1:58:41 PM*

---

## 1. User

Got it — and I had the URL wrong earlier (misread the screenshot). Correct endpoint is `http://100.100.0.1:11500/v1` — which lines up with the nginx listen on `100.100.0.1:11500` we saw in `ss -ltnp` while debugging the Ollama-:11434 thing. Same auth pattern (token via `svc:pop-os:nova-orchestrator-token`), different port, different upstream — orchestrator with L1/L2/L3 routing.
Three notes I'm holding for the Windows-native mirror:

1. One token fetch, two surfaces — same bearer plugs into both WSL Remote Cline and Windows-native Cline. After you paste it on the WSL side, just copy from clipboard or re-paste from the same fetch into Windows-native. No second pass-cli call needed.
2. Reachability already verified for Windows — earlier in this session I confirmed `100.100.0.1:11434` was reachable from this box on Nebula (`100.100.0.2`). Port 11500 will be too.
3. The `svc:pop-os:ssh-private-key` quirk from memory — `reference_popos_ssh_access.md` notes pop-os SSH user is `kntrnjmb` from this Windows side. The WSL session's `ssh pop-os "sudo -n -u kntrnjb …"` runs as `kntrnjb` on pop-os (different user, different home, where pass-cli + the vault keyring live). That's correct — it's the local user on pop-os, not the SSH login user. Just flagging so I don't trip on it.
Standing by. When you've pasted on the WSL side, ping me and I'll:

* Walk the Cline UI on Windows-native via windows-mcp (Snapshot → Click into the gear → fill the OpenAI Compatible fields → paste token from clipboard) — or you can paste yourself and I just verify the round-trip
* Smoke-test from Windows-native: send a hello, confirm it routes to L1 and comes back clean
* Update memory: `project_admin_hub.md` gets a "Cline wired to nova-orchestrator on both surfaces" line, and a fresh `reference_nova_orchestrator.md` with the URL + layer model IDs + token slug
If anything fails over there, paste the error and I'll triage.

---

## 2. AI

Standing by, ack on all three.

One small correction on note 3 — you wrote `kntrnjmb` once and `kntrnjb` twice in the same note. Assuming `kntrnjb` is the right one (the pop-os local user where pass-cli + the vault keyring live), since that's what the `sudo -n -u` invocation actually uses. Worth fixing in `reference_popos_ssh_access.md` if the typo is there too — easy one to chase later.

Ready when you are. Ping me after the WSL paste and I'll drive the Windows-native side.

---

## 3. User

what am I supposed to do?

---

## 4. AI

You're being asked to do one thing: **paste the bearer token into Cline on the WSL Remote side first.**

The flow your earlier message laid out:

1. Fetch the token once (via `pass-cli` against `svc:pop-os:nova-orchestrator-token` — same pattern you used for the Ollama setup, just a different slug).
2. Paste it into Cline's OpenAI Compatible config on the WSL Remote side, with base URL `http://100.100.0.1:11500/v1`.
3. Ping me back.

Then I take over for the Windows-native mirror — same token from your clipboard, same URL, just into the Windows-native Cline instance — and run the smoke test.

If you've lost the thread on *how* to fetch the token or *where* in Cline to paste it, say the word and I'll walk you through that part too. Otherwise: token fetch → WSL Cline paste → ping me.
