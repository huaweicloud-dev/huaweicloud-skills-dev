# IAM Policies

This Skill reads a local file (`~/.hcloud/metaRepo/services_en.json`) which is downloaded by KooCLI during `hcloud meta download`. The KooCLI itself requires valid AK/SK credentials for authentication.

## Required Permissions

Since this Skill only reads local metadata cache, no specific IAM policies are required beyond the credentials needed for KooCLI configuration.

| Permission | Scope | Reason |
|------------|-------|--------|
| None (read-only local operation) | Local | Only reads local JSON metadata file cached by KooCLI |

## Least Privilege Principle

The `hcloud meta download` command requires a configured KooCLI profile with valid credentials, but does not make API calls to list services. The metadata is downloaded from a public metadata repository.

For the data read operation, no Huawei Cloud API calls are made — all data comes from the local cache file.