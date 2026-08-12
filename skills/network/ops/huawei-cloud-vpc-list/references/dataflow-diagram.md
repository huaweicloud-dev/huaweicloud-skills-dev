# Data Flow Diagram — huawei-cloud-vpc-list

```mermaid
flowchart TD
  START(["/User asks for the VPC list/"]) --> CONFIRM["Confirm region + optional filters\n(limit, name, id, cidr, enterprise project)"]
  CONFIRM --> PREREQ{"hcloud CLI present\nand authenticated?"}
  PREREQ -->|No| GUIDE["Guide user through\nreferences/cli-installation-guide.md"]
  GUIDE --> CONFIRM
  PREREQ -->|Yes| CLI["Run primary command:\nhcloud VPC ListVpcs/v3 --cli-region={region} [filters]"]
  CLI --> OK{"Command succeeded?"}
  OK -->|Yes| OUTPUT["Parse and return VPC list:\nid, name, cidr, status, description, ep id"]
  OK -->|No / version issue| V2["Try legacy API:\nhcloud VPC ListVpcs/v2 --cli-region={region}"]
  V2 --> OK2{"Command succeeded?"}
  OK2 -->|Yes| OUTPUT
  OK2 -->|No| SDK["Fallback to SDK:\nhuaweicloudsdkvpc VpcClient.list_vpcs"]
  SDK --> OUTPUT
  OUTPUT --> MORE{"More pages available?"}
  MORE -->|Yes| PAG["Re-run with --marker={next_marker}"]
  PAG --> OUTPUT
  MORE -->|No| END(["/Return final VPC list to user/"])
```

## Flow Description

1. Confirm the target region and any optional filter parameters with the user.
2. Verify the KooCLI (`hcloud`) is installed and authenticated.
3. Run the primary v3 CLI command; on failure fall back to the v2 CLI command, then to the Python SDK.
4. Parse the returned `vpcs` array and present id/name/cidr/status/description/enterprise-project.
5. If the result set is paginated, fetch the next page using `--marker` until all pages are returned.
6. This skill performs **read-only** queries — no VPC is created, modified, or deleted.
