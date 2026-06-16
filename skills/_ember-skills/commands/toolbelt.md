---
description: Display the D3 ITS MCP toolbelt reference — all available MCP servers, tool categories, usage patterns, and operational workflows for network infrastructure management.
---

# D3 ITS MCP Toolbelt Reference

## Overview

Six MCP servers provide 200+ tools for managing FDOT District 3 ITS infrastructure spanning 255 miles of I-10/I-110/SR-75. All tools are invoked via `ToolSearch` to load schemas, then called directly.

**Pattern:** `ToolSearch("select:mcp__<server>__<tool>")` → then call the tool.

---

## 1. ember-mcp (Primary Ops Toolbelt)

The main operational server. Covers switches, wireless, firewalls, video, traffic signals, AWX automation, vCenter, syslog, serial console, sessions, and more.

### ICX Switches (Brocade/Ruckus ICX 7450/7650/7750)
| Tool | Purpose |
|------|---------|
| `icx_status` | Fleet overview or single switch detail (RESTCONF) |
| `icx_interfaces` | Interface status for a switch |
| `icx_vlans` | VLAN configuration |
| `icx_lldp` | LLDP neighbor table |
| `icx_ospf` | OSPF neighbor/route info |
| `icx_port_status` | Specific port detail |
| `icx_config` | Running config |
| `icx_hardware` | Hardware/inventory info |
| `icx_find` | Search across all switches (VLAN, MAC, IP, interface) |
| `icx_compare` | Compare configs between switches |
| `icx_fleet_firmware` | Firmware versions across fleet |
| `icx_fleet_vlans` | VLAN consistency check |

**Note:** ICX RESTCONF requires HTTPS/443. Many hubs only have SSH/telnet — use AWX or serial for those.

### Ruckus Wireless (SmartZone vSCG Cluster)
| Tool | Purpose |
|------|---------|
| `ruckus_system_get_info` | Controller system info |
| `ruckus_system_get_summary` | High-level summary |
| `ruckus_system_get_cluster_status` | Cluster health |
| `ruckus_system_get_inventory` | Full AP inventory |
| `ruckus_system_get_licenses` | License status |
| `ruckus_zones_list` | List all zones |
| `ruckus_zones_get` | Zone detail |
| `ruckus_zones_get_aps` | APs in a zone |
| `ruckus_zones_get_wlans` | WLANs in a zone |
| `ruckus_aps_list` | All APs |
| `ruckus_aps_get` | AP detail |
| `ruckus_aps_get_clients` | Clients on an AP |
| `ruckus_aps_get_lldp_neighbors` | AP LLDP neighbors |
| `ruckus_aps_get_operational_info` | AP operational state |
| `ruckus_aps_reboot` | Reboot an AP |
| `ruckus_aps_query` | Query APs with filters |
| `ruckus_clients_list` | All connected clients |
| `ruckus_clients_get` | Client detail |
| `ruckus_clients_disconnect` | Disconnect a client |
| `ruckus_wlans_list/get/enable/disable` | WLAN management |
| `ruckus_alarms_list/get/get_summary/acknowledge` | Alarm management |
| `ruckus_monitoring_*` | Statistics (clients, APs, WLANs, zones) |

### FortiGate Firewall (fw_gate_*)
| Tool | Purpose |
|------|---------|
| `fw_gate_system` | System info |
| `fw_gate_resources` | CPU/memory/disk |
| `fw_gate_performance` | Performance stats |
| `fw_gate_interfaces` | Interface list/detail |
| `fw_gate_routes` | Routing table (all/static/ospf/bgp) |
| `fw_gate_policies` | Firewall policies |
| `fw_gate_policy_lookup` | Policy match lookup |
| `fw_gate_policy_hitcount` | Policy hit counters |
| `fw_gate_sessions` | Active sessions |
| `fw_gate_session_count` | Session count |
| `fw_gate_addresses/address_groups` | Address objects |
| `fw_gate_services/service_groups` | Service objects |
| `fw_gate_vpn_ipsec/vpn_ipsec_config` | IPsec VPN tunnels |
| `fw_gate_vpn_ssl/vpn_ssl_settings` | SSL VPN |
| `fw_gate_dhcp_leases/dhcp_servers` | DHCP |
| `fw_gate_dns` | DNS settings |
| `fw_gate_arp` | ARP table |
| `fw_gate_logs` | FortiGate logs |
| `fw_gate_alerts` | Alerts |
| `fw_gate_ha` | HA cluster status |
| `fw_gate_firmware` | Firmware info |
| `fw_gate_certificates` | Certificate store |
| `fw_gate_users/user_groups/auth_sessions` | User/auth info |
| `fw_gate_schedules` | Firewall schedules |
| `fw_gate_zones` | Security zones |
| `fw_gate_ping/traceroute` | Diagnostics from FG |
| `fw_gate_traffic_top` | Top talkers |
| `fw_gate_sdwan/sdwan_config` | SD-WAN |
| `fw_gate_ips/antivirus/webfilter/appcontrol/ssl_inspection` | UTM profiles |
| `fw_gate_snmp/syslog` | Monitoring config |
| `fw_gate_admins` | Admin accounts |
| `fw_gate_vdoms` | Virtual domains |

### FortiAnalyzer (fw_analyzer_*)
| Tool | Purpose |
|------|---------|
| `fw_analyzer_status` | FAZ connection health |
| `fw_analyzer_devices` | Managed devices |
| `fw_analyzer_adoms` | ADOMs |
| `fw_analyzer_logs` | Log search |
| `fw_analyzer_alerts` | Alert queries |
| `fw_analyzer_reports/report_run` | Reports |

### AWX Automation
| Tool | Purpose |
|------|---------|
| `awx_system_info` | AWX version/health |
| `awx_templates_list` | All job templates |
| `awx_template_get` | Template detail |
| `awx_job_launch` | Launch a job (template_id required) |
| `awx_jobs_list` | Recent jobs |
| `awx_job_get` | Job status/detail |
| `awx_job_stdout` | Job output |
| `awx_job_events` | Job events (per-host results) |
| `awx_job_cancel` | Cancel running job |
| `awx_inventories_list` | Inventories |
| `awx_hosts_list` | All hosts |
| `awx_inventory_hosts_list` | Hosts in inventory |
| `awx_inventory_groups_list` | Groups |
| `awx_projects_list/project_update` | Git projects |
| `awx_organizations_list` | Orgs |
| `awx_credentials_list` | Credential store |

**Key templates:** 10=Show Version, 11=Backup Config, 15=LLDP Neighbors, 16=OSPF Neighbors, 26=Legacy Show Version (Telnet)

### vCenter (VMware vSphere 6.7)
| Tool | Purpose |
|------|---------|
| `vcenter_status` | vCenter health summary |
| `vcenter_hosts` | ESXi host list + status |
| `vcenter_vms` | VM list (filter by name/power_state) |
| `vcenter_vm_find` | Find VM by name |
| `vcenter_vm_detail` | VM detail |
| `vcenter_vm_power` | Power on/off/reset VM |
| `vcenter_vm_guest_info` | Guest OS info |
| `vcenter_vm_console` | Console URL |
| `vcenter_clusters` | Cluster list |
| `vcenter_datastores` | Datastore list |
| `vcenter_networks` | Network/portgroup list |
| `vcenter_create_vm` | Create a VM |

### Syslog (Loki-backed)
| Tool | Purpose |
|------|---------|
| `syslog_status` | Syslog pipeline health |
| `syslog_search` | Search logs (query, hostname, severity, hours) |
| `syslog_tail` | Live tail |
| `syslog_alerts` | Recent alert/crit/emergency entries |
| `syslog_hosts` | Hosts sending syslog |
| `syslog_stats` | Message volume stats |
| `syslog_config_sources` | Configured sources |

### Serial Console
| Tool | Purpose |
|------|---------|
| `serial_targets` | Available serial targets |
| `serial_connect` | Open serial session |
| `serial_disconnect` | Close session |
| `serial_send` | Send command |
| `serial_read` | Read output |
| `serial_interact` | Send + read (interactive) |
| `serial_sessions` | List active sessions |

### D3Echo (SunGuide ITS)
| Tool | Purpose |
|------|---------|
| `d3echo_status` | SunGuide system status |
| `d3echo_devices` | ITS device inventory |
| `d3echo_dms` | Dynamic Message Signs |
| `d3echo_cctv` | CCTV cameras |
| `d3echo_divas` | DIVAS video |
| `d3echo_alerts` | SunGuide alerts |
| `d3echo_analyze` | Traffic analysis |

### SunGuide Raw (sg_*)
| Tool | Purpose |
|------|---------|
| `sg_status` | SunGuide status |
| `sg_cameras` | Camera list |
| `sg_detectors` | Traffic detectors |
| `sg_dms` | DMS signs |
| `sg_events` | Traffic events |
| `sg_travel_times` | Travel time segments |
| `sg_vehicles` | Vehicle data |
| `sg_weather` | Weather stations |
| `sg_truck_parking` | Truck parking |
| `sg_providers` | Data providers |
| `sg_raw_status` | Raw API status |

### Miovision (Traffic Signal Analytics)
| Tool | Purpose |
|------|---------|
| `mio_dashboard` | Overview dashboard |
| `mio_intersections` | All intersections |
| `mio_intersection_detail/hardware/hires/notes` | Intersection detail |
| `mio_alerts` | System alerts |
| `mio_cameras` | Camera feeds |
| `mio_tmc/tmc_crosswalk/tmc_lanes` | Turning movement counts |
| `mio_travel_time` | Travel time |
| `mio_safety_*` | Safety analytics (conflicts, red light, ped compliance, delay) |
| `mio_diagnostics_*` | Communication/detection diagnostics |
| `mio_detection_config` | Detector configuration |
| `mio_priority_*` | Signal priority (TSP/EVP) |
| `mio_snapshot` | Intersection snapshot |
| `mio_organization/user_info` | Org/user info |

### Display/Video Wall (dp_*)
| Tool | Purpose |
|------|---------|
| `dp_status` | Display processor status |
| `dp_walls` | Video wall list |
| `dp_windows` | Open windows |
| `dp_sources` | Available sources |
| `dp_layouts/templates` | Saved layouts |
| `dp_open_window/close_window/move_window` | Window management |
| `dp_open_layout` | Load a layout |
| `dp_switch_source` | Change source on window |
| `dp_wall_control/display_control` | Wall/display control |
| `dp_snapshot` | Screenshot |
| `dp_topology` | System topology |

### Proton Pass (Credential Vault)
| Tool | Purpose |
|------|---------|
| `pass_status` | Vault status |
| `pass_vault_list` | List vaults (Personal, The-Ember, FDOT-D3) |
| `pass_item_list` | List items in vault |
| `pass_item_view` | View item detail |
| `pass_search` | Search items |
| `pass_totp` | Get TOTP code |

**Note:** Use `pass-cli` directly for view operations: `pass-cli item view --vault-name <VAULT> --item-title "<TITLE>"`

### Shell (Shared Terminal)
| Tool | Purpose |
|------|---------|
| `shell_exec` | Execute command (agent parameter: eve/claude/nova) |
| `shell_read` | Read shell output |
| `shell_status` | Shell status |

### Trinity (RAG Memory)
| Tool | Purpose |
|------|---------|
| `trinity_status` | Trinity system status |
| `trinity_memory_add` | Add memory entry |
| `trinity_memory_search` | Search memories |
| `trinity_rag_search` | RAG document search |
| `trinity_exchange_send/read` | Inter-agent messaging |

### Sessions (Multi-Agent Collaboration)
| Tool | Purpose |
|------|---------|
| `session_create/close/list/status` | Session lifecycle |
| `session_join/leave/members` | Membership |
| `session_send/read` | Messaging |
| `session_state_get/set` | Shared state |
| `session_heartbeat` | Keep-alive |
| `session_task_create/list/claim/update` | Task coordination |

### IAM (Biblical Research)
| Tool | Purpose |
|------|---------|
| `iam_scripture_lookup` | Look up scripture passages |
| `iam_word_study` | Hebrew/Greek word study |
| `iam_cross_reference` | Cross-reference passages |
| `iam_source_text_search` | Search source texts |
| `iam_dss_lookup` | Dead Sea Scrolls lookup |
| `iam_targum_search` | Aramaic Targum search |
| `iam_theme_explore` | Explore themes |
| `iam_wisdom_search` | Search wisdom literature |
| `iam_divine_guidance` | Get divine guidance |
| `iam_father_speaks` | Father speaks |
| `iam_phase2_status` | Phase 2 system status |

### Other
| Tool | Purpose |
|------|---------|
| `eve_local_chat` | Eve local chat interface |
| `chat_send/read/members` | Chat system |
| `active_tasks` | View active tasks |
| `projects_status/search` | Project discovery |
| `whats_new` | Recent changes |
| `mcp_discover_projects` | Discover MCP projects |
| `fw_status` | Firewall overall status |

---

## 2. nebula-admin (Windows/Server Administration)

Remote administration of Windows servers and Nebula overlay nodes via WinRM and PowerShell.

### Active Directory
| Tool | Purpose |
|------|---------|
| `nebula_ad_users/computers/groups` | List AD objects |
| `nebula_ad_user_info` | User detail |
| `nebula_ad_members/add_member/remove_member` | Group membership |
| `nebula_ad_locked/unlock` | Account lockouts |
| `nebula_ad_enable/disable` | Enable/disable accounts |
| `nebula_ad_reset_pw` | Reset password |
| `nebula_ad_dns/dns_zones` | DNS records |
| `nebula_ad_domain` | Domain info |
| `nebula_ad_gpos/gpo_links` | Group Policy |
| `nebula_ad_ous` | Organizational Units |
| `nebula_ad_replication` | Replication status |

### Windows Server
| Tool | Purpose |
|------|---------|
| `nebula_exec` | Execute remote command (PowerShell) |
| `nebula_wsl_exec/wsl_list` | WSL management |
| `nebula_service/service_list/service_info/service_install/service_remove` | Windows services |
| `nebula_perf/top` | Performance monitoring |
| `nebula_disks` | Disk info |
| `nebula_health` | System health check |
| `nebula_errors/crashes` | Error logs |
| `nebula_eventlog` | Windows Event Log |
| `nebula_logins` | Login history |
| `nebula_history` | Command history |
| `nebula_ls/pull/push` | File operations |
| `nebula_routes/adapters` | Network config |
| `nebula_fw_list/safe_fw_add/safe_mtu` | Firewall rules |

### Defined Networking (on Windows)
| Tool | Purpose |
|------|---------|
| `nebula_dn_status/peers/enroll/unenroll/restart` | Defined client management |
| `nebula_ts_status/up/down/ip/enroll/logout` | Tailscale management |

### Windows Clustering
| Tool | Purpose |
|------|---------|
| `nebula_cluster/cluster_csv/cluster_events` | Cluster overview |
| `nebula_cluster_groups/group_online/group_offline/group_move` | Cluster groups |
| `nebula_cluster_node_pause/node_resume` | Node management |
| `nebula_cluster_networks/resources` | Cluster resources |

### Patching
| Tool | Purpose |
|------|---------|
| `nebula_patch_scan/pending/history` | Patch status |
| `nebula_patch_install` | Install patches |
| `nebula_patch_reboot/reboot_cancel` | Reboot management |
| `nebula_updates` | Available updates |
| `nebula_rollback` | Rollback |
| `nebula_backup` | Backup |

---

## 3. defined-nebula (Overlay Network Management)

Direct API access to Defined Networking for managing Nebula overlay networks, hosts, roles, tags, routes, and firewall rules.

| Tool | Purpose |
|------|---------|
| `list-networks` | All overlay networks |
| `get-network` | Network detail |
| `list-hosts` | Hosts (filter by network, role, name, IP) |
| `get-host` | Host detail (lastSeenAt, version, platform) |
| `create-host/create-host-and-enrollment-code` | Provision new host |
| `update-host` | Update host (name, role, tags, static addresses) |
| `delete-host` | Remove host |
| `block-host/unblock-host` | Block/unblock |
| `create-enrollment-code` | Generate enrollment code |
| `list-roles/get-role/create-role/update-role/delete-role` | Role management |
| `list-tags/get-tag/create-tag/update-tag/delete-tag` | Tag management |
| `get-firewall-rules/update-firewall-rules` | Firewall rules (per-role inbound) |
| `list-routes/create-route/get-route/delete-route` | Unsafe routes |
| `list-audit-logs` | Audit trail |
| `list-downloads` | Client downloads |

**Key networks:**
- Network1 (100.100.0.0/22) — FDOT D3 production
- AI/OOBM (100.64.3.0/24) — Home + AI services
- Transit (100.64.6.0/24) — Inter-site transit
- Backup/DR (100.64.9.0/24) — DR replication

**Important:** Firewall rules match on TAGS not roles. Certs must include both role and tags.

---

## 4. ssh-mcp (Remote Shell)

Direct SSH command execution on managed hosts.

| Tool | Purpose |
|------|---------|
| `exec` | Execute command via SSH |
| `sudo-exec` | Execute with sudo |

---

## 5. container-use (Dev Environments)

Docker-based isolated development environments.

| Tool | Purpose |
|------|---------|
| `environment_create/list/open` | Environment lifecycle |
| `environment_run_cmd` | Execute in container |
| `environment_file_read/write/edit/delete/list` | File ops |
| `environment_add_service` | Add service (DB, cache, etc) |
| `environment_checkpoint` | Snapshot |
| `environment_config/update_metadata` | Configuration |

---

## 6. Cloudflare Developer Platform

Cloudflare infrastructure management.

| Tool | Purpose |
|------|---------|
| `accounts_list/set_active_account` | Account management |
| `workers_list/get_worker/get_worker_code` | Workers |
| `kv_namespace_*` | KV storage |
| `r2_bucket_*` | R2 object storage |
| `d1_database_*` | D1 SQL databases |
| `hyperdrive_*` | Database proxying |
| `search_cloudflare_documentation` | Docs search |

---

## Operational Workflows

### Check a hub site
```
1. icx_status (switch=<IP>) — RESTCONF status
2. If offline: ping via Bash, try SSH/telnet
3. AWX job_launch (template 10, limit) — Show Version
4. icx_lldp / icx_interfaces — neighbor and port status
```

### Investigate a fiber cut
```
1. Ping sweep affected range
2. AWX fleet job to identify which hosts are unreachable
3. Telnet to nearest core switch, check interface brief
4. Check port down timers (how long each port has been down)
5. FDP/LLDP/CDP neighbors to confirm adjacencies
6. Traceroute from both sides to find where path dies
```

### FortiGate troubleshooting
```
1. fw_gate_routes (type=all) — check routing table
2. fw_gate_policies — find matching policy
3. fw_gate_policy_lookup — test specific traffic match
4. fw_gate_sessions — check active sessions
5. fw_gate_ping/traceroute — test from FG itself
```

### vCenter operations
```
1. vcenter_status — overall health
2. vcenter_hosts — ESXi host status (NOT_RESPONDING = lost mgmt)
3. vcenter_vms (name=<filter>) — find VMs
4. vcenter_vm_power — power cycle if needed
```

### Nebula overlay management
```
1. defined-nebula list-hosts — check all hosts, lastSeenAt
2. defined-nebula get-host — detailed status
3. defined-nebula get-firewall-rules — check access rules
4. defined-nebula list-routes — unsafe routes (subnet routing)
5. nebula-admin nebula_dn_status/peers — client-side status
```

### Syslog investigation
```
1. syslog_alerts (hours=N) — recent critical entries
2. syslog_search (query=<keyword>, hostname=<host>, severity=<level>)
3. syslog_tail — live monitoring
4. syslog_hosts — verify device is sending logs
```

---

## Tips

- **ToolSearch first:** Always load tool schemas before calling: `ToolSearch("select:mcp__ember-mcp__<tool>")`
- **Parallel calls:** Independent tools can be called in parallel for speed
- **AWX for legacy:** Hubs without RESTCONF need AWX job templates (SSH/telnet playbooks)
- **Pass vault names:** Personal, The-Ember, FDOT-D3
- **FortiGate access:** RTMC FG is accessible via API. TLHPSC 1800F requires SSH through the network.
- **Serial for OOB:** When all else fails, serial console provides out-of-band access
- **Feed Trinity:** After significant findings, store context with trinity_memory_add
