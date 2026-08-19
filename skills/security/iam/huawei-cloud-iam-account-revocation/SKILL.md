---
name: huawei-cloud-iam-account-revocation
description: |
  Manage IAM account permission revocation on Huawei Cloud — detach policies, remove group memberships, delete login profiles, revoke access keys, delete MFA devices, and delete IAM users/groups.
  Triggers include: "revoke permissions", "offboard user", "disable account", "删除用户", "注销账号权限", "清理IAM用户", "权限回收", "用户离职清理", "remove IAM user", "delete access key", "revoke IAM role".
tags:
  - iam
  - security
  - account-management
  - revocation
  - access-control
---

# Huawei Cloud IAM Account Revocation

## Overview

This Skill enables automated revocation of IAM user permissions and account cleanup on Huawei Cloud. It covers the complete lifecycle of removing a user's access — from detaching policies and removing group memberships, to deleting access keys, login profiles, MFA devices, and finally deleting the IAM user or group.

**Common scenarios:**
- **Employee offboarding** — Revoke all permissions and delete the user account
- **Security incident response** — Immediately revoke access and disable the account
- **Account cleanup** — Remove unused or deactivated IAM users and groups
- **Least privilege enforcement** — Detach excessive policies from users or groups

## Prerequisites

1. **KooCLI (hcloud)** installed and authenticated
   - Installation: Follow the [official KooCLI installation guide](https://support.huaweicloud.com/qs-hcli/hcli_02_003.html) to download and verify the package
   - Authentication: `hcloud configure set --cli-profile=default --access-key={AK} --secret-key={SK} --cli-region={region}`
2. **IAM permissions** required for the operator account:
   - `iam:users:list`
   - `iam:users:delete`
   - `iam:groups:delete`
   - `iam:policies:detach`
   - `iam:accessKeys:delete`
   - `iam:loginProfiles:delete`
   - `iam:virtualMfaDevices:delete`
   - `iam:roles:revokeFromUser`
3. **User/Group/Policy IDs** — Target resource IDs must be known or obtainable via `ListUsersV5`

## Workflow

```
1. Identify target user(s) → ListUsersV5 (query by group or all)
2. Pre-check resource existence → user_exists() / group_exists() before any delete
3. Detach all policies from the user → DetachUserPolicyV5
4. Remove user from all groups → RemoveUserFromGroupV5
5. Revoke enterprise project roles → RevokeRoleFromUserOnEnterpriseProject
6. Delete console login profile → DeleteLoginProfileV5
7. Delete access keys → DeleteAccessKeyV5
8. Delete MFA devices → DeleteVirtualMfaDeviceV5
9. Delete user → DeleteUserV5
10. (Optional) Clean up groups → DeleteGroupV5 (if empty)
```

> **Safety:** Steps 3–10 are destructive. Always confirm the target user ID and verify via query before deletion.
> **Error handling:** Before each delete operation, `skill.py` performs a `ListUsersV5` pre-check. If the user does not exist, the operation is skipped with a `resource_not_found` error (error code `U03`). The `run_hcloud()` function also detects hcloud CLI `USE_ERROR` markers in output (even when rc=0) and treats them as failures with error code `U02`.

## Core Commands

### Query Operations

| Command | Description |
|---------|-------------|
| `hcloud IAM ListUsersV5 --cli-region={region} --limit=100` | List all IAM users |
| `hcloud IAM ListUsersV5 --cli-region={region} --group_id={group_id}` | List users in a specific group |

### Policy Detachment

| Command | Description |
|---------|-------------|
| `hcloud IAM DetachUserPolicyV5 --cli-region={region} --policy_id={policy_id} --user_id={user_id}` | Detach a policy from a user |
| `hcloud IAM DetachGroupPolicyV5 --cli-region={region} --policy_id={policy_id} --group_id={group_id}` | Detach a policy from a group |

### Group Membership

| Command | Description |
|---------|-------------|
| `hcloud IAM RemoveUserFromGroupV5 --cli-region={region} --group_id={group_id} --user_id={user_id}` | Remove a user from a group |

### Role Revocation

| Command | Description |
|---------|-------------|
| `hcloud IAM RevokeRoleFromUserOnEnterpriseProject --cli-region={region} --enterprise_project_id={ep_id} --role_id={role_id} --user_id={user_id}` | Revoke a role from a user on an enterprise project |

### Credential and Access Revocation

| Command | Description |
|---------|-------------|
| `hcloud IAM DeleteLoginProfileV5 --cli-region={region} --user_id={user_id}` | Delete console login profile (disable console access) |
| `hcloud IAM DeleteAccessKeyV5 --cli-region={region} --access_key_id={ak_id} --user_id={user_id}` | Delete a permanent access key (revoke API access) |
| `hcloud IAM DeleteVirtualMfaDeviceV5 --cli-region={region} --user_id={user_id} --serial_number={serial_number}` | Delete a virtual MFA device |

### Deletion Operations

| Command | Description |
|---------|-------------|
| `hcloud IAM DeleteGroupV5 --cli-region={region} --group_id={group_id}` | Delete a group (must be empty) |
| `hcloud IAM DeleteUserV5 --cli-region={region} --user_id={user_id}` | Delete an IAM user (all resources must be removed first) |

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{user_id}` | Yes | IAM user ID (UUID) | `a1b2c3d4e5f6...` |
| `{group_id}` | Conditional | IAM group ID (UUID) | `g1h2i3j4k5l6...` |
| `{policy_id}` | Conditional | Identity policy ID | `p1q2r3s4t5u6...` |
| `{access_key_id}` | Conditional | Permanent access key ID | `ABCDEFGHIJKLMNOPQRST` |
| `{ep_id}` | Conditional | Enterprise project ID | `ep_1234567890...` |
| `{role_id}` | Conditional | Role ID | `r1s2t3u4v5w6...` |
| `{serial_number}` | Conditional | MFA device serial number | `iam:user-mfa:{user_id}:mfa-device-name` |

## Reference Documents

- [IAM Policies](references/iam-policies.md)
- [CLI Installation Guide](references/cli-installation-guide.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Verification Method](references/verification-method.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name | `IAM` |
| Operation name | PascalCase | `DeleteUserV5`, `DetachUserPolicyV5` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--user_id=xxx` |