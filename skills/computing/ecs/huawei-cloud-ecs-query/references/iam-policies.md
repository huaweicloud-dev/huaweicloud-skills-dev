# IAM Policies for ECS Query Operations

## Least-Privilege Policy

The following IAM policy grants the minimum permissions required for ECS read-only query operations:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:servers:get",
        "ecs:servers:list",
        "ecs:serverGroups:get",
        "ecs:serverGroups:list",
        "ecs:flavors:get",
        "ecs:flavors:list",
        "ecs:availabilityZones:list",
        "ecs:tags:get",
        "ecs:tags:list",
        "ecs:keypairs:get",
        "ecs:keypairs:list",
        "ecs:quotas:get",
        "ecs:cloudServers:get",
        "ecs:cloudServers:list",
        "ecs:jobs:get",
        "ecs:scheduledEvents:list",
        "ecs:recycleBin:get",
        "ecs:recycleBin:list",
        "ecs:templates:get",
        "ecs:templates:list",
        "ecs:serverInterfaces:get",
        "ecs:serverInterfaces:list",
        "ecs:serverVolumes:get",
        "ecs:serverVolumes:list",
        "ecs:serverBlockDevices:get",
        "ecs:serverBlockDevices:list",
        "ecs:serverPassword:get",
        "ecs:serverRemoteConsole:get",
        "ecs:serverMetadata:get",
        "ecs:flavorSellPolicies:list",
        "ecs:flavorCapacity:get"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Notes

- This policy only grants read (get/list) permissions; no create, update, or delete operations are included.
- The `Resource: ["*"]` can be further restricted to specific projects or resources if needed.
- For temporary AK/SK access, ensure the IAM agency or trust policy includes these actions.
