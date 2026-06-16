---
description: D3 ITS fiber failover operations — activate/deactivate GRE backup path between RTMC and TLHPSC, check OSPF health, and troubleshoot routing between sites.
---

# D3 ITS Fiber Failover Operations

## Architecture

```
PRODUCTION PATH (2ms, OSPF cost 4):
  chp-core (VE 1000, 10.170.110.1)
    ↔ Hub 10 (VE 1000, 10.170.110.3)
      ↔ TLHPSC-CORE (1/1/2, 10.175.127.1/29)
        → 1800F FortiGate (10.162.254.1)
          → TLHPSC VLTL subnet (10.162.254.0/24)

BACKUP PATH (68ms, OSPF cost 10000):
  chp-core (VE 127, 10.175.127.10)
    ↔ FRR Router (ens256, 10.175.127.9)
      → GRE tunnel (gre-tlhpsc, 172.16.255.1/30)
        → Nebula overlay (100.100.0.3 → 100.100.0.20)
          → LXC 201 (172.16.255.2)
            → TLHPSC VLTL subnet (10.162.254.0/24)
```

## Key IPs

| Device | Interface | IP | Role |
|--------|-----------|------|------|
| chp-core | VE 1000 | 10.170.110.1/29 | OSPF to Hub 10 |
| chp-core | VE 127 | 10.175.127.10/29 | OSPF to FRR router |
| Hub 10 | VE 1000 | 10.170.110.3/29 | OSPF to chp-core |
| Hub 10 | 1/2/1 | 10.175.127.2/29 | OSPF to TLHPSC-CORE |
| TLHPSC-CORE | 1/1/2 | 10.175.127.1/29 | OSPF to Hub 10 |
| TLHPSC-CORE | lag 2 | 10.162.110.2/30 | To 1800F FortiGate |
| FRR Router | ens256 | 10.175.127.9/29 | OSPF to chp-core |
| FRR Router | ens224 | 10.175.252.21/23 | Management/WAN |
| FRR Router | gre-tlhpsc | 172.16.255.1/30 | GRE to TLHPSC |
| FRR Router | defined1 | 100.100.0.3/22 | Nebula overlay |
| LXC 201 | eth0 | 10.162.254.120/24 | TLHPSC LAN |
| LXC 201 | rtmc-gre | 172.16.255.2/30 | GRE from FRR |
| LXC 201 | defined1 | 100.100.0.20/22 | Nebula overlay |
| TLHPSC PVE | LAN | 10.162.254.107 | Proxmox host |
| 1800F (DOTSD3MWFW) | VLTL | 10.162.254.1 | TLHPSC gateway |

## Activate GRE Failover (when fiber is down)

```bash
# On FRR router (10.175.252.21):
ssh kntrnjb@10.175.252.21

# Start the GRE tunnel
sudo systemctl start gre-tlhpsc.service

# Add OSPF redistribution for backup route
sudo vtysh -c "conf t" -c "router ospf" -c "redistribute kernel metric 10000 metric-type 2" -c "end" -c "write memory"

# Verify
sudo vtysh -c "show ip ospf neighbor"
ping -c 3 172.16.255.2  # GRE endpoint
ping -c 3 10.162.254.107  # TLHPSC PVE
```

## Deactivate GRE Failover (when fiber is restored)

```bash
# On FRR router:
ssh kntrnjb@10.175.252.21

# Remove OSPF redistribution FIRST (prevents duplicates)
sudo vtysh -c "conf t" -c "router ospf" -c "no redistribute kernel" -c "end" -c "write memory"

# Wait 60s for LSAs to flush, then stop tunnel
sudo systemctl stop gre-tlhpsc.service

# Verify production path works
ping -c 3 10.162.254.107  # Should be ~2ms via fiber
```

## Quick Health Check

```bash
# Check production OSPF path:
telnet 10.175.52.1  # chp-core
> show ip route 10.162.254.0
# Should show: via 10.170.110.3, ve 1000, cost 110/4, OSPF

# Check TLHPSC-CORE fiber links:
telnet 10.162.110.2  # TLHPSC-CORE
> show interfaces brief ethernet 1/1/1
> show interfaces brief ethernet 1/1/2
> show interfaces brief ethernet 1/1/3
# 1/1/2 should be UP (Hub 10). Others are known dead.

# Check GRE tunnel (if activated):
ssh kntrnjb@10.175.252.21
sudo systemctl status gre-tlhpsc
ping 172.16.255.2
sudo vtysh -c "show ip ospf neighbor"
```

## Troubleshooting

### "No route to 10.162.254.0/24 on chp-core"
1. Check Hub 10 is online: `ping 10.175.51.10`
2. Check TLHPSC-CORE 1/1/2 is up: telnet to 10.162.110.2, `show int brief e 1/1/2`
3. Check OSPF: telnet to 10.175.52.1, `show ip ospf neighbor` — should see Hub 10 (10.175.51.10) on v1000
4. Check TLHPSC-CORE OSPF has `redistribute static`: telnet 10.162.110.2, `show run | include redistribute`
5. If all above OK but no route: check for IP conflicts on 10.175.127.0/29

### "Duplicate ping replies (DUP!)"
Both production and GRE paths are active. Deactivate GRE: remove `redistribute kernel` from FRR OSPF.

### "Nebula tunnel keeps dying (20-second cycle)"
LXC 201 advertising GRE IPs to lighthouses. Check iptables on FRR router:
```bash
sudo iptables -C OUTPUT -o gre-tlhpsc -p udp --dport 40967 -j DROP  # Should exist
sudo iptables -C FORWARD -o gre-tlhpsc -p udp --dport 40967 -j DROP  # Should exist
```

### "SSL/HTTPS times out through GRE but ping works"
FortiGate UTM/SSL inspection breaks tunneled HTTPS. Either bypass UTM for 10.162.254.0/24 traffic or use production fiber path.

### "vCenter hosts NOT_RESPONDING"
1. Verify HTTPS from vCenter: SSH to 10.175.252.238, `curl -sk https://10.162.254.100`
2. If timeout: routing issue (check above)
3. If HTTP 000: MTU/SSL issue (use production path, not GRE)
4. If reachable but still NOT_RESPONDING: reconnect via pyvmomi or vSphere GUI
5. If vAPI errors: restart `vmware-vapi-endpoint` on vCenter appliance

## Ring Status (Known Broken)

TLHPSC-CORE fiber ports — only 1/1/2 is working:
- 1/1/1 (Hub 9 primary): **DEAD 1,001 days** — TransCore maintenance
- 1/1/2 (Hub 10 direct): **UP** — sole production path
- 1/1/3 (Hub 9 secondary): **DEAD 68 days** — TransCore maintenance
- 1/1/6 (Hub 9 alternate): **DARK** — enabled, fiber dead

## Planned Improvements

1. CoT aerial fiber: Hub 9 ↔ TLH City Hall ↔ TLHPSC (call with Jon McFadden pending)
2. Hub 11 + Hub 12 direct home runs to TLHPSC-CORE
3. 20G nonstop bypass: Hub 8 (MM 189) → Hub 10 or TLHPSC-CORE
4. Permanent electrical repair at Hub 10 (fire ants in disconnect)
5. ICX-7850 deployment with 100G multi-path to all 6 DCs
