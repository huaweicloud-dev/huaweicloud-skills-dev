# Verification Method

## Functional Verification

Run the skill's own test script:

```bash
bash scripts/test-cli-commands.sh {skill-path} --executor cli   # CLI priority
bash scripts/test-cli-commands.sh {skill-path} --executor sdk   # SDK fallback
```

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh {skill-path}
```

The validation checks, among others:

- SKILL.md exists with YAML frontmatter (`name`, `description`, no `version`)
- Required sections present: Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents
- `references/iam-policies.md` and `references/cli-installation-guide.md` exist
- No credential hardcoding
- File count <= 30, SKILL.md lines <= 500

## Expected Output

A successful query returns the GaussDB instance count and total storage size, e.g.:

```text
GaussDB for openGauss count: 2
GaussDB for openGauss total size: 400.0 GB
GaussDB (MySQL) count: 1
GaussDB (MySQL) total size: 100.0 GB
Total GaussDB instances: 3
Total GaussDB storage size: 500.0 GB
```

When using the count-only CLI lookup, a single number is returned:

```text
2
```

When using the size lookup, the summed storage size in GB is returned:

```text
400
```
