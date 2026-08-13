# IAM Policies (IAM 权限)

This skill is **read-only** — it only queries CES (Cloud Eye) monitoring data
and EPS (Enterprise Project) information. It never creates, modifies or deletes
any resource. Use the least-privilege policies below.

## Recommended System Policies

Grant the following read-only system policies to the IAM user / agency that
runs this skill:

| Service | System Policy | Required Permissions |
|---------|---------------|----------------------|
| CES | `CES ReadOnlyAccess` | Query alarm rules, alarm histories, alarm templates, dashboards, notification masks, resource groups, one-click alarms, metrics and agent dimension info |
| EPS | `EPS ReadOnlyAccess` | List enterprise projects, query project details, quotas, bound resources and migration records |
| IAM | (optional) | Only needed if the skill must resolve the project ID automatically via IAM (`iam:projects:list` / `iam:agencies:get`); the IAM project lookup is read-only |

If only the built-in `CES ReadOnlyAccess` / `EPS ReadOnlyAccess` policies are
granted, no custom policy JSON is needed.

## Custom Policy JSON (alternative, least privilege)

If system policies are not an option, create a custom policy with only the
read actions used by this skill:

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ces:alarms:list",
        "ces:alarmHistory:list",
        "ces:alarmTemplates:list",
        "ces:alarmTemplate:get",
        "ces:dashboards:list",
        "ces:dashboard:get",
        "ces:notificationMasks:list",
        "ces:notificationMaskResources:list",
        "ces:resourceGroups:list",
        "ces:resourceGroup:get",
        "ces:oneClickAlarms:list",
        "ces:oneClickAlarmRules:list",
        "ces:metrics:list",
        "ces:agentDimensions:list",
        "eps:enterpriseProjects:list",
        "eps:enterpriseProject:get",
        "eps:quotas:list",
        "eps:resources:list",
        "eps:migrations:list"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

> Note: actual action names follow the CES / EPS service permission model.
> When in doubt, prefer the read-only system policies listed above.

## Credential Handling

- Credentials are read from environment variables only
  (`HW_ACCESS_KEY`, `HW_SECRET_KEY`, `HW_SECURITY_TOKEN`, `HW_REGION_NAME`).
- Never hardcode AK/SK in scripts, guides or this document.
- Do not output credential values in query results or reports.
