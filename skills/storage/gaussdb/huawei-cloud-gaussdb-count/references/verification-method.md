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

A successful query returns the GaussDB instance count, e.g.:

```text
GaussDB for openGauss count: 2
GaussDB (MySQL) count: 1
Total GaussDB instances: 3
```

When using the count-only CLI lookup, a single number is returned:

```text
2
```
