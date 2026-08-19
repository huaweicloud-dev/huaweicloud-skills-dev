# Verification Method

## Prerequisite Checks

```bash
# Verify hcloud is installed and authenticated
hcloud version
hcloud IAM ListUsersV5 --cli-region=cn-north-4 --limit=1
```

## Manual Verification Steps

### 1. List Users
```bash
hcloud IAM ListUsersV5 --cli-region=cn-north-4 --limit=10
```
Expected: List of IAM users with IDs and names.

### 2. Detach Policy from User
```bash
hcloud IAM DetachUserPolicyV5 \
  --cli-region=cn-north-4 \
  --policy_id={policy_id} \
  --user_id={user_id}
```
Expected: HTTP 204 No Content (success).

### 3. Remove User from Group
```bash
hcloud IAM RemoveUserFromGroupV5 \
  --cli-region=cn-north-4 \
  --group_id={group_id} \
  --user_id={user_id}
```
Expected: HTTP 204 No Content (success).

### 4. Delete Login Profile
```bash
hcloud IAM DeleteLoginProfileV5 \
  --cli-region=cn-north-4 \
  --user_id={user_id}
```
Expected: HTTP 204 No Content (success). User can no longer log in via console.

### 5. Delete Access Key
```bash
hcloud IAM DeleteAccessKeyV5 \
  --cli-region=cn-north-4 \
  --access_key_id={ak_id} \
  --user_id={user_id}
```
Expected: HTTP 204 No Content (success).

### 6. Delete User
```bash
hcloud IAM DeleteUserV5 \
  --cli-region=cn-north-4 \
  --user_id={user_id}
```
Expected: HTTP 204 No Content (success).

### 7. Delete Group
```bash
hcloud IAM DeleteGroupV5 \
  --cli-region=cn-north-4 \
  --group_id={group_id}
```
Expected: HTTP 204 No Content (success).

## Automated Verification

```bash
# Run all test cases
bash scripts/test-cli-commands.sh skills/security/iam/huawei-cloud-iam-account-revocation --executor cli
```