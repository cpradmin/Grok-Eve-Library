# File Inventory — Interesting Reads & Resources

> Cross-machine index of documentation, skills, configs, tools, and reference material.
> Last updated: 2026-05-23

---

## Skills (Claude Code / Cline)

| Skill | Location | Lines | Notes |
|-------|----------|-------|-------|
| **network-security-operations** | Admin-Hub `Downloads\_skill-extract-latest\` | 3,057 | 11 reference files: Cloudflare, Fortinet, Ruckus ICX, firewalls, routing, PKI, NetBird, operations |
| **netbird** | Admin-Hub `Downloads\Claude-Skills\netbird\` | ~500 | Config, deployment, troubleshooting references |
| **nebula** | Admin-Hub `Downloads\Claude-Skills\nebula\` | ~650 | Config, certs, deployment, troubleshooting references |
| **nebula (D3 ITS)** | pop-os `~/.claude/skills/nebula.md` | 169 | Infrastructure-specific: real IPs, paths, API patterns, unsafe_routes |
| **proton-pass-cli** | Admin-Hub `Downloads\proton-pass-cli.skill` | — | Proton Pass CLI integration |
| **network-security-operations (v1)** | Admin-Hub `Downloads\_skill-extract\` | 2,400 | Older version, missing Cloudflare+Fortinet refs |

All skills are mirrored to Forge: `adam/claude-skills`

---

## API Specifications

| Spec | Location | Format |
|------|----------|--------|
| **Defined Networking API** | Admin-Hub `Downloads\openapi.yaml` | OpenAPI 3.1.0 |
| **Dell Storage Manager REST API** | pop-os `Downloads/Documents/FDOT-Reference/common_dell-storage-manager-rest-api-cookbook-3029-wp-san_en-us.pdf` | PDF |
| **Ruckus ICX RESTCONF API** | pop-os `Downloads/Documents/FDOT-Reference/TN_How to Use the RUCKUS ICX RESTCONF API.pdf` | PDF |

---

## Architecture & Planning Documents

### On Forge (`adam/claude-skills/docs/`)
| Document | Author | Date |
|----------|--------|------|
| T3 Spin-Up Gap Analysis | Nova | 2026-05-10 |
| T3 Forge Charter | Nova/Eve | 2026-05-09 |
| Disaster Recovery Plan (Local-Only) | Nova | 2026-05-10 |
| Master MCP Spec v0.2 → v0.8 | Eve/Nova | 2026-05-01 |
| Icosahedral Trinity V3 | Eve | 2026-05-01 |

### On Admin-Hub (`C:\Users\KNTRNJMB\Downloads\`)
| Document | Size | Notes |
|----------|------|-------|
| `claude_T3_Sovereign_Forge_Architecture_2026-05-09.md` | 45KB | Full T3 architecture session |
| `claude_Homelab practice for FDOT D3 ITS network_bc57d2fe.md` | 318KB | Comprehensive homelab/FDOT practice guide |
| `claude_Virtual router with local AI on VMware_fd27cd9e.md` | 852KB | FRR + AI on vSphere (4 versions) |
| `claude_Troubleshooting issues_f4f715a4.md` | 150KB | Troubleshooting compendium |
| `claude_Tab review_75e466cc.md` | 385KB | Full browser tab audit |
| `T3-Spinup-Gap-Analysis-2026-05-10.md` | 19KB | Gap analysis for T3 spin-up |
| `Disaster-Recovery-Plan-Local-Only-2026-05-10.md` | 50KB | DR plan |

### On Admin-Hub (`Downloads\files.zip`)
| Document | Size | Notes |
|----------|------|-------|
| `FDOT_D3_ITS_Security_Policy_Rev0_Draft.docx` | 19KB | Security policy draft |
| `FDOT_D3_ITS_Security_Policy_Rev0_Draft.html` | 37KB | HTML version |
| `DEPLOY.md` | 2KB | Deployment notes |

---

## FDOT Network Reference

### pop-os (`~/Downloads/Documents/FDOT-Reference/`)
| File | Type | Notes |
|------|------|-------|
| `CHP-Bubble-Chart.pdf` | PDF | D3 hub topology bubble chart |
| `CHP-Fiber-Plans.pdf` | PDF | Fiber plant plans |
| `CHPFiber_Plans-10312019 (1).pdf` | PDF | Updated fiber plans |
| `FDOT_D3_Phase1_Final.pdf` | PDF | Phase 1 final report |
| `FDOT_AI_Compliance_Checklist-Jon.pdf` | PDF | AI compliance checklist (Jon's version) |
| `FDOT-D3-Hubs.kmz` | KML | Hub locations (Google Earth) |
| `Untitled map- FDOT-D3-Hubs.csv` | CSV | Hub coordinates export |
| `camera-list-2026-04-09_11-48-57.xlsx` | Excel | CCTV camera inventory |
| `Chipley_DB_IP_090215.xlsx` | Excel | Chipley hub IP assignments |
| `miovision_devices_2026-03-12.csv` | CSV | Miovision device inventory |
| `network-overview-data-export.csv` | CSV | Network overview export |
| `dmz-172.60.1.0-scan-2026-05-06.txt` | Text | DMZ network scan |
| `cp_config_R1900-5GB-4-10-2026.bin` | Binary | Cradlepoint R1900 config backup |
| `port5_root.pcap` | PCAP | Packet capture |
| `Strand 710_96F SM FOC_Barry_TLH_PSC.trc` | Trace | OTDR fiber trace |
| `dsm_vasa.crt` / `dsm_vasa.key` | Cert | Dell Storage Manager VASA certs |
| `FG3K4ETB19900064_debug.log` | Log | FortiGate 3400E debug log |

### Admin-Hub (`C:\Users\KNTRNJMB\Downloads\`)
| File | Type | Notes |
|------|------|-------|
| `Homelab_practice_for_FDOT_D3_ITS_network_2026-04-07.pdf` | PDF | Homelab guide |
| `grok-chat-ICX8200.pdf` | PDF | ICX 8200 deployment planning (Grok session) |
| `I10-HUB6-EAST.drawio.pdf` | PDF | I-10 Hub 6 East diagram |
| `CHP-Ring-Planning-I10-Hub6-East.drawio.pdf` | PDF | Ring planning diagram |
| `Wired_Network(2025_06_02).pdf` | PDF | Wired network overview |
| `Iteris-BlueTOAD-Spectra-RSU-C-V2XUserGuide.pdf` | PDF | V2X RSU user guide |
| `CHP_Cabs.xlsx` | Excel | Cabinet inventory |
| `Escambia_County_Signalization_IP Scheme.xlsx` | Excel | Escambia signal IPs |
| `BlueTOAD Programming Cheat Sheet.xlsx` | Excel | BlueTOAD config reference |
| `Copy of RSU install information.xlsx` | Excel | RSU installation data |
| `Chipley_Master.xlsx` | Excel | Chipley master inventory |
| `Pens Loc & IP's.xlsx` | Excel | Pensacola locations + IPs |
| `3 Mile Bridge IP Address(30582).xlsx` | Excel | 3 Mile Bridge IPs |

### Admin-Hub Maps & GIS
| File | Location | Notes |
|------|----------|-------|
| `FDOT D3 Map\doc.kml` | Downloads | D3 hub map (KML) |
| `Escambia-FDOT-Infrastructure\west-doc.kml` | Downloads | Escambia county infrastructure |
| `I10-7.0-M MAP files\` | Downloads | I-10 mile marker maps |
| `RSU-Configs\*.geojson` | Downloads | RSU/V2X GeoJSON placement configs |

---

## Firmware & Software

### ICX Switch Firmware (Admin-Hub `Downloads\`)
| Version | Path | Models |
|---------|------|--------|
| 08090g | `08090g\` | ICX7150, ICX7250, ICX7450, ICX7650, ICX7850 |
| 08080f (Latest) | `08080f(Latest)\` | ICX7150, ICX7250, ICX7450, ICX7650, ICX7850 |
| 08070ga | `08070ga\` | Older release |

### FortiGate Images
| File | Location | Notes |
|------|----------|-------|
| `FW_ITS-8040+_v113.dat` | Admin-Hub Downloads | ITS-8040+ firmware |
| `FAZ_VM64-v6-build2473-FORTINET.out` | Admin-Hub Downloads | FortiAnalyzer VM image (300MB) |
| `FFW_VM64_KVM-v7.4.1.F-build2463-FORTINET.out.kvm\` | Admin-Hub Downloads | FortiGate KVM image |

### Cradlepoint
| File | Location | Notes |
|------|----------|-------|
| `R1900-0fc.json` | pop-os Downloads | R1900 config export (firmware 7.24.24) |
| `R1900-0fc (1).json` | pop-os Downloads | Second export |

### ISOs
| File | Location | Size |
|------|----------|------|
| `pop-os_24.04_amd64_nvidia_5.iso` | pop-os Downloads | 3.2GB |
| `Win11_25H2_English_x64_v2.iso` | pop-os Downloads | 8.5GB |

### Tools
| Tool | Location | Notes |
|------|----------|-------|
| `MLNX_WinOF2-26_1_50000_All_x64.exe` | pop-os Downloads | Mellanox 25G NIC driver (335MB) |
| `Alienware_Area-51_AA16250_AA18250_1.9.0_64.exe` | pop-os Downloads | BIOS update |
| `DNClient-Desktop (1).msi` | Admin-Hub Downloads | Defined Networking client installer |
| `ICXConfigurator-V1.1\` | Admin-Hub Downloads | Ruckus ICX config tool |
| `axctl-master\` | Admin-Hub Downloads | Axis camera CLI (Rust) |
| `SwitchMinerInstallv421\` | Admin-Hub Downloads | Network switch discovery |
| `lantopolog252\` | Admin-Hub Downloads | LAN topology mapper |

---

## Visio Stencils (Admin-Hub `Downloads\`)

| Vendor | Folders |
|--------|---------|
| **Ruckus ICX** | `Ruckus ICX Visio Stencils\`, `(1)\`, `(2)\` |
| **Ruckus Wireless** | `Visio Stencils_ Ruckus Wireless Access Points\` |
| **Fortinet** | `Fortinet Visio Stencil\`, `(4)\`, `(5)\`, `Fortinet_Products_MAY2023\` |
| **Dell PowerEdge** | `Dell-PowerEdge-RackServers\`, `(2)\`, `(4)\`, `(6)\`, `TowerServers\` |
| **Dell Storage** | `Dell-Storage-SC-Series\`, `(1)\`, `Dell-Classic-Servers\`, `(2)\` |
| **Dell EMC Unity** | `DellEMC_Unity\`, `Unity_Stencils\`, `(3)\`, `(6)\` |
| **EMC** | `EMC_Graphics_stencil_02_Nov_09\` |
| **Cisco** | `Interfaces_and_Modules_-_HWICs-1-14-08\`, `switches_catalyst_4500-X\` |
| **Generic** | `VSDfx-Generic (1)\`, `Stencils\` |

---

## Conversation Archives

### Claude Conversations (Admin-Hub `claude_Jon_all_2026-05-23.zip`)
50+ conversations, 36MB total. Highlights:
- `claude_ff8f32d8_Route-only configuration on VE member ports.json` (717KB)
- `claude_8a78becf_PDF editing for infrastructure diagrams.json` (16MB)
- `claude_de3d4d59_Local AI session mesh bridge for Grok.json` (2.7MB)
- `claude_75e466cc_Tab review.json` (2.2MB)
- `claude_945b8711_Playing MIDI music with Grok locally.json` (749KB)
- `claude_112de88a_Sunguide 9 standalone upgrade testing.json` (739KB)
- `claude_9321ece3_ZFS mirrored pool setup on Proxmox.json` (774KB)
- `projects/` subfolder: Ai-Dream Team code, Love-Unlimited scripts, Claude prompting guide

### Grok Conversations (pop-os `~/Downloads/Documents/`)
62 JSON exports. Notable:
- `grok_CHP D3 ITS ICX-7950 Deployment Planning` — ICX 8200/7950 planning
- `grok_Organizing Chat Memories for Local AI` — memory architecture
- `grok_OSPF Setup Flawless, Problem Remains` — OSPF troubleshooting
- `grok_Cline Triple External API Setup` — multi-API config

### Grok Bulk Exports (pop-os `~/Downloads/`)
- `grok_f110cbec.json` — 17-19MB (4 versions, likely full Grok history exports)

---

## Miscellaneous

### pop-os (`~/Downloads/Documents/`)
| Path | Notes |
|------|-------|
| `Antigravity-Claude-Code-Proxy/` | Multi-model proxy (Gemini, Claude, GPT-OSS, Perplexity) |
| `BrowserOS/` | BrowserOS project files |
| `grok-4-cli/` | Grok 4 CLI tool (Node.js) |
| `love-unlimited/` | Agent deployment scripts, Grok memory tools |
| `My-Love-Eve/` | Eve conversation exports + images |
| `n8n-docs/` | n8n documentation clone |
| `open-webui/` | Open WebUI source |
| `Cline/MCP/claude-code-plugins-plus-skills/` | Skills marketplace source (Astro site) |
| `Cline/Hooks/`, `Cline/Rules/`, `Cline/Workflows/` | Cline configuration exports |
| `ember-infrastructure.drawio` | Infrastructure diagram (editable) |
| `ember-infrastructure.drawio.html` | Self-contained HTML viewer |
| `itsfm_master_vs_sunguide.csv` | ITSFM naming audit data |
| `misc/copilot_all_prompts_2026-02-10.chatreplay.json` | Copilot prompt archive |
| `misc/vscode-extensions-backup.txt` | VS Code extensions list |

### Admin-Hub (`C:\Users\KNTRNJMB\Downloads\`)
| Path | Notes |
|------|-------|
| `grok-everywhere-main\` | Grok browser extension source |
| `JMB-CELL-BU\` | Samsung phone backup (Magisk, firmware, NetBird installer) |
| `Ruckus Support\` | MobaXterm session logs from Ruckus TAC calls |
| `VCENTER-SSL-Update\` | vCenter SSL cert update docs |
| `FDOTnetwork access20240909\` | FDOT network access request |
| `safeTCORE Outstanding Training Modules\` | Training records |
| `Net2Plan-0.7.0.1\` | Network planning tool |
| `SPARR\` | FDOT SPARR system tools |
| `Subsystem Test\`, `MVDS Subsystem\` | ITS subsystem test tools |
| `ConfigurationManager_7.74.0126\` | Ruckus configuration manager |
| `mediamtx_v1.12.3_windows_amd64\` | MediaMTX RTSP server |
| `happytime-onvif-server-x64\` | ONVIF camera simulator |
| `Notion export zips (2)` | Notion workspace exports (Nov 2025) |
