---
name: huawei-cloud-ecs-query
description: >
  Queries Huawei Cloud ECS (Elastic Cloud Server) resources in read-only mode.
  Covers ECS instances, flavors, keypairs, quotas, server groups, block devices,
  NICs, VNC console, launch templates, recycle bin, scheduled events, and tags.
  No write operations. Use this skill when the user needs to query ECS instance
  details, list flavors, check server status, view block devices, or inspect
  ECS resource attributes.
  Triggers include: 查询ECS, ECS实例查询, 云服务器查询, 弹性云服务器, ECS规格,
  ECS配额, 云服务器列表, ECS详情, query ECS, list ECS servers, show server details,
  ECS flavors, ECS quotas, ECS keypairs, server groups, block devices, ECS inventory,
  cloud server list, ecs list, ecs query, ecs show.
tags:
  - huawei-cloud
  - ecs
  - query
---

# Huawei Cloud ECS Query

> **⚠️ Execution Method (Must Read): This skill executes queries via local Python scripts. Using hcloud, openstack, or other CLI tools or direct API calls is prohibited.**
>
> - Query scripts are located under the skill directory `scripts/ecs/`
> - All scripts and environment check scripts are inside the skill package. **You must use `skill action=exec` to execute them; do not run them directly in the shell**
> - For specific script paths and parameters, see `references/guide.md`
> - **Do not attempt hcloud, openstack, curl IAM, or other CLI/API methods; this skill does not depend on those tools**
> - **All paths are relative to the skill directory, which is the directory containing this SKILL.md**

## Overview

This skill is a standalone read-only query skill that queries Huawei Cloud ECS resources by calling the Huawei Cloud Python SDK (`huaweicloudsdkecs`) via local Python scripts.

This skill is applicable to the following scenarios:

1. Query ECS instance lists and details (status, flavor, image, network, IP)
2. Query available ECS flavors and sell policies
3. Query ECS keypairs and security groups
4. Query server block devices and volume attachments
5. Query server network interfaces and NIC details
6. Query server groups, tags, and quotas
7. Query launch templates and recycle bin
8. Query scheduled events and job status
9. Obtain VNC remote console address

This skill does NOT handle the following:

1. Creating ECS instances or resources
2. Modifying ECS instances or resources
3. Deleting ECS instances or resources
4. Guessing or fabricating information that was not queried

---

## Architecture

```text
User Request → Skill → huaweicloudsdkecs (SDK) → Huawei Cloud ECS API
                                   ↓
                   ListServersDetails / ShowServer / ListFlavors / ...
                                   ↓
                          Structured JSON results
```

## Prerequisites

**Before use, you must run the environment check script to complete environment verification and dependency installation in one step:**

- Linux / macOS: `skill action=exec: bash skill://scripts/check_env.sh`
- Windows: `skill action=exec: powershell -ExecutionPolicy Bypass -File skill://scripts/check_env.ps1`

The script will check in order: Python >= 3.6 → install dependencies → verify SDK → verify credentials → verify service availability. If the environment check fails, fix the issue before continuing with other scripts.

**Environment Variables:**

| Variable | Required | Description |
|----------|----------|-------------|
| HW_ACCESS_KEY | Yes | Huawei Cloud AK |
| HW_SECRET_KEY | Yes | Huawei Cloud SK |
| HW_REGION_NAME | No | Default cn-north-4 |
| HW_PROJECT_ID | No | Project ID (automatically obtained via IAM API if not set) |
| HW_SECURITY_TOKEN | No | Required for temporary AK/SK |

**Do not output the values of the above environment variables.**

**IAM Permissions** — See `references/iam-policies.md` for least-privilege policy.

---

## Workflow

1. **Environment Preparation** — Execute the environment check script to ensure dependencies are installed and credentials are configured
2. **Identify Query** — Based on user intent, read `references/guide.md` to determine the script path and parameters
3. **Execute Query** — Call the appropriate script with parameters via `skill action=exec`
4. **Format Results** — Parse and present query results in a structured format

---

## Core Commands

### Instance Queries

```bash
# List all ECS instances (detailed)
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_servers_details.py --region=cn-north-4

# Show a specific ECS instance
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_server.py --region=cn-north-4 --server_id=<id>

# List cloud servers (v1.1 API)
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_cloud_servers.py --region=cn-north-4

# List servers by tag
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_servers_by_tag.py --region=cn-north-4
```

### Flavor Queries

```bash
# List ECS flavors
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_flavors.py --region=cn-north-4

# List flavor sell policies
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_flavor_sell_policies.py --region=cn-north-4

# List resize flavors
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_resize_flavors.py --region=cn-north-4 --source_flavor_id=<id>

# Show flavor capacity
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_flavor_capacity.py --region=cn-north-4 --flavor_id=<id>
```

### Server Detail Queries

```bash
# List server block devices
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_server_block_devices.py --region=cn-north-4 --server_id=<id>

# Show server block device
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_server_block_device.py --region=cn-north-4 --server_id=<id> --volume_id=<id>

# List server network interfaces
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_server_interfaces.py --region=cn-north-4 --server_id=<id>

# List server volume attachments
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_server_volume_attachments.py --region=cn-north-4 --server_id=<id>

# Show server tags
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_server_tags.py --region=cn-north-4 --server_id=<id>

# Show server limits (quotas)
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_server_limits.py --region=cn-north-4
```

### Keypair & Security Group Queries

```bash
# List SSH keypairs
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/nova_list_keypairs.py --region=cn-north-4

# Show SSH keypair details
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/nova_show_keypair.py --region=cn-north-4 --keypair_name=<name>

# List server security groups
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/nova_list_server_security_groups.py --region=cn-north-4 --server_id=<id>
```

### Other Queries

```bash
# List server groups
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_server_groups.py --region=cn-north-4

# List availability zones
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_server_az_info.py --region=cn-north-4

# List project tags
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_server_tags.py --region=cn-north-4

# Show VNC remote console
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_server_remote_console.py --region=cn-north-4 --server_id=<id>

# List recycle bin servers
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_recycle_bin_servers.py --region=cn-north-4

# List scheduled events
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_scheduled_events.py --region=cn-north-4

# Show job status
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_job.py --region=cn-north-4 --job_id=<id>
```

---

## Parameter Confirmation

| Parameter | Required | Description |
|-----------|----------|-------------|
| region | Yes | Huawei Cloud region, e.g., cn-north-4 |
| --project_id | No | Project ID; automatically obtained if not provided |
| --server_id | Yes (Show) | ECS server ID for detail query |
| --flavor_id | Yes (Flavor) | Flavor ID for flavor-specific queries |
| --keypair_name | Yes (Keypair) | Keypair name for keypair detail query |
| --job_id | Yes (Job) | Job ID for async task status query |
| --availability_zone | No | Availability zone filter |

For script-specific parameters, see `references/guide.md`.

---

## Output Format

Query results are output in JSON format, containing the following common fields:

- `total`: Total number of matching resources
- `items`: Resource list, each resource containing key fields such as id, name, and status
- Specific fields vary by resource type; see `references/guide.md` for details

---

## KooCLI Command Format Standard

When hcloud CLI is available, use the following format:

```bash
hcloud ECS ListServersDetails --cli-region=<region> [--limit=<N>] [--offset=<N>]
hcloud ECS ShowServer --cli-region=<region> --server_id=<id>
hcloud ECS ListFlavors --cli-region=<region> [--availability_zone=<az>]
hcloud ECS ListServerGroups --cli-region=<region>
hcloud ECS NovaListKeypairs --cli-region=<region>
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `ECS` | `hcloud ECS ListServersDetails` |
| Operation name | PascalCase | `ListServersDetails`, `ShowServer` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--server_id=xxx` |

---

## Reference Documents

- [Query Guide](references/guide.md) — Script usage guide for all ECS query operations
- [IAM Policies](references/iam-policies.md) — Least-privilege IAM policy for ECS query operations
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup reference
- [Verification Method](references/verification-method.md) — How to verify skill functionality
- [Data Flow Diagram](references/dataflow-diagram.md) — Mermaid data flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance criteria for this skill
