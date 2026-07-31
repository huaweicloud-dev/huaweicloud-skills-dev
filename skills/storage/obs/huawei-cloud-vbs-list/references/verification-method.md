# Verification Method

## 1. Prerequisite Checks

### 1.1 KooCLI (hcloud) Installed

```bash
hcloud version
```

Expected: prints the version (e.g., `Current KooCLI version: 7.2.12`). If not installed, see [cli-installation-guide.md](cli-installation-guide.md).

### 1.2 Credentials Configured

```bash
hcloud configure list
```

Expected: a profile exists with `mode: AKSK` and a non-empty `accessKeyId`.

### 1.3 IAM Permission

Verify the user can call `cbr:backup:list`. See [iam-policies.md](iam-policies.md).

## 2. Functional Verification

### 2.1 CLI — List All Backups

```bash
hcloud CBR ListBackups --cli-region=cn-north-4 --limit=1
```

Expected behavior:

- HTTP 200 JSON response with top-level keys `backups`, `count`, `offset`, `limit`.
- `backups` is an array (possibly empty).
- Each item contains at least `id`, `name`, `status`, `resource_type`, `resource_id`, `created_at`.

### 2.2 CLI — Filtering

```bash
hcloud CBR ListBackups --cli-region=cn-north-4 --limit=1 --resource_type=OS::Nova::Server
hcloud CBR ListBackups --cli-region=cn-north-4 --limit=1 --name=backup_for_image
hcloud CBR ListBackups --cli-region=cn-north-4 --limit=1 --status=available
```

Expected: the response `count` reflects the applied filters (>= 0).

### 2.3 SDK Script — Summarized Listing

```bash
python3 scripts/list_vbs_backups.py --region cn-north-4 --limit=5
```

Expected: prints a summary table with columns `ID / Name / Status / ResourceType / CreatedAt` (or a "No backups found" message if the project has no backups). Exit code 0.

## 3. Sample Output (CLI)

```json
{
  "backups": [
    {
      "id": "af094134-204a-42d8-87aa-b2252b49011d",
      "name": "backup_for_image_21ec2a51-bba0-44a9-b92f-7f554ccb6c61",
      "status": "available",
      "resource_type": "OS::Nova::Server",
      "resource_id": "765f2ea2-da3c-43fc-8f5b-dfc5e214a8c9",
      "created_at": "2026-05-13T11:55:16.025095",
      "vault_id": "bf33d48b-369e-4852-81e3-b5940a0ee6fa"
    }
  ],
  "count": 1,
  "offset": 0,
  "limit": 1
}
```

## 4. Acceptance Check

- [ ] `hcloud CBR ListBackups` returns a valid JSON response.
- [ ] Filters (status/name/resource_type/vault/time range) work correctly.
- [ ] SDK script works and prints a readable summary.
- [ ] No AK/SK is printed or hardcoded anywhere in the skill files.
