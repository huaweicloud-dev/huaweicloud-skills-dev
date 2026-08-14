---
id: huawei-cloud-dns-managemengt
name: huawei-cloud-dns-managemengt
tags: [huawei-cloud, dns, domain-resolution, record-set, zone-management, dynamic-update, automation]
description: |
  Huawei Cloud DNS domain resolution dynamic management skill using hcloud CLI (KooCLI).
  1. List and query DNS zones (public/private) and record sets with detailed status
  2. Create, update, and delete DNS record sets for dynamic domain resolution management
  3. Batch update DNS records for failover, traffic switching, and blue-green deployments
  4. Generate DNS resolution audit logs and change history reports
  5. Validate DNS resolution and verify record propagation
  6. Support A, AAAA, CNAME, MX, TXT, NS, SRV, CAA record types
  Triggers include: "DNS management", "DNS record update", "domain resolution", "zone query", "record set create", "record set delete", "DNS failover", "traffic switch", "blue-green DNS", "DNS audit", "DNS 验证", "域名解析管理", "DNS 记录更新", "域名解析", "Zone 查询", "记录集创建", "记录集删除", "DNS 故障切换", "流量切换", "蓝绿 DNS", "DNS 审计"
---

# Huawei Cloud DNS Domain Resolution Dynamic Management

## Overview

This skill provides comprehensive DNS domain resolution dynamic management capabilities for Huawei Cloud DNS service. It enables automated DNS record management for scenarios like failover, traffic switching, blue-green deployments, and dynamic IP updates.

**Architecture**: Shell + hcloud CLI (KooCLI) → DNS Service API → Zone/RecordSet resources

**Core Capabilities**:

- List and query DNS zones (public/private) and record sets
- Create, update, and delete DNS record sets dynamically
- Batch update DNS records for failover and traffic switching
- DNS resolution validation and propagation verification
- Operation audit logging for compliance
- Support for all standard record types (A, AAAA, CNAME, MX, TXT, NS, SRV, CAA)

**Typical Use Cases**:

- "Help me update the A record for www.example.com to point to a new IP"
- "List all DNS zones in my account"
- "Switch DNS traffic from the primary server to the backup server"
- "Create a new CNAME record for api.example.com pointing to lb.example.com"
- "Delete the TXT record for old-verification.example.com"
- "Show all record sets in the example.com zone"
- "Batch update DNS records for blue-green deployment"
- "Validate DNS resolution for www.example.com"
- "Generate a DNS change audit report"

## Prerequisites

### 1. CLI Environment Requirements (MANDATORY)

- **hcloud CLI (KooCLI)** v7.0+ — Huawei Cloud command-line tool
- **jq** — JSON processor for parsing API responses
- **curl** — HTTP client for DNS resolution validation
- **dig** (optional) — DNS lookup tool for resolution verification
- **nslookup** (optional) — DNS lookup alternative

**Install hcloud CLI**:

```bash
# Linux/macOS one-click install
curl -sSL https://hwcloudcli.obs.cn-north-1.myhuaweicloud.com/cli/latest/hcloud_install.sh | bash

# Verify installation
hcloud --version
```

**Install jq, curl, dig**:

```bash
# Ubuntu/Debian
sudo apt install -y jq curl dnsutils

# CentOS/RHEL
sudo yum install -y jq curl bind-utils

# macOS
brew install jq curl bind
```

**Available Shell Scripts**:

- `scripts/config.sh` - Shared configuration (credentials, regions, proxy)
- `scripts/list_zones.sh` - List all DNS zones (public/private) with filtering
- `scripts/list_recordsets.sh` - List and query record sets in a zone
- `scripts/manage_recordset.sh` - Create, update, or delete a single record set
- `scripts/update_dns.sh` - Batch update DNS records for failover/traffic switching
- `scripts/validate_dns.sh` - Validate DNS resolution and verify propagation
- `scripts/dns_audit_log.sh` - Operation audit logging (JSONL + CSV/JSON export)
- `scripts/check_env.sh` - Environment check and validation (hcloud CLI + tools + API)

### 2. Authentication Configuration

This skill supports **one authentication path** via environment variables:

#### Environment Variables

```bash
export HW_ACCESS_KEY=<your-ak>
export HW_SECRET_KEY=<your-sk>
export HW_REGION_NAME=cn-north-4
```

> **Note**: If you have already configured `hcloud configure` interactively (entering credentials via prompts, not command-line arguments), the skill will also detect and use those credentials.

**Environment Variables**:

| Variable | Required | Description |
|----------|----------|-------------|
| `HW_ACCESS_KEY` | Optional | Huawei Cloud Access Key ID (required only if hcloud configure not set) |
| `HW_SECRET_KEY` | Optional | Huawei Cloud Secret Access Key (required only if hcloud configure not set) |
| `HW_REGION_NAME` | Optional | Default region (default: `cn-north-4`) |
| `HW_SECURITY_TOKEN` | Optional | Security token for temporary credentials |

**Security Notes**:

- Never commit credentials to version control
- Never expose AK/SK values in code, conversation, or commands
- Never pass AK/SK values as command-line arguments (exposes credentials in shell history and `ps aux`)
- Use IAM users with minimal required permissions
- Enable MFA for sensitive operations
- Rotate AK/SK regularly
- Use `./scripts/check_env.sh` to validate credentials before running scripts

### 3. Quick Start

```bash
# Step 1: Configure authentication via environment variables
export HW_ACCESS_KEY=<your-ak>
export HW_SECRET_KEY=<your-sk>
export HW_REGION_NAME=cn-north-4

# Step 2: Run environment check
bash scripts/check_env.sh

# Step 3: List DNS zones
bash scripts/list_zones.sh --type public

# Step 4: List record sets in a zone
bash scripts/list_recordsets.sh --zone-name example.com.

# Step 5: Update an A record
bash scripts/manage_recordset.sh --action update \
  --zone-name example.com. \
  --name www.example.com. \
  --type A \
  --records "192.168.1.100"

# Step 6: Validate DNS resolution
bash scripts/validate_dns.sh --domain www.example.com --expected-ip 192.168.1.100
```

### 4. IAM Permission Requirements

| API Action | Permission | Purpose |
|------------|-----------|---------|
| `dns:zones:list` | List zones | Query all DNS zones |
| `dns:zones:get` | Get zone details | View individual zone information |
| `dns:recordsets:list` | List record sets | Query all record sets in a zone |
| `dns:recordsets:get` | Get record set | View individual record set details |
| `dns:recordsets:create` | Create record set | Create new DNS records |
| `dns:recordsets:update` | Update record set | Modify existing DNS records |
| `dns:recordsets:delete` | Delete record set | Remove DNS records |
| `dns:lines:list` | List lines | Query available resolution lines |

## Workflow

### Main Steps
1. **Environment Check** → Verify hcloud CLI, jq, credentials
2. **Zone Query** → List DNS zones via hcloud CLI
3. **Record Set Management** → Create, update, or delete DNS records
4. **Batch Operations** → Failover, traffic switching, blue-green deployment
5. **Validation** → Verify DNS resolution and propagation
6. **Audit Logging** → Record operations for compliance

### Zone Query Workflow
List DNS zones (public/private), filter by type, output as JSON/table.

### Record Set Management Workflow
Create, update, or delete individual DNS record sets with support for all record types.

### Batch Update Workflow
Update multiple DNS records simultaneously for failover, traffic switching, or blue-green deployments.

### DNS Validation Workflow
Verify DNS resolution using dig/nslookup and compare against expected values.

### Audit Log Workflow
Record all DNS operations (list/create/update/delete/validate) to audit log file for compliance.

All DNS operations use hcloud CLI commands:

| Operation | hcloud CLI Command | Description |
|-----------|-------------------|-------------|
| List zones | `hcloud DNS ListPublicZones` / `hcloud DNS ListPrivateZones` | List DNS zones |
| Show zone | `hcloud DNS ShowPublicZone` / `hcloud DNS ShowPrivateZone` | Get zone details |
| List record sets | `hcloud DNS ListRecordSets` / `hcloud DNS ListPrivateRecordSets` | List records in a zone |
| Create record set | `hcloud DNS CreateRecordSet` / `hcloud DNS CreatePrivateRecordSet` | Create a DNS record |
| Update record set | `hcloud DNS UpdateRecordSet` / `hcloud DNS UpdatePrivateRecordSet` | Update a DNS record |
| Delete record set | `hcloud DNS DeleteRecordSet` / `hcloud DNS DeletePrivateRecordSet` | Delete a DNS record |
| Show record set | `hcloud DNS ShowRecordSet` / `hcloud DNS ShowPrivateRecordSet` | Get record details |

**Output format**: All commands use `--cli-output=json` for machine-readable output, parsed by `jq`.

## Core Commands

| Command | Description | Backend |
|---------|-------------|---------|
| `list_zones.sh` | List and query DNS zones | hcloud CLI |
| `list_recordsets.sh` | List and query record sets in a zone | hcloud CLI |
| `manage_recordset.sh` | Create, update, or delete a record set | hcloud CLI |
| `update_dns.sh` | Batch update DNS records for failover/switching | hcloud CLI |
| `validate_dns.sh` | Validate DNS resolution and propagation | dig/nslookup/curl |
| `dns_audit_log.sh` | Maintain operation audit logs | Shell |
| `check_env.sh` | Verify environment prerequisites | Shell |
| `config.sh` | Load configuration and credentials | Shell |

### List DNS Zones

```bash
# List all public zones
bash scripts/list_zones.sh --type public

# List all private zones
bash scripts/list_zones.sh --type private

# List all zones (both public and private)
bash scripts/list_zones.sh --type all

# Search zones by name pattern
bash scripts/list_zones.sh --type public --search example

# JSON output
bash scripts/list_zones.sh --type public --format json
```

### List Record Sets

```bash
# List all record sets in a zone
bash scripts/list_recordsets.sh --zone-name example.com.

# Filter by record type
bash scripts/list_recordsets.sh --zone-name example.com. --type A

# Search by name pattern
bash scripts/list_recordsets.sh --zone-name example.com. --search www

# Show a specific record set
bash scripts/list_recordsets.sh --zone-name example.com. --name www.example.com. --type A

# JSON output
bash scripts/list_recordsets.sh --zone-name example.com. --format json

# Private zone record sets
bash scripts/list_recordsets.sh --zone-name example.com. --zone-type private
```

### Manage Record Set (Create / Update / Delete)

```bash
# Create an A record
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name www.example.com. \
  --type A \
  --records "192.168.1.100"

# Create an A record with multiple IPs (round-robin)
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name app.example.com. \
  --type A \
  --records "192.168.1.100 192.168.1.101 192.168.1.102"

# Create a CNAME record
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name api.example.com. \
  --type CNAME \
  --records "lb.example.com."

# Create an MX record
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name example.com. \
  --type MX \
  --records "10 mail.example.com."

# Create a TXT record
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name verify.example.com. \
  --type TXT \
  --records "\"verification-token-12345\""

# Update an existing A record (changes the IP)
bash scripts/manage_recordset.sh --action update \
  --zone-name example.com. \
  --name www.example.com. \
  --type A \
  --records "192.168.2.200"

# Delete a record set
bash scripts/manage_recordset.sh --action delete \
  --zone-name example.com. \
  --name old.example.com. \
  --type A

# Private zone operations
bash scripts/manage_recordset.sh --action create \
  --zone-name internal.example.com. \
  --name app.internal.example.com. \
  --type A \
  --records "10.0.1.100" \
  --zone-type private

# TTL customization
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name www.example.com. \
  --type A \
  --records "192.168.1.100" \
  --ttl 300
```

### Batch Update DNS (Failover / Traffic Switching)

```bash
# Failover: switch all A records in a zone from old IP to new IP
bash scripts/update_dns.sh --mode failover \
  --zone-name example.com. \
  --old-ip 192.168.1.100 \
  --new-ip 192.168.2.200

# Traffic switching: update specific records to new IP
bash scripts/update_dns.sh --mode switch \
  --zone-name example.com. \
  --names "www.example.com. api.example.com. app.example.com." \
  --type A \
  --new-ip 192.168.2.200

# Blue-green deployment: update records with a JSON config file
bash scripts/update_dns.sh --mode bluegreen \
  --config-file ./dns-update-config.json

# Dry run (preview changes without applying)
bash scripts/update_dns.sh --mode failover \
  --zone-name example.com. \
  --old-ip 192.168.1.100 \
  --new-ip 192.168.2.200 \
  --dry-run
```

**Batch Update Config File Format** (JSON):

```json
{
  "zone_name": "example.com.",
  "zone_type": "public",
  "updates": [
    {
      "name": "www.example.com.",
      "type": "A",
      "records": ["192.168.2.200"],
      "ttl": 300
    },
    {
      "name": "api.example.com.",
      "type": "CNAME",
      "records": ["new-lb.example.com."],
      "ttl": 600
    }
  ]
}
```

### DNS Resolution Validation

```bash
# Validate A record resolution
bash scripts/validate_dns.sh --domain www.example.com --type A --expected-ip 192.168.1.100

# Validate CNAME resolution
bash scripts/validate_dns.sh --domain api.example.com --type CNAME --expected-value lb.example.com.

# Validate without expected value (just check resolution works)
bash scripts/validate_dns.sh --domain www.example.com --type A

# Validate using specific DNS server
bash scripts/validate_dns.sh --domain www.example.com --type A --dns-server 8.8.8.8

# Validate with timeout
bash scripts/validate_dns.sh --domain www.example.com --type A --timeout 10
```

### Environment Check

```bash
# Full environment validation (CLI + tools + API)
bash scripts/check_env.sh

# Verbose mode (show versions)
bash scripts/check_env.sh --verbose

# Auto-fix missing dependencies
bash scripts/check_env.sh --fix
```

### Operation Audit Logging

```bash
# Log a DNS list operation
bash scripts/dns_audit_log.sh --action list --detail "Queried all public zones"

# Log a record update operation
bash scripts/dns_audit_log.sh --action update \
  --detail "Updated A record www.example.com. from 192.168.1.100 to 192.168.2.200"

# Export audit logs to CSV
bash scripts/dns_audit_log.sh --action list --export csv

# Export audit logs to JSON
bash scripts/dns_audit_log.sh --action list --export json

# Custom log directory
bash scripts/dns_audit_log.sh --action list --log-dir /var/log/dns_audit
```

**Audit Log Entry Format** (JSONL, timezone-aware timestamps):

```json
{
  "timestamp": "2026-07-29T10:30:00+08:00",
  "region": "cn-north-4",
  "action": "update",
  "detail": "Updated A record www.example.com. from 192.168.1.100 to 192.168.2.200",
  "user": "root"
}
```

## KooCLI Command Format

```bash
# General format
hcloud <Service> <Operation> --cli-region=<region> --param1=value1 --param2=value2

# List public zones example
hcloud DNS ListPublicZones --cli-region=cn-north-4

# List record sets example
hcloud DNS ListRecordSets --zone_id=<zone-id> --cli-region=cn-north-4

# Create record set example
hcloud DNS CreateRecordSet --zone_id=<zone-id> --name=www.example.com. --type=A --records=192.168.1.100 --ttl=300 --cli-region=cn-north-4
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Uppercase PascalCase | `DNS`, `IAM` |
| Operation name | PascalCase | `ListPublicZones`, `CreateRecordSet` |
| Region param | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple param | `--key=value` | `--zone_id=xxx` |
| Output format | `--cli-output=json` | JSON output for programmatic parsing |

## Parameters

### Shell Script Parameters

| Script | Parameter | Required/Optional | Description | Default |
|--------|-----------|-------------------|-------------|---------|
| `list_zones.sh` | `--type` | Optional | Zone type: public/private/all | `all` |
| `list_zones.sh` | `--search` | Optional | Search by name pattern | - |
| `list_zones.sh` | `--format` | Optional | Output format: text/json | `text` |
| `list_recordsets.sh` | `--zone-name` | Required | Zone name (FQDN with trailing dot) | - |
| `list_recordsets.sh` | `--zone-type` | Optional | Zone type: public/private | `public` |
| `list_recordsets.sh` | `--type` | Optional | Filter by record type (A/AAAA/CNAME/MX/TXT/NS/SRV/CAA) | All |
| `list_recordsets.sh` | `--name` | Optional | Filter by record set name | - |
| `list_recordsets.sh` | `--search` | Optional | Search by name pattern | - |
| `list_recordsets.sh` | `--format` | Optional | Output format: text/json | `text` |
| `manage_recordset.sh` | `--action` | Required | Action: create/update/delete | - |
| `manage_recordset.sh` | `--zone-name` | Required | Zone name (FQDN with trailing dot) | - |
| `manage_recordset.sh` | `--zone-type` | Optional | Zone type: public/private | `public` |
| `manage_recordset.sh` | `--name` | Required | Record set name (FQDN with trailing dot) | - |
| `manage_recordset.sh` | `--type` | Required | Record type (A/AAAA/CNAME/MX/TXT/NS/SRV/CAA) | - |
| `manage_recordset.sh` | `--records` | Required* | Space-separated record values (*required for create/update) | - |
| `manage_recordset.sh` | `--ttl` | Optional | TTL in seconds | `300` |
| `update_dns.sh` | `--mode` | Required | Update mode: failover/switch/bluegreen | - |
| `update_dns.sh` | `--zone-name` | Required* | Zone name (*required for failover/switch) | - |
| `update_dns.sh` | `--zone-type` | Optional | Zone type: public/private | `public` |
| `update_dns.sh` | `--old-ip` | Required* | Old IP to replace (*required for failover) | - |
| `update_dns.sh` | `--new-ip` | Required* | New IP to set (*required for failover/switch) | - |
| `update_dns.sh` | `--names` | Required* | Space-separated record names (*required for switch) | - |
| `update_dns.sh` | `--type` | Optional | Record type for switch mode | `A` |
| `update_dns.sh` | `--config-file` | Required* | JSON config file path (*required for bluegreen) | - |
| `update_dns.sh` | `--dry-run` | Optional | Preview changes without applying | `false` |
| `validate_dns.sh` | `--domain` | Required | Domain to validate | - |
| `validate_dns.sh` | `--type` | Optional | Record type to check | `A` |
| `validate_dns.sh` | `--expected-ip` | Optional | Expected IP address | - |
| `validate_dns.sh` | `--expected-value` | Optional | Expected record value | - |
| `validate_dns.sh` | `--dns-server` | Optional | DNS server to query | System default |
| `validate_dns.sh` | `--timeout` | Optional | Query timeout in seconds | `5` |
| `check_env.sh` | `--verbose` | Optional | Show detailed check info | `false` |
| `check_env.sh` | `--fix` | Optional | Auto-fix missing dependencies | `false` |
| `dns_audit_log.sh` | `--action` | Required | Operation type (list/create/update/delete/validate/batch) | - |
| `dns_audit_log.sh` | `--detail` | Optional | Operation detail description | - |
| `dns_audit_log.sh` | `--export` | Optional | Export format: csv/json | - |
| `dns_audit_log.sh` | `--log-dir` | Optional | Log directory path | `./dns_audit_logs` |

### Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `HW_ACCESS_KEY` | Optional* | Huawei Cloud AK (required only if hcloud configure not set) | - |
| `HW_SECRET_KEY` | Optional* | Huawei Cloud SK (required only if hcloud configure not set) | - |
| `HW_REGION_NAME` | Optional | Default region | `cn-north-4` |
| `HW_SECURITY_TOKEN` | Optional | Temporary credential token | - |

*\*When `hcloud configure` is already set up, `HW_ACCESS_KEY` and `HW_SECRET_KEY` are not needed. Environment variables take precedence when both are configured.*

## Output Format

### Zone List Output

```text
========================================
Huawei Cloud DNS Zone List (Type: public)
========================================
[1] example.com.
    Zone ID:      xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Status:       ACTIVE
    Record Count: 15
    TTL:          300
    Created:      2026-07-01T10:00:00Z
========================================
Total: 1 public zone(s)
```

### Record Set List Output

```text
========================================
DNS Record Sets (Zone: example.com.)
========================================
[1] www.example.com.
    Type:    A
    TTL:     300
    Records: 192.168.1.100
    Status:  ACTIVE
[2] api.example.com.
    Type:    CNAME
    TTL:     300
    Records: lb.example.com.
    Status:  ACTIVE
========================================
Total: 2 record set(s)
```

### Batch Update Output

```text
========================================
DNS Batch Update (Mode: failover)
Zone: example.com.
========================================
[1] www.example.com. (A)
    Old: 192.168.1.100 → New: 192.168.2.200  ✅ Updated
[2] api.example.com. (A)
    Old: 192.168.1.100 → New: 192.168.2.200  ✅ Updated
========================================
Summary: 2 updated, 0 skipped, 0 failed
```

## Verification

### Environment Compliance Check

```bash
# Run full environment check (CLI + tools + API)
bash scripts/check_env.sh

# Exit codes:
#   0 - All checks passed
#   1 - Missing dependencies or API errors
```

### DNS Resolution Validation

```bash
# Validate that a record resolves to the expected value
bash scripts/validate_dns.sh --domain www.example.com --type A --expected-ip 192.168.1.100

# Exit codes:
#   0 - DNS resolution matches expected value
#   1 - Resolution mismatch or validation failed
```

## Best Practices

1. **Use Shell Scripts EXCLUSIVELY**: All scripts are Shell + hcloud CLI. No Python SDK dependency.
2. **Always Use FQDN**: DNS record names must be Fully Qualified Domain Names with trailing dot (e.g., `www.example.com.`)
3. **Dry Run First**: Use `--dry-run` with batch operations to preview changes before applying
4. **Validate After Update**: Always run `validate_dns.sh` after updating DNS records to confirm propagation
5. **Audit Logging**: Enable audit logging for all DNS operations using `dns_audit_log.sh`
6. **Low TTL for Dynamic Records**: Use TTL of 60-300 seconds for records that may need rapid changes (failover, traffic switching)
7. **Environment Validation**: Always run `check_env.sh` first to verify hcloud CLI and dependencies
8. **Backup Before Batch Updates**: Export current record sets before batch operations for rollback capability
9. **Multi-Region Awareness**: DNS zones are global, but private zones are region-specific
10. **Record Type Validation**: Ensure record values match the expected format for each type (e.g., IP for A, FQDN for CNAME)

## References

| Document | Description |
|----------|-------------|
| [IAM Permission Policies](references/iam-policies.md) | Required permissions and policy JSON |
| [DNS API Guide](references/dns-api-guide.md) | DNS API reference (hcloud CLI) |
| [CLI Installation Guide](references/cli-installation-guide.md) | hcloud CLI install, configure, troubleshoot |
| [Verification Method](references/verification-method.md) | Step-by-step verification |
| [Acceptance Criteria](references/acceptance-criteria.md) | Production readiness acceptance tests |

## Notes

- **DNS zones are global resources** — public zones are accessible from all regions; private zones are region-specific.
- **Record names must be FQDN** — always include the trailing dot (e.g., `www.example.com.` not `www.example.com`).
- **TTL affects propagation speed** — lower TTL means faster propagation but more DNS queries. Use 60-300s for dynamic records.
- **Batch operations are not atomic** — if one record update fails, previous updates are not rolled back. Use `--dry-run` first.
- **DNS propagation takes time** — after updating a record, propagation may take up to TTL seconds globally. Use `validate_dns.sh` to check.
- **AK/SK must never be hardcoded** — credentials should only be obtained via environment variables (`HW_ACCESS_KEY`, `HW_SECRET_KEY`) or `hcloud configure` interactive mode.
- **hcloud CLI is the only supported method** — all scripts use hcloud CLI (KooCLI) natively.
- **Authentication**: Use environment variables (`HW_ACCESS_KEY`, `HW_SECRET_KEY`) as the primary method. If `hcloud configure` is already set up interactively, the skill will detect and use those credentials. Never pass credentials as command-line arguments.
- **Temporary Credentials Supported**: This skill supports temporary AK/SK+Token obtained via IAM STS. Set `HW_SECURITY_TOKEN` when using temporary credentials.
- **Environment Variable Standard**: Uses `HW_*` prefix for consistency with other Huawei Cloud skills.
- **jq is required** for all scripts that parse hcloud CLI JSON output.
- **Audit log timestamps are timezone-aware** — format `YYYY-MM-DDTHH:MM:SS+HH:MM` (e.g., `+08:00`), not misleading `Z` suffix.
- **Private zones require VPC association** — private zones must be associated with a VPC to be effective. This skill manages records but does not handle VPC association.

## Common Pitfalls

| Pitfall | Symptom | Quick Fix |
|---------|---------|-----------|
| hcloud not installed | `command not found: hcloud` | Install KooCLI |
| jq not installed | JSON parse errors | `sudo apt install jq` |
| AK/SK not set | API 401 / credential error | Export `HW_ACCESS_KEY`/`HW_SECRET_KEY` or configure `hcloud` interactively |
| Wrong region | `❌ API 返回异常` | Use valid region ID (e.g., `cn-north-4`) |
| Missing trailing dot | Record creation fails | Use FQDN with trailing dot: `www.example.com.` |
| Zone not found | `❌ 未找到 Zone` | Verify zone name is correct and includes trailing dot |
| Record set already exists | Create fails with conflict | Use `--action update` instead of `--action create` |
| Record set not found | Update/delete fails | Verify record name and type match exactly |
| Invalid record value | API validation error | Check value format matches record type (IP for A, FQDN for CNAME, etc.) |
| DNS propagation delay | Validation fails immediately | Wait for TTL seconds and retry validation |
| API rate limit | `429 Too Many Requests` | Add delay between calls |
