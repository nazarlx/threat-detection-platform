# IR Playbook: Access from New/Suspicious Country

## Trigger
Splunk Alert: Login attempt from country not in whitelist

## Severity
Medium

## Investigation Steps

### Step 1 — Identify country of origin
```spl
index=main sourcetype=cowrie
| rex field=_raw "\[HoneyPotSSHTransport,\d+,(?<src_ip>\d+\.\d+\.\d+\.\d+)\]"
| where isnotnull(src_ip)
| stats count by src_ip
| iplocation src_ip
| table src_ip, count, Country, City
| sort -count
```

### Step 2 — Check if login succeeded
```spl
index=main sourcetype=cowrie
| rex field=_raw "login attempt \[b'(?<username>[^']+)'/b'(?<password>[^']+)'\] (?<result>succeeded|failed)"
| where result="succeeded"
| table _time, username, password, result
```

### Step 3 — MITRE ATT&CK Mapping
| Technique | ID |
|-----------|-----|
| Valid Accounts | T1078 |
| Default Credentials | T1078.001 |
| Brute Force | T1110 |

### Step 4 — Response
- Verify if IP is in any threat intelligence feeds
- Check VirusTotal and AbuseIPDB
- For production: implement geo-blocking if needed
- Document for threat intelligence

## High Risk Countries (based on honeypot data)
| Country | Events | Risk |
|---------|--------|------|
| India | 76 | High |
| China | 69 | High |
| Brazil | 17 | Medium |
| UAE | 11 | High |
