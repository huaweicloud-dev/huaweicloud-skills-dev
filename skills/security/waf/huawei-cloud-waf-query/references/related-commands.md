# Command Quick Reference

| Operation | Command |
| ----------- | --------- |
| List attack events | `hcloud WAF ListEvent --cli-region=cn-north-4 --project_id=<id> --from=<ms> --to=<ms> [--attacks.1=<type>] [--actions.1=<action>] [--domains.1=<domain>] --pagesize=<n>` |
| Show event detail | `hcloud WAF ShowEvent --cli-region=cn-north-4 --project_id=<id> --eventid=<event_id>` |
| List access logs | `hcloud WAF ListEventLog --cli-region=cn-north-4 --project_id=<id> --page=<page> --pagesize=<size>` |
| Attack statistics | `hcloud WAF ListStatistics --cli-region=cn-north-4 --project_id=<id> --from=<ms> --to=<ms>` |
| Threat overview | `hcloud WAF ListThreats --cli-region=cn-north-4 --project_id=<id> --from=<ms> --to=<ms> --recent=today` |
| Top source IPs | `hcloud WAF ListTopIp --cli-region=cn-north-4 --project_id=<id> --from=<ms> --to=<ms>` |

## Common Filters

- Attack types (`--attacks.N`): `xss`, `sqli`, `rfi`, `lfi`, `cmdi`, `cc`, `webshell`, `vuln`, `botm`,
  `robot`, `antitamper`, `antileakage`, `custom_blackip`, `custom_geoip`, `illegal`, `advanced_bot`, `llm_prompt_injection`
- Protection actions (`--actions.N`): `block`, `pass`, `log`, `captcha`, `js_challenge`, `mask`, `abort_response`
- Recent keywords (`--recent`): `yesterday`, `today`, `3days`, `1week`, `1month`

## Timestamp Helper

```bash
FROM=$((($(date +%s%3N))-86400000))   # 24 hours ago
TO=$(date +%s%3N)                     # now
```
