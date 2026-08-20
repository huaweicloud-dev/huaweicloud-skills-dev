# Acceptance Criteria

## Release Gate Checklist

| # | Criterion | Verification Method |
|---|-----------|-------------------|
| 1 | SKILL.md exists with valid frontmatter | `grep '^---$' SKILL.md` |
| 2 | Skill name matches directory name | `grep '^name: ' SKILL.md` matches dir |
| 3 | All SDK imports work | `python3 -c "from huaweicloudsdkobs.v1.obs_client import ObsClient"` |
| 4 | openpyxl available | `python3 -c "import openpyxl; print(openpyxl.__version__)"` |
| 5 | `--help` produces expected output | `python3 scripts/obs-list-excel.py --help` |
| 6 | IAM policies file exists | `ls references/iam-policies.md` |
| 7 | Excel file generated successfully | `python3 scripts/obs-list-excel.py --region=cn-north-4 --output=/tmp/verify.xlsx` |
| 8 | Excel contains two sheets (Buckets Summary + Objects) | `python3 -c "import openpyxl; wb=openpyxl.load_workbook('/tmp/verify.xlsx'); assert len(wb.sheetnames) >= 2"` |
| 9 | Skill quality SDK integrated | `python3 -c "import sys; sys.path.insert(0,'scripts/'); from skill_quality_sdk import quality_report"` |
|10 | No credential hardcoding | `grep -rn 'AKIA\|sk-[A-Za-z0-9]\|access_key.*=' scripts/ --include='*.py'` returns empty |