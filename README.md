# Threat Detection Platform

A SOC home lab that collects real-world attack data from a public-facing honeypot, ingests logs into Splunk SIEM, and triggers real-time Discord alerts.

## Live Results

**4 days of data collected:**
- 15+ unique attackers from 6 countries
- 500+ events indexed in Splunk
- Top attackers: India (76 events), China (69 events), Brazil (17 events), USA (12 events)
- Most common technique: T1082 System Information Discovery

## Architecture
Internet (real attackers)
↓ port 2222
AWS EC2 t2.micro — Cowrie SSH Honeypot (Docker)
↓ Tailscale VPN (ACL: honeypot → Splunk:8088 only)
↓ HEC — every 1 minute via cron
Splunk Enterprise (Windows) ← Ubuntu Apache + Windows Sysmon
↓
Alerts (Discord) + Cowrie Dashboard
## Dashboard

### Top attackers by IP
![Top Attackers](docs/screenshots/top-attackers.png)

### Attack timeline by hour
![Timeline](docs/screenshots/timeline.png)

### Top passwords used by attackers
![Passwords](docs/screenshots/top-passwords.png)

### Top commands executed after login
![Commands](docs/screenshots/top-commands.png)

### Geo map — attack origins
![Geo Map](docs/screenshots/geo-map.png)

### MITRE ATT&CK techniques detected
![MITRE](docs/screenshots/mitre-attack.png)

## Tech Stack

| Category | Technology |
|----------|-----------|
| Cloud | AWS (EC2, S3, IAM, VPC) |
| IaC | Terraform |
| Honeypot | Cowrie SSH (Docker) |
| SIEM | Splunk Enterprise |
| VPN | Tailscale (ACL protected) |
| Alerting | Discord webhooks |
| OS | Ubuntu 22.04 |

## Detection Rules

| Alert | Threshold | Severity |
|-------|-----------|----------|
| SSH Brute Force | >10 attempts/min | Critical |
| Web Scanner | >100 requests/min | High |
| 404 Brute Force | >50 errors/min | High |

## MITRE ATT&CK Coverage

| Technique | ID | Events |
|-----------|-----|--------|
| System Information Discovery | T1082 | 45+ |
| Brute Force: Password Guessing | T1110.001 | 15+ |
| Unsecured Credentials: Private Keys | T1552.004 | 8+ |
| Valid Accounts: Default Credentials | T1078.001 | 3+ |

## Real Attacks Detected

| IP | Country | Attempts | VirusTotal |
|----|---------|----------|-----------|
| 179.124.29.29 | Brazil | 17 | 15/95 Malicious |
| 120.48.162.52 | China | 12 | — |
| 106.13.78.62 | China | 9 | — |
| 183.134.60.14 | China | 5 | — |
| 47.110.244.136 | China | 5 | — |

## Security Hardening

- Tailscale ACL: EC2 sees ONLY Splunk port 8088
- Docker: `--read-only`, `--security-opt no-new-privileges`
- UFW firewall: only ports 22, 2222, 41641 open
- SSH: password auth disabled, root login disabled
- sudo: requires password (NOPASSWD removed)
- Tailscale state: chmod 600 + chattr +i

## Project Structure
├── terraform/          # AWS infrastructure as code
├── splunk/
│   ├── searches/       # SPL detection queries
│   └── dashboards/     # Dashboard JSON definitions
├── scripts/            # Automation scripts
├── playbooks/          # Incident response procedures
└── docs/screenshots/   # Evidence screenshots
## Setup

```bash
cd terraform
terraform init
terraform apply -var="your_ip=$(curl -s ifconfig.me)/32"
```

## Roadmap

- [x] Week 1: Honeypot infrastructure + Splunk integration
- [x] Week 2: Cowrie dashboard + MITRE ATT&CK mapping
- [ ] Week 3: IR Playbooks + CloudTrail integration
- [ ] Week 4: AbuseIPDB reporting + Prometheus monitoring
