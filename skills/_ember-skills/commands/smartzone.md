---
description: Ruckus SmartZone (vSZ) operations — CLI commands, REST API, config backups, cluster management, AP troubleshooting, and WLAN operations for the D3 ITS wireless infrastructure.
---

# Ruckus SmartZone (vSZ) Operations

Cluster: 10.175.252.54-56 | vSZ Essentials 7.1.0.0.586 | Creds: admin / T@mpa.2017 | API: port 8443

## SSH Access

```bash
sshpass -p 'T@mpa.2017' ssh admin@10.175.252.54
```

Prompt levels:
- `ruckus>` — user mode (show, ping, traceroute)
- `ruckus#` — privileged mode (`enable` to enter, password same as login)
- `ruckus(config)#` — config mode (`config` from privileged)
- `ruckus(debug)#` — debug mode (`debug` from privileged)

## CLI Command Reference

### User Mode (ruckus>)
| Command | Purpose |
|---------|---------|
| `show version` | Firmware, uptime, model |
| `show cluster` | Cluster nodes, roles, state |
| `show ap` | All managed APs |
| `show zone` | Zone list |
| `show wlan` | WLAN list |
| `show interface` | Management/data interfaces |
| `show running-config` | Current running configuration |
| `show backup-config` | List/verify backup status |
| `ping <ip>` | ICMP ping |
| `traceroute <ip>` | Traceroute |

### Privileged Mode (ruckus#)
| Command | Purpose |
|---------|---------|
| `backup config <ftp-user> <ftp-pass> <ftp-ip> <ftp-port>` | Backup config to FTP |
| `copy backup ftp://user:pass@x.x.x.x/` | Copy cluster backup to FTP |
| `restore` | Restore config (options: all, failover, policy) |
| `reboot` | Reboot controller |
| `shutdown` | Graceful shutdown |
| `set-factory` | Factory reset (DESTRUCTIVE) |
| `upgrade <url>` | Firmware upgrade |

### Config Mode (ruckus(config)#)
| Command | Purpose |
|---------|---------|
| `admin` | Admin user management |
| `controller` | Controller settings |
| `interface management` | Management IP config |
| `interface data` | Data plane IP config |
| `ip name-server <ip>` | DNS server |
| `dhcp` | DHCP settings |
| `vpn` | VPN configuration |
| `no <command>` | Negate/remove config |

### Debug Mode (ruckus(debug)#)
| Command | Purpose |
|---------|---------|
| `diag` | Diagnostic commands |
| `dp-packet-capture` | Data plane packet capture |
| `remote-packet-capture` | Remote AP packet capture |
| `remote-syslogd` | Remote syslog config |
| `save-log` | Export logs to FTP |
| `show` | Debug-level show commands |

## REST API Reference

Base URL: `https://10.175.252.54:8443/wsg/api/public/v11_1`

### Authentication
```bash
# Get service ticket (required for all API calls)
TICKET=$(curl -sk -X POST "https://10.175.252.54:8443/wsg/api/public/v11_1/serviceTicket" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"T@mpa.2017"}' | python3 -c "import sys,json; print(json.load(sys.stdin).get('serviceTicket',''))")

# Use ticket as query param on all subsequent calls
curl -sk "https://10.175.252.54:8443/wsg/api/public/v11_1/cluster/state?serviceTicket=$TICKET"
```

### Config Backup Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/configuration?serviceTicket=` | List config backups (id, date, size, md5) |
| POST | `/configuration/backup?serviceTicket=` | Create new config backup |
| GET | `/configuration/download?id={id}&serviceTicket=` | Download backup file |
| POST | `/configuration/upload?serviceTicket=` | Upload a backup file |
| POST | `/configuration/restore/{id}?serviceTicket=` | Restore from backup by ID |
| DELETE | `/configuration/{id}?serviceTicket=` | Delete a backup |

### Cluster Backup Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/cluster?serviceTicket=` | List cluster backups |
| POST | `/cluster/backup?serviceTicket=` | Create cluster backup |
| POST | `/cluster/restore/{id}?serviceTicket=` | Restore cluster backup |
| DELETE | `/cluster/{id}?serviceTicket=` | Delete cluster backup |
| GET | `/cluster/state?serviceTicket=` | Cluster health/state |

### Scheduled Backup Settings
| Method | Path | Description |
|--------|------|-------------|
| GET/PATCH | `/configurationSettings/scheduleBackup?serviceTicket=` | Scheduled backup config |
| GET/PATCH | `/configurationSettings/autoExportBackup?serviceTicket=` | Auto-export to FTP settings |

### Common Operational Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/rkszones?serviceTicket=` | List zones |
| GET | `/rkszones/{id}/wlans?serviceTicket=` | WLANs in a zone |
| GET | `/aps?serviceTicket=` | List all APs |
| GET | `/aps/{mac}?serviceTicket=` | AP details by MAC |
| POST | `/query/ap?serviceTicket=` | Query APs with filters |
| GET | `/system/inventory?serviceTicket=` | System inventory |
| GET | `/system/systemSummary?serviceTicket=` | System summary stats |

## Current Backup Inventory

| Type | Date | Version | Size |
|------|------|---------|------|
| Config | 2023-09-14 | 6.1.1.0.959 | ~20 MB |
| Config | 2025-03-20 | 6.1.1.0.959 | ~20 MB |
| Config | 2025-03-20 | 6.1.1.0.959 | ~20 MB |
| Cluster | 2024-10-23 | — | ~2.9 GB |
| Cluster | 2025-02-19 | — | ~2.9 GB |
| Cluster | 2025-03-18 | — | ~2.9 GB |
| Cluster | 2025-03-20 | — | ~2.9 GB |

Backup filename format: `{ClusterName}_BackupConf_{MMdd}_db_{MM}_{dd}_{HH}_{mm}.bak`

## Quick Operations

### List config backups via API
```bash
TICKET=$(curl -sk -X POST "https://10.175.252.54:8443/wsg/api/public/v11_1/serviceTicket" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"T@mpa.2017"}' | python3 -c "import sys,json; print(json.load(sys.stdin).get('serviceTicket',''))")
curl -sk "https://10.175.252.54:8443/wsg/api/public/v11_1/configuration?serviceTicket=$TICKET" | python3 -m json.tool
```

### Create a new config backup
```bash
curl -sk -X POST "https://10.175.252.54:8443/wsg/api/public/v11_1/configuration/backup?serviceTicket=$TICKET"
```

### Download a backup
```bash
curl -sk -o backup.bak "https://10.175.252.54:8443/wsg/api/public/v11_1/configuration/download?id=BACKUP_ID&serviceTicket=$TICKET"
```

### Check cluster health
```bash
curl -sk "https://10.175.252.54:8443/wsg/api/public/v11_1/cluster/state?serviceTicket=$TICKET" | python3 -m json.tool
```

## MCP Tool Mapping

| Task | MCP Tool | When to use CLI/API instead |
|------|----------|---------------------------|
| List zones | `ruckus_zones_list` | — |
| List WLANs | `ruckus_wlans_list` | — |
| List APs | `ruckus_aps_list` | — |
| AP details | `ruckus_aps_get` | — |
| AP clients | `ruckus_aps_get_clients` | — |
| Alarms | `ruckus_alarms_list` | — |
| System info | `ruckus_system_get_info` | — |
| Cluster status | `ruckus_system_get_cluster_status` | — |
| Config backups | **No MCP tool** | Use API `/configuration` endpoint |
| Backup create | **No MCP tool** | Use API or CLI `backup config` |
| Backup download | **No MCP tool** | Use API `/configuration/download` |
| Restore | **No MCP tool** | Use API or CLI `restore` |
| Reboot controller | **No MCP tool** | SSH CLI `reboot` |
| Packet capture | **No MCP tool** | SSH debug mode |
| Running config | **No MCP tool** | SSH CLI `show running-config` |

## Filesystem Notes

SmartZone does NOT expose direct SCP/SFTP access to backup files. Backups must be retrieved via:
1. REST API `/configuration/download` endpoint
2. CLI `copy backup ftp://` to an FTP server
3. Web UI Administration > Backup and Restore > Download
4. Auto-export via `autoExportBackup` API setting (FTP only)

## Troubleshooting

### AP not joining controller
1. Check AP can reach controller IP: `ping` from AP console
2. Verify AP firmware is compatible with controller version
3. Check zone provisioning rules
4. Check `ruckus_alarms_list` for AP registration failures

### WLAN issues
1. `ruckus_wlans_get` — check WLAN config (auth, encryption, VLAN)
2. `ruckus_aps_get_clients` — check client associations
3. `ruckus_monitoring_get_wlan_statistics` — check traffic stats
4. Debug mode `remote-packet-capture` for over-the-air captures

### Cluster problems
1. `ruckus_system_get_cluster_status` — check node states
2. SSH to each node and `show cluster` — compare views
3. Check management interface connectivity between nodes
4. Verify all nodes on same firmware version
