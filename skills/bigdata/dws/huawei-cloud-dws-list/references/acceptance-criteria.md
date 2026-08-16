# Acceptance Criteria

## Definition of Done

1. **Command validity**: `hcloud DWS ListClusters --cli-region=<region> --help` shows valid parameters and exits 0.
2. **Live query**: `hcloud DWS ListClusters --cli-region=<region>` returns valid JSON with `clusters` array and `count` field.
3. **Name extraction**: `jq -r '.clusters[]?.name'` correctly extracts cluster names; empty list handled gracefully.
4. **Trigger words**: SKILL.md description contains trigger words for both Chinese ("DWS列表", "查询DWS") and English ("list DWS clusters").
5. **No credentials**: No AK/SK hardcoded anywhere in the skill package.
6. **Compliance**: Skill passes `validate-skill.sh` (0 FAIL).

## Test Results

| Case | Expected | Actual | Status |
|------|----------|--------|--------|
| TC-01: ListClusters help | exit 0, params shown | TBD | TBD |
| TC-02: ListClusters live | valid JSON | TBD | TBD |
| TC-03: Name extraction | names per line | TBD | TBD |
