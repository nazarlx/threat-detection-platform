# Automated Threat Detection Platform

A SOC home lab that collects real-world attack data from a public-facing honeypot and simulated attacks, ingests logs into Splunk SIEM, and triggers real-time Discord alerts.

## Architecture





## Tech Stack

- **Cloud:** AWS (EC2, S3, IAM, VPC) — Terraform
- **Honeypot:** Cowrie SSH honeypot in Docker
- **SIEM:** Splunk Enterprise with Add-on for AWS
- **Local lab:** Ubuntu (Apache), Windows (Sysmon), Kali (attacks)
- **Alerting:** Discord webhooks via Python script

## Detection Rules

| Alert | Description | Severity |
|-------|-------------|----------|
| SSH Brute Force | >10 failed SSH attempts/min | Critical |
| Web Scanner | >100 requests/min from single IP | High |
| 404 Brute Force | >50 404 errors/min | High |

## Real Attacks Detected

Within hours of deployment, real attackers found the honeypot:
- `20.64.105.196` (Microsoft Azure) — automated SSH scanner

## Project Structure
├── terraform/          # AWS infrastructure as code
├── splunk/
│   ├── searches/       # SPL detection queries
│   └── dashboards/     # Dashboard definitions
├── scripts/            # Automation scripts
├── playbooks/          # Incident response procedures
└── docs/screenshots/   # Evidence screenshots
## Setup

```bash
cd terraform
terraform init
terraform apply
```

## Week 1 — Completed
- [x] Cowrie honeypot on AWS EC2 via Terraform
- [x] S3 log pipeline with IAM role
- [x] Splunk Add-on for AWS (Incremental S3 input)
- [x] 3 detection alerts with Discord notifications
- [x] Web Security Dashboard

## Week 2 — In Progress
- [ ] Cowrie attack dashboard (geo map, top passwords)
- [ ] AWS CloudTrail integration
- [ ] MITRE ATT&CK mapping
