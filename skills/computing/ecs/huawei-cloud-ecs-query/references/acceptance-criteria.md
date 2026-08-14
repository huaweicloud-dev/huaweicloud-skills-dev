# Acceptance Criteria

## Functional Requirements

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-01 | Skill can list all ECS instances with ID, name, status, flavor, and network info | High |
| AC-02 | Skill can show details of a specific ECS instance by server ID | High |
| AC-03 | Skill can list ECS flavors with vCPU, memory, and availability info | High |
| AC-04 | Skill can list SSH keypairs with name, type, and fingerprint | Medium |
| AC-05 | Skill can list server groups with ID, name, and policy | Medium |
| AC-06 | Skill can list server block devices and volume attachments | Medium |
| AC-07 | Skill can list server network interfaces with IP and MAC addresses | Medium |
| AC-08 | Skill can query server tags and project tags | Medium |
| AC-09 | Skill can query tenant quotas (server limits) | Medium |
| AC-10 | Skill can query availability zones | Low |
| AC-11 | Skill can query flavor sell policies and resize flavors | Low |
| AC-12 | Skill can query launch templates and versions | Low |
| AC-13 | Skill can query recycle bin servers and configuration | Low |
| AC-14 | Skill can query scheduled events | Low |
| AC-15 | Skill can query job (async task) status | Low |
| AC-16 | Skill can get VNC remote console address | Low |
| AC-17 | Skill can get server password (for keypair-auth instances) | Low |

## Non-Functional Requirements

| ID | Criterion | Priority |
|----|-----------|----------|
| NFR-01 | All operations are read-only; no create/update/delete operations | Critical |
| NFR-02 | Results are returned in structured JSON format | High |
| NFR-03 | Environment check validates Python, SDK, and credentials before queries | High |
| NFR-04 | Credentials are read from environment variables only; no hardcoding | Critical |
| NFR-05 | Scripts are executed via `skill action=exec`; not directly in shell | High |
| NFR-06 | Error messages are clear and actionable | Medium |
| NFR-07 | Large result sets support pagination | Medium |

## Compliance Requirements

| ID | Criterion | Priority |
|----|-----------|----------|
| CR-01 | SKILL.md follows Huawei Cloud Skill Specification format | Critical |
| CR-02 | IAM policy uses least-privilege principle | High |
| CR-03 | No credential hardcoding in any file | Critical |
| CR-04 | No cross-skill direct calls | High |
| CR-05 | File count ≤ 30 | Medium |
| CR-06 | SKILL.md line count ≤ 500 | Medium |
| CR-07 | All file extensions in allowlist | Medium |
