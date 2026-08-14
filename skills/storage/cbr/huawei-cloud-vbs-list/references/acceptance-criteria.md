# Acceptance Criteria

## Correct Behaviors (PASS)

| Case | Expected Result |
|------|-----------------|
| User asks "list my backups" | Skill returns the backup list with key fields (ID, name, status, resource type, created time) |
| User filters by status `available` | Only backups in `available` status are returned (`count` matches) |
| User filters by name | Backups whose name contains the given string are returned |
| User filters by resource type | Only backups of that resource type are returned |
| No backups exist | Skill reports "no backups found" / empty list without error |
| CLI unavailable | Skill falls back to the CBR SDK script and still returns results |
| Permission denied (403) | Skill points the user to `references/iam-policies.md` (`cbr:backups:list`) |

## Error Patterns (FAIL / Must Avoid)

| Pattern | Why It Fails |
|---------|--------------|
| Using `hcloud VBS ...` | `VBS` is an unsupported KooCLI service (`[USE_ERROR]Unsupported service: VBS`); must use `CBR` |
| Guessing API endpoint `/v2/{project_id}/backups` | Legacy VBS path; the current endpoint is `/v3/{project_id}/backups` (from SDK `_http_info`) |
| Omitting `--cli-region` | Region is required; without it the CLI cannot resolve the project |
| Hardcoding AK/SK in scripts | Violates credential security rules; read from env/profile only |
| Passing `--limit=200` via SDK | SDK pagination limit may differ from CLI; use a safe default (e.g. 50) |

## Checklist

- [ ] CLI command `hcloud CBR ListBackups --cli-region=cn-north-4` returns valid JSON.
- [ ] Filters (status/name/resource_type/vault/time) behave correctly.
- [ ] SDK fallback script works without CLI.
- [ ] No credentials hardcoded; no `hcloud configure set` examples with real values.
- [ ] SKILL.md frontmatter name matches the directory name.
- [ ] All reference docs present: iam-policies.md, verification-method.md, dataflow-diagram.md, acceptance-criteria.md, cli-installation-guide.md.
