# Nebula network best practices
*Created: 5/15/2026, 1:46:07 PM*
*Exported: 5/15/2026, 2:02:41 PM*

---

## 1. User

Defined Networks Nebula best practices research

---

## 2. AI

Here's a comprehensive best practices guide for Defined Networks Nebula, organized by category:

---

## Defined Networks Nebula — Best Practices

---

### 🔐 PKI & Certificate Authority (CA)

**Protect the CA private key above all else.**
The `ca.key` file is the most sensitive file you'll create, because it is the key used to sign the certificates for individual Nebula hosts. Store it somewhere safe, preferably with strong encryption. The CA private key should live only on the lighthouse or a secure offline machine. If you lose it, you cannot issue new certificates and will need to rebuild the entire PKI.

**Encrypt the CA key at rest.**
Nebula offers built-in encryption of the CA private key since v1.7.0. If you do not plan to store the private key in encrypted storage (e.g., Ansible Vault or AWS Secrets Manager), it is recommended that you use the built-in encryption. Pass the `-encrypt` flag when generating the CA and you will be prompted for a passphrase.

**Set explicit certificate durations and plan rotation early.**
By default, a CA is created with a one-year expiration, and all certificates signed will be valid until one second before expiration of the CA. Set up an alert or calendar event to rotate your CA and certificates before then to ensure continued connectivity. Pass `-duration XXhXXmXXs` to set a custom duration.

**Start CA rotation months in advance.**
Since you'll need access to the config file on every host in your network, it's a good idea to start rotating certificates early, possibly even months in advance, to avoid any connection issues. Consider setting a reminder in your team's shared calendar for 2–3 months prior to your new CA's expiration.

**Follow the proper rotation sequence.**
The correct CA rotation order is: (1) add the new CA certificate to the `pki.ca` bundle of all hosts, leaving the existing CA in place; (2) reload or restart Nebula; (3) sign host certificates with the new CA key, update `pki.cert` and `pki.key`, and reload/restart Nebula on each host; (4) remove the old CA from `pki.ca` and reload/restart Nebula on each host.

**Enable `pki.disconnect_invalid`.**
Consider enabling `pki.disconnect_invalid`. This flag will cause Nebula to close existing tunnels to hosts which are no longer trusted — either because their certificates are expired or are no longer signed by a trusted CA. This will accelerate how quickly you learn of problems after updating your CA trust bundle.

**Use config management for cert distribution.**
Ideally your hosts are managed using a config management tool like Ansible, Chef, or Puppet. If not, you'll need to manually connect to each device to update its Nebula config.

---

### 🗼 Lighthouses

**Lighthouses need stable, public IPs.**
Nebula lighthouses allow hosts to find each other, anywhere in the world. Lighthouses are the only hosts in a Nebula network whose IP addresses should not change.

**Run at least two lighthouses for resilience.**
Lighthouse nodes should be assigned a public global IP address — any kind of NAT or port forwarding is likely to render your lighthouses useless. A minimal $5/mo cloud machine is good enough to run as a lighthouse node, and no traffic passes through those nodes; they only broker the peer-to-peer connections of the other nodes in your mesh.

**Open UDP/4242 to the internet on lighthouse hosts only.**
Once you have launched a lighthouse instance, ensure that Nebula UDP traffic (default port `udp/4242`) can reach it over the internet. Regular nodes do not need inbound public ports — hole-punching handles the rest.

---

### 🔥 Firewall & Security Groups

**Use groups for fine-grained, zero-trust firewall rules.**
Nebula integrates a role-based firewall at every single node, where you can filter packets coming in and out of the node based on the group membership of the other node in the tunnel. Since the other node's identity and group membership is cryptographically verified, no central source of authentication truth is needed.

**Assign groups at certificate signing time.**
Nebula's real power is its certificate-based firewall. When you sign a certificate, you can embed groups. Firewall rules are then evaluated locally on each node using the groups embedded in the peer's certificate — no central policy server needed. Example:
```bash
nebula-cert sign -name "webserver" -ip "10.42.0.50/24" -groups "trusted,web"
nebula-cert sign -name "database"  -ip "10.42.0.60/24" -groups "trusted,db"
```

**Always allow ICMP for diagnostics.**
Regardless of what firewalls you create, it's generally recommended to allow ICMP traffic in order to test route configuration.

**Restrict key files to root only.**
It's a best practice to make sure that the key file is only readable by root.

**Default-deny inbound, permit only what's needed.** Set `outbound_action: drop` and `inbound_action: drop` as your defaults, then explicitly allow only required ports per group — keeping the blast radius of a compromised node minimal.

---

### 🔗 NAT Traversal & Connectivity (Punchy / Relay)

**Enable `punchy` on all nodes.**
Enable `punchy: punch: true` and `respond: true` in your config. This allows Nebula to punch through NAT for peers, greatly improving direct peer-to-peer connectivity without relying on relay paths.

**Use relays for difficult NAT/firewall situations.**
If a direct path goes down, Nebula reroutes instantly through relays to keep your network stable and responsive. Configure the `relay` section in `config.yaml` for hosts behind strict firewalls where UDP hole punching consistently fails.

**Assign one route per router host for `unsafe_routes`.**
It is generally good practice to assign a single route per router host when using `unsafe_routes` to extend access beyond overlay hosts.

---

### 🌐 IP Addressing & Subnet Design

**Choose a non-overlapping overlay subnet.**
Nebula overlay IPs are independent of your real network. Choose a private subnet that does not overlap with your existing infrastructure. Common choices: `10.42.0.0/24`, `192.168.100.0/24`.

**Use `preferred_ranges` to optimize latency.**
The `preferred_ranges` config key lets you tell Nebula to prefer certain underlay IP ranges (e.g., RFC-1918 private addresses) so that traffic between hosts on the same LAN takes the most direct path rather than going through the internet.

**Size your subnet for growth.** Use at least a `/20` or `/16` if you anticipate adding many hosts, since you cannot resize without rebuilding.

---

### 📦 Operations & Automation

**Use config management (Ansible, Terraform, etc.)** to distribute certs, rotate keys, and push config changes uniformly across your fleet. Manual SSH-based distribution does not scale.

**Monitor certificate expiry via Prometheus.** Nebula exposes a Prometheus endpoint. Monitor it in Grafana with an alert on CA and host certificate expiration so you aren't caught off guard.

**Automate with Managed Nebula if self-hosting is a burden.**
Managed Nebula is Nebula with automated certificate management, SSO integration, and a web UI — ideal for teams that want Nebula without running the infrastructure themselves. It supports up to 100 devices for free.

---

### 🆕 Staying Current

**Upgrade to cert v2 and consider IPv6.**
Nebula v1.10 adds support for IPv6-addressed Nebula hosts via a v2 certificate format. While v1 certificates support only a single IPv4 address, v2 allows multiple IPv4 and/or IPv6 addresses. A dual-CA migration strategy enables a smooth transition with easy rollback capability.

**Use P256 only if compliance demands it.**
The default curve used for cryptographic handshakes and signatures is Curve25519. This is the recommended setting for most users. If your deployment has certain compliance requirements (e.g., FIPS), you can create your CA with `-curve P256` to use NIST Curve P256 and ECDSA signatures.

---

### Quick Reference Checklist

| Area | Action |
|---|---|
| CA key | Stored offline / encrypted, backed up |
| CA rotation | Reminder set 2–3 months before expiry |
| Firewall | Default-deny; group-based rules only |
| Key file perms | Readable by root only |
| Lighthouses | At least 2, stable public IPs, UDP/4242 open |
| Punchy | Enabled on all nodes |
| Subnet | Non-overlapping, sized for growth |
| Monitoring | Prometheus + cert expiry alerts |
| Automation | Config management for cert distribution |
| Nebula version | v1.10+ for cert v2 / IPv6 support |

---

## 3. User

let build a skill with this info

---

## 4. AI

Great — I have everything I need from the research. Let me write the skill now.The skill is packaged and ready. Here's what was built:

**`nebula-overlay-network.skill`** — structured as:

```
nebula-overlay-network/
├── SKILL.md                              ← Main skill (always loaded)
└── references/
    ├── pki-and-certs.md                  ← CA creation, key security, rotation
    ├── lighthouses-and-connectivity.md   ← Lighthouse setup, punchy, relays, HA
    ├── firewall-and-groups.md            ← Groups, rules, zero-trust patterns
    └── operations.md                     ← Subnets, Ansible, monitoring, IPv6
```

**What it covers:**
- **SKILL.md** has an architecture summary, quick-start checklist, key commands, config skeleton, common firewall patterns, and a routing table that tells Claude when to load each reference file
- The 4 reference files are loaded on-demand depending on the question — keeping things fast and focused
- The description is tuned to trigger on Nebula-specific language *and* intent-based queries (mesh VPN, Tailscale/ZeroTier alternatives, etc.)

To install it, go to **Settings → Skills** in Claude and upload the `.skill` file.

---

## 5. User

add a best practice for netbird, windows firewall, linux firewall, ip routing and switching Ruckus ICX series best practice
