---
description: Ruckus ICX switch CLI quick-reference — show commands, configuration patterns, firmware upgrades, stacking, troubleshooting, and model differences for ICX7450/7650/7750/8200.
---

# Ruckus ICX CLI Quick Reference

Fleet: ICX7450, ICX7650, ICX7750, ICX8200 | Creds: FDOT / FloridaD0t3 | TFTP: 10.175.252.29 (/srv/tftp/)

## Show Commands

```
show run                              # Full running config
show run interface e 1/1/1            # Single interface config
show interfaces brief                 # All ports — state/speed/duplex one-liner
show interfaces brief wide            # Same with full port names
show interfaces ethernet 1/1/1       # Detailed counters for one port
show ip interface brief               # L3 interfaces with IPs
show vlan                             # All VLANs summary
show vlan <id>                        # Specific VLAN: tagged/untagged ports
show lldp neighbors                   # LLDP neighbor table
show lldp neighbors detail            # LLDP with system description + mgmt IP
show ip ospf neighbor                 # OSPF adjacencies
show ip ospf interface brief          # OSPF-enabled interfaces
show ip route                         # Full routing table
show ip route summary                 # Route count by protocol
show stack                            # Stack topology: unit/role/MAC/priority/state
show stack detail                     # Stack with uptime + firmware per unit
show optic <unit/slot/port>           # SFP/SFP+ optic power (dBm), temp, voltage
show optic all                        # All optics at once (fiber health check)
show mac-address                      # Full MAC table
show mac-address ethernet 1/1/1       # MACs on one port
show mac-address <MAC>                # Find port for a MAC
show cpu                              # 1-second CPU load per process
show cpu histogram                    # CPU histogram (sustained load)
show memory                           # Memory utilization
show log                              # System log buffer
show log | include ERROR              # Filtered log
show flash                            # Boot images + versions in flash
show version                          # Firmware version, uptime, serial, model
show arp                              # ARP table
show ip access-list                   # All ACLs
show statistics ethernet 1/1/1        # Packet/byte/error counters per port
show media ethernet 1/1/1             # SFP type (1G-LX, 10G-SR, etc.)
```

## Configuration Patterns

### VLAN
```
vlan <id> name <NAME>
  tagged ethernet 1/1/1 to 1/1/4      # Trunk ports
  untagged ethernet 1/1/5 to 1/1/24   # Access ports
  router-interface ve <id>             # L3 SVI
!
interface ve <id>
  ip address 10.x.x.1/24
  ip ospf area 0.0.0.0
```

### Interface
```
interface ethernet 1/1/1
  port-name UPLINK-TO-CORE
  speed-duplex 1000-full               # Force speed (or auto)
  inline power                         # PoE enable (7450/7650)
  spanning-tree 802-1w admin-edge-port # RSTP edge
  no spanning-tree 802-1w admin-edge-port  # Remove edge
```

### LAG / Trunk
```
lag <NAME> dynamic id <1-256>
  ports ethernet 1/1/47 to 1/1/48
  primary-port 1/1/47
  deploy                               # Activate LAG
!
vlan <id>
  tagged lag <1-256>                   # Trunk VLAN over LAG
```

### OSPF
```
router ospf
  area 0.0.0.0
  redistribute connected
  redistribute static
!
interface ve <id>
  ip ospf area 0.0.0.0
  ip ospf cost 4                       # Tune path preference
```

### ACL
```
ip access-list extended <NAME>
  permit ip 10.175.0.0/16 any
  deny ip any any log
!
interface ethernet 1/1/1
  ip access-group <NAME> in
```

## Firmware Upgrade

```bash
# 1. Check current version
show version
show flash

# 2. Copy boot ROM (if required by release notes)
copy tftp flash 10.175.252.29 SPR08095.bin bootrom

# 3. Copy primary image
copy tftp flash 10.175.252.29 SPR08095ufi.bin primary

# 4. Set boot preference
boot system flash primary

# 5. Save and reload
write memory
reload                                 # Or: boot system flash primary
```

**Stack upgrade:** firmware propagates to all members automatically after the active controller is upgraded (8.0.70+). Verify with `show stack detail` post-reload.

**UFI note:** Images 08.0.80+ use UFI format. Pre-UFI switches must upgrade to 08.0.80f first.

## Stack Management

```
show stack                             # Unit/role/priority/state
show stack detail                      # Per-unit firmware + uptime
stack unit <id> priority <0-255>       # Higher = more likely active (default 128)
stack unit <old-id> renumber <new-id>  # Renumber (resets unit config!)
stack secure-setup                     # Interactive stack build
stack switch-over                      # Force active->standby failover
```

**Election:** highest priority wins. Tie = lowest MAC. Active controller default priority = 128.

## Troubleshooting

```
show ip route 10.162.254.0            # Check specific route
show ip ospf neighbor                  # OSPF stuck in INIT/2WAY?
show ip ospf database                  # LSA database
show arp 10.x.x.x                     # Resolve IP → MAC
ping 10.x.x.x source 10.y.y.y        # Ping from specific SVI
traceroute 10.x.x.x source 10.y.y.y
show statistics ethernet 1/1/1        # CRC/input errors = bad cable/SFP
show optic 1/1/1                       # Rx power < -24 dBm = fiber issue
show logging                           # Same as show log
show cpu                               # CPU spike diagnosis
show who                               # Active management sessions
clear arp                              # Flush ARP table
clear mac-address                      # Flush MAC table
debug ip ospf packet                   # OSPF debug (use sparingly!)
no debug all                           # Kill all debugs
```

## Model Differences

| Feature | ICX7450 (08.0.x) | ICX7650 (08.0.x/10.x) | ICX7750 (08.0.x) | ICX8200 (10.x only) |
|---------|-------------------|------------------------|-------------------|----------------------|
| Firmware | FastIron 08.0.x | 08.0.x or 10.0.x | FastIron 08.0.x | FastIron 10.0.x only |
| L2/L3 images | Separate SWR/SPR | Separate (08.x) / Unified (10.x) | Separate SWR/SPR | Unified only (no L2-only) |
| Stacking | Yes (rear ports) | Yes (rear/front) | Yes (rear 100G) | Yes |
| PoE | PoE+ (7450-48P) | PoE++ 802.3bt | No | PoE++ 802.3bt |
| Max ports | 48x1G + 4x10G | 48x10G + 6x40G | 48x10G + 6x100G | 48x10/25G + 8x100G |
| RESTCONF | 08.0.80+ | Yes | 08.0.80+ | Yes |
| CLI syntax | Identical core | Identical core | Identical core | Identical core |

**Key gotcha:** ICX8200 runs FastIron 10.x exclusively -- no separate switching image. The `show flash` output and boot commands differ slightly (single image vs primary/secondary). All other CLI commands are syntactically identical across models.

## MCP Tool Mapping

| CLI Task | MCP Tool | Notes |
|----------|----------|-------|
| show version / show stack | `icx_status` | RESTCONF required |
| show interfaces | `icx_interfaces` | |
| show vlan | `icx_vlans` | |
| show lldp neighbors | `icx_lldp` | |
| show ip ospf | `icx_ospf` | |
| show run | `icx_config` | |
| Chassis/SFP detail | `icx_hardware` | |
| Find MAC/VLAN/IP | `icx_find` | Cross-fleet search |
| Config diff | `icx_compare` | Two-switch diff |
| Fleet firmware audit | `icx_fleet_firmware` | |
| VLAN consistency | `icx_fleet_vlans` | |
| SSH/telnet commands | AWX job templates | For non-RESTCONF hubs |
| Out-of-band access | `serial_connect/interact` | Console server |
