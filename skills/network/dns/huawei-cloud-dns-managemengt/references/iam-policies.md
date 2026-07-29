# IAM Permission Policies - DNS Management Skill

## Overview

This document declares the IAM permissions required by the Huawei Cloud DNS Domain Resolution Dynamic Management skill. All permissions follow the principle of least privilege.

## Read Operations (Query Only)

| API Action | Permission | Purpose |
|------------|-----------|---------|
| `dns:zones:list` | List zones | Query all DNS zones (public/private) |
| `dns:zones:get` | Get zone details | View individual zone information |
| `dns:recordsets:list` | List record sets | Query all record sets in a zone |
| `dns:recordsets:get` | Get record set | View individual record set details |
| `dns:lines:list` | List lines | Query available resolution lines |

## Write Operations (Record Management)

| API Action | Permission | Purpose |
|------------|-----------|---------|
| `dns:recordsets:create` | Create record set | Create new DNS records |
| `dns:recordsets:update` | Update record set | Modify existing DNS records |
| `dns:recordsets:delete` | Delete record set | Remove DNS records |

## Zone Management Operations (Optional - Not Used by This Skill)

| API Action | Permission | Purpose |
|------------|-----------|---------|
| `dns:zones:create` | Create zone | Create new DNS zones |
| `dns:zones:delete` | Delete zone | Remove DNS zones |
| `dns:zones:update` | Update zone | Modify zone settings |

## Minimum Read-Only Policy (JSON)

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dns:zones:list",
        "dns:zones:get",
        "dns:recordsets:list",
        "dns:recordsets:get",
        "dns:lines:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Full Management Policy (JSON)

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dns:zones:list",
        "dns:zones:get",
        "dns:recordsets:list",
        "dns:recordsets:get",
        "dns:recordsets:create",
        "dns:recordsets:update",
        "dns:recordsets:delete",
        "dns:lines:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Permission Assignment Steps

1. Log in to Huawei Cloud IAM console: https://console.huaweicloud.com/iam/
2. Navigate to **Policies** → **Create Custom Policy**
3. Choose **JSON** mode and paste the policy JSON above
4. Navigate to **Users** / **User Groups** → **Authorize**
5. Select the custom policy and confirm

## Permission Failure Handling

When a command fails with a permission error:

1. Read this document (`references/iam-policies.md`)
2. Display the required permission list and policy JSON to the user
3. Guide the user to create a custom policy in the IAM console
4. Pause execution and wait for user confirmation that permissions have been granted
5. Retry the failed command
