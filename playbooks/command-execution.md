# IR Playbook: Command Execution After Login

## Trigger
Splunk Alert: Commands executed after successful SSH login

## Severity
High

## Real Example
**Date:** 2026-04-24
**IP:** 31.56.209.39
**Commands:**
- `echo "cat /proc/1/mounts && ls /proc/1/; curl2; ps aux; ps" | sh`
- `cat /proc/1/mounts` — container detection
- `ps aux` — process enumeration
- `curl2` — malware download attempt

## Investigation Steps

### Step 1 — Get all commands from attacker
```spl
index=main sourcetype=cowrie
| rex field=_raw "\[HoneyPotSSHTransport,\d+,(?<src_ip>\d+\.\d+\.\d+\.\d+)\]"
| rex field=_raw "CMD: (?<command>.+)"
| where isnotnull(command) AND src_ip="ATTACKER_IP"
| table _time, src_ip, command
| sort _time
```

### Step 2 — Identify attack stage
| Command | Stage | MITRE |
|---------|-------|-------|
| uname -a | Reconnaissance | T1082 |
| cat /proc/1/mounts | Container detection | T1611 |
| ps aux | Process discovery | T1057 |
| curl/wget URL | Malware download | T1105 |
| cat /etc/passwd | Credential access | T1003 |

### Step 3 — Check for downloads
```spl
index=main sourcetype=cowrie
| rex field=_raw "CMD: (?<command>.+)"
| where match(command, "curl|wget|tftp|nc")
| table _time, command
```

### Step 4 — Response
- Capture full session log from Cowrie
- Document all commands for threat intelligence
- If malware URL found → submit to VirusTotal
- Report IP to AbuseIPDB
