# Acceptance Criteria

| ID | Criteria | Verification Method |
|----|----------|-------------------|
| AC-01 | `hcloud meta download` completes successfully | Run `echo "y" | hcloud meta download` — should show "Download successful" |
| AC-02 | `services_en.json` file exists | Check `~/.hcloud/metaRepo/services_en.json` exists and is valid JSON |
| AC-03 | Service count is returned as a positive integer | Run the Python parsing script — output should show `Huawei Cloud Services Count: <N>` where N > 100 |
| AC-04 | Command is non-destructive | No resources are created, modified, or deleted by this Skill |