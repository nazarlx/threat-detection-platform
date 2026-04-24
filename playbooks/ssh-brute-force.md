# IR Playbook: SSH Brute Force Detection

## Trigger
Splunk Alert: >10 failed SSH attempts per minute from single IP

## Severity
Critical

## Real Example
**Date:** 2026-04-24
**IP:** 31.56.209.39 (UAE - Swissnet LLC)
**VirusTotal:** 11/94 malicious
**Action:** Login with empty password → Docker escape attempt via /proc/1/mounts

## Investigation Steps

### Step 1 — Identify scope
```spl
index=main sourcetype=cowrie
| rex field=_raw "\[HoneyPotSSHTransport,\d+,(?<src_ip>\d+\.\d+\.\d+\.\d+)\]"
| where src_ip="ATTACKER_IP"
| table _time, _raw
| sort _time
```

### Step 2 — Check threat intelligence
- VirusTotal: https://virustotal.com/gui/ip-address/ATTACKER_IP
- AbuseIPDB: https://abuseipdb.com/check/ATTACKER_IP
- IPsum: https://github.com/stamparm/ipsum

### Step 3 — Check commands executed
```spl
index=main sourcetype=cowrie
| rex field=_raw "CMD: (?<command>.+)"
| where isnotnull(command)
| table _time, command
| sort _time
```

### Step 4 — MITRE ATT&CK Mapping
| Technique | ID |
|-----------|-----|
| Brute Force: Password Guessing | T1110.001 |
| System Information Discovery | T1082 |
| Container Escape | T1611 |

### Step 5 — Response
- Honeypot: document and monitor — do NOT block
- Production: block IP in AWS Security Group immediately
- Report to AbuseIPDB
- Add to threat intelligence watchlist

## Escalation Criteria
- Successful login detected → Critical
- Malware download attempt → Critical
- Container escape attempt → Critical
