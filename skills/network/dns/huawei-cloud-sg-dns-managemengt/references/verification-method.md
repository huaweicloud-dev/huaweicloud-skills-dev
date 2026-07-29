# Verification Method

## Overview

This document provides step-by-step verification procedures for the Huawei Cloud DNS Domain Resolution Dynamic Management skill.

## 1. Environment Verification

### Step 1: Run Environment Check

```bash
bash scripts/check_env.sh --verbose
```

**Expected Output**: All checks pass with ✅, no ❌ failures.

### Step 2: Verify hcloud CLI

```bash
hcloud --version
```

**Expected**: Version 7.0+ displayed.

### Step 3: Verify jq

```bash
jq --version
```

**Expected**: Version 1.6+ displayed.

### Step 4: Verify API Connectivity

```bash
hcloud DNS ListPublicZones --cli-region=cn-north-4 --cli-output=json
```

**Expected**: JSON response with zones array (may be empty if no zones exist).

## 2. Zone Query Verification

### Step 1: List Public Zones

```bash
bash scripts/list_zones.sh --type public
```

**Expected**: Table output with zone names, IDs, and status.

### Step 2: List All Zones

```bash
bash scripts/list_zones.sh --type all
```

**Expected**: Both public and private zones listed.

### Step 3: JSON Output

```bash
bash scripts/list_zones.sh --type public --format json
```

**Expected**: Valid JSON with `zones` array, `count`, `region`, and `timestamp` fields.

## 3. Record Set Query Verification

### Step 1: List Record Sets

```bash
bash scripts/list_recordsets.sh --zone-name example.com.
```

**Expected**: Table output with record names, types, TTL, and values.

### Step 2: Filter by Type

```bash
bash scripts/list_recordsets.sh --zone-name example.com. --type A
```

**Expected**: Only A records displayed.

## 4. Record Set Management Verification

### Step 1: Create a Test Record

```bash
bash scripts/manage_recordset.sh --action create \
  --zone-name example.com. \
  --name test-verify.example.com. \
  --type A \
  --records "192.168.99.99" \
  --ttl 60
```

**Expected**: ✅ Success message with record set ID.

### Step 2: Verify Creation

```bash
bash scripts/list_recordsets.sh --zone-name example.com. --name test-verify.example.com. --type A
```

**Expected**: Record set shown with IP 192.168.99.99.

### Step 3: Update the Record

```bash
bash scripts/manage_recordset.sh --action update \
  --zone-name example.com. \
  --name test-verify.example.com. \
  --type A \
  --records "192.168.99.100"
```

**Expected**: ✅ Success message.

### Step 4: Verify Update

```bash
bash scripts/list_recordsets.sh --zone-name example.com. --name test-verify.example.com. --type A
```

**Expected**: IP changed to 192.168.99.100.

### Step 5: Delete the Test Record

```bash
bash scripts/manage_recordset.sh --action delete \
  --zone-name example.com. \
  --name test-verify.example.com. \
  --type A
```

**Expected**: ✅ Success message.

### Step 6: Verify Deletion

```bash
bash scripts/list_recordsets.sh --zone-name example.com. --name test-verify.example.com. --type A
```

**Expected**: No matching record set found.

## 5. Batch Update Verification

### Step 1: Dry Run

```bash
bash scripts/update_dns.sh --mode failover \
  --zone-name example.com. \
  --old-ip 192.168.1.100 \
  --new-ip 192.168.2.200 \
  --dry-run
```

**Expected**: Preview of changes without actual modification.

### Step 2: Execute Failover

```bash
bash scripts/update_dns.sh --mode failover \
  --zone-name example.com. \
  --old-ip 192.168.1.100 \
  --new-ip 192.168.2.200
```

**Expected**: Summary showing records updated.

## 6. DNS Resolution Validation

### Step 1: Validate A Record

```bash
bash scripts/validate_dns.sh --domain www.example.com --type A --expected-ip 192.168.1.100
```

**Expected**: ✅ DNS resolution matches expected value.

### Step 2: Validate Without Expected Value

```bash
bash scripts/validate_dns.sh --domain www.example.com --type A
```

**Expected**: Resolved IP addresses displayed.

## 7. Audit Log Verification

### Step 1: Log an Operation

```bash
bash scripts/dns_audit_log.sh --action list --detail "Verification test"
```

**Expected**: Log entry written successfully.

### Step 2: Export Logs

```bash
bash scripts/dns_audit_log.sh --action list --export json
```

**Expected**: JSON array of log entries.

## Verification Checklist

- [ ] Environment check passes (hcloud CLI, jq, credentials)
- [ ] API connectivity verified
- [ ] Zone listing works (public, private, all)
- [ ] Record set listing works (with filters)
- [ ] Record set create works
- [ ] Record set update works
- [ ] Record set delete works
- [ ] Batch update dry-run works
- [ ] Batch update execution works
- [ ] DNS resolution validation works
- [ ] Audit logging works
- [ ] JSON output format is valid
- [ ] Error handling is graceful
