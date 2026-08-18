# IAM Policies for WAF Read-Only Query

This skill only performs **read-only** WAF queries (List/Show). Grant the least-privilege policy below.

## JSON Policy (attach to the IAM user or group)

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "waf:event:list",
        "waf:event:get",
        "waf:eventLog:list",
        "waf:statistics:list",
        "waf:threat:list",
        "waf:topIp:list"
      ],
      "Resource": [
        "waf:*:*:instance:*"
      ]
    }
  ]
}
```

## Alternative: System-defined Role

If custom policies are not desired, assign the **WAF ReadOnlyAccess** role (if available in your environment) or **WAF Administrator** for full access (not recommended for read-only automation).

## Notes

- `waf:event:list` — ListEvent (attack event list)
- `waf:event:get` — ShowEvent (attack event detail)
- `waf:eventLog:list` — ListEventLog (access/protection logs)
- `waf:statistics:list` — ListStatistics (attack statistics)
- `waf:threat:list` — ListThreats (threat overview)
- `waf:topIp:list` — ListTopIp (top attack source IPs)

All actions are read-only; no `waf:*:create` / `waf:*:delete` / `waf:*:update` permissions are granted.
