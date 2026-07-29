# Acceptance Criteria

## Overview

This document defines the production readiness acceptance tests for the Huawei Cloud DNS Domain Resolution Dynamic Management skill.

## 1. Environment Prerequisites

- [ ] hcloud CLI (KooCLI) v7.0+ installed and configured
- [ ] jq installed
- [ ] curl installed
- [ ] dig or nslookup available (optional, for validation)
- [ ] Valid Huawei Cloud credentials (AK/SK or hcloud configure)
- [ ] DNS service enabled in the target region
- [ ] IAM permissions granted (dns:zones:list, dns:recordsets:* etc.)

## 2. Script Syntax Validation

- [ ] `bash -n scripts/config.sh` passes
- [ ] `bash -n scripts/check_env.sh` passes
- [ ] `bash -n scripts/list_zones.sh` passes
- [ ] `bash -n scripts/list_recordsets.sh` passes
- [ ] `bash -n scripts/manage_recordset.sh` passes
- [ ] `bash -n scripts/update_dns.sh` passes
- [ ] `bash -n scripts/validate_dns.sh` passes
- [ ] `bash -n scripts/dns_audit_log.sh` passes

## 3. Functional Acceptance Tests

### 3.1 Environment Check

- [ ] `bash scripts/check_env.sh` exits 0 with all dependencies present
- [ ] `bash scripts/check_env.sh --verbose` shows version information
- [ ] `bash scripts/check_env.sh` exits 1 when hcloud CLI is missing

### 3.2 Zone Listing

- [ ] `bash scripts/list_zones.sh --type public` lists public zones
- [ ] `bash scripts/list_zones.sh --type private` lists private zones
- [ ] `bash scripts/list_zones.sh --type all` lists both public and private zones
- [ ] `bash scripts/list_zones.sh --format json` produces valid JSON output
- [ ] `bash scripts/list_zones.sh --search example` filters zones by name pattern

### 3.3 Record Set Listing

- [ ] `bash scripts/list_recordsets.sh --zone-name <zone>` lists all record sets
- [ ] `bash scripts/list_recordsets.sh --zone-name <zone> --type A` filters by type
- [ ] `bash scripts/list_recordsets.sh --zone-name <zone> --name <name>` filters by name
- [ ] `bash scripts/list_recordsets.sh --zone-name <zone> --format json` produces valid JSON
- [ ] `bash scripts/list_recordsets.sh --zone-name <zone> --zone-type private` works for private zones

### 3.4 Record Set Management

- [ ] Create A record succeeds and record appears in listing
- [ ] Create CNAME record succeeds
- [ ] Create MX record succeeds
- [ ] Create TXT record succeeds
- [ ] Update A record changes the IP value
- [ ] Update with TTL changes the TTL
- [ ] Delete record set removes it from listing
- [ ] Create on private zone succeeds with --zone-type private
- [ ] Duplicate create fails with meaningful error
- [ ] Update non-existent record fails with meaningful error
- [ ] Delete non-existent record fails with meaningful error

### 3.5 Batch Update

- [ ] Failover mode with --dry-run shows preview without changes
- [ ] Failover mode updates all A records matching old-ip to new-ip
- [ ] Switch mode updates specified records to new IP
- [ ] Bluegreen mode applies updates from JSON config file
- [ ] Batch update summary shows correct counts (updated/skipped/failed)
- [ ] All batch operations are logged to audit log

### 3.6 DNS Validation

- [ ] Validate A record with correct expected IP exits 0
- [ ] Validate A record with wrong expected IP exits 1
- [ ] Validate without expected value shows resolved IPs
- [ ] Validate with --dns-server uses specified DNS server
- [ ] Validate with --timeout respects timeout value

### 3.7 Audit Logging

- [ ] Log entry is written in JSONL format
- [ ] Timestamp is timezone-aware (includes +HH:MM offset)
- [ ] Export to CSV produces valid CSV
- [ ] Export to JSON produces valid JSON array
- [ ] Custom --log-dir works correctly

## 4. Security Acceptance

- [ ] No credentials hardcoded in any script
- [ ] No AK/SK passed as command-line arguments
- [ ] Credentials only read from environment variables or hcloud configure
- [ ] No credentials logged in audit logs
- [ ] Scripts use `set -euo pipefail` for safe execution

## 5. Error Handling Acceptance

- [ ] Missing hcloud CLI produces clear error message
- [ ] Invalid credentials produces clear error message
- [ ] Invalid zone name produces clear error message
- [ ] Missing trailing dot in record name produces clear error
- [ ] API rate limiting is handled gracefully
- [ ] Network errors produce meaningful messages

## 6. Output Format Acceptance

- [ ] Text output is human-readable with colors
- [ ] JSON output is valid and parseable by jq
- [ ] JSON output includes metadata (region, timestamp)
- [ ] Error messages go to stderr
- [ ] Normal output goes to stdout

## 7. Documentation Acceptance

- [ ] SKILL.md has valid YAML frontmatter
- [ ] All scripts have --help output
- [ ] All parameters documented in SKILL.md
- [ ] All references files exist and are accurate
- [ ] Examples in SKILL.md are correct
