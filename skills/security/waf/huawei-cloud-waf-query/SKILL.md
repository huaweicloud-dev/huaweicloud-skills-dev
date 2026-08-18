---
name: huawei-cloud-waf-query
description: |
  Query Huawei Cloud WAF (Web Application Firewall) attack events, access/protection logs, attack statistics, threat overview and top attack source IPs for daily security inspection and incident troubleshooting.
  Triggers include: "查询WAF攻击事件", "查询WAF告警", "查看WAF防护日志", "查看WAF访问日志", "WAF攻击统计", "WAF威胁概览", "查询攻击源IP", "waf query", "waf attack events", "waf logs", "waf statistics", "web application firewall", "安全日报", "日常巡检WAF".
tags: [huawei-cloud, waf, security, query, logs]
---

# Huawei Cloud WAF Query Skill

## Overview

This skill helps users query **Huawei Cloud Web Application Firewall (WAF)** protection data for daily security inspection and incident troubleshooting:

- **Attack events** — list attack events by time range, attack type, protection action and domain, and view event details
- **Access / protection logs** — page through WAF access (event) logs
- **Attack statistics** — overall counts grouped by attack category (ACCESS / WEB_ATTACK / CC / PRECISE / CRAWLER / BOTM / BLACK_IP / ATTACK)
- **Threat overview** — threat summary for a recent period (yesterday / today / 3days / 1week / 1month)
- **Top attack source IPs** — ranking of the most frequent attack source IPs in a time window

All operations are **read-only queries** (List/Show). No resource is created, modified or deleted.

## Prerequisites

1. **KooCLI (hcloud) installed and authenticated** — see `references/cli-installation-guide.md`.
2. **WAF service permission** — the IAM account needs WAF read permissions, see `references/iam-policies.md`.
3. **Project ID** — required by most WAF APIs. Obtain it from the Huawei Cloud console (username → My Credentials → Projects) or use:

   ```bash
   hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --name=cn-north-4
   ```

4. **Region** — WAF queries must specify a region, e.g. `cn-north-4`.
5. Time parameters `from`/`to` are **millisecond timestamps** and must be used together; the maximum time range is 30 days.

## Workflow

1. **Confirm the target time window** — compute `from`/`to` millisecond timestamps (e.g. last 24 hours).
   For "today / 3 days" style summaries, `ListThreats --recent` accepts `yesterday|today|3days|1week|1month` directly.
2. **Get an overview first** — run `ListStatistics` to see the attack distribution, then drill down with `ListEvent`.
3. **List attack events** — `ListEvent` with filters (attack type, action, domain, time range).
4. **Inspect a specific event** — `ShowEvent --eventid=<id>` for full detail of a suspicious event.
5. **Check logs / rankings** — `ListEventLog` for access logs, `ListTopIp` for top source IPs, `ListThreats` for the threat summary.

## Core Commands

### List attack events

```bash
hcloud WAF ListEvent --cli-region=cn-north-4 --project_id={project_id} \
  --from={from_ms} --to={to_ms} [--attacks.1={attack_type}] \
  [--actions.1={action}] [--domains.1={domain}] --pagesize={page_size}
```

- `--attacks.1` values: `xss`, `sqli`, `rfi`, `lfi`, `cmdi`, `cc`, `webshell`, `vuln`, `botm`, `robot`, `antitamper`, `antileakage`, `custom_blackip`, `custom_geoip`, `illegal`, etc.
- `--actions.1` values: `block`, `pass`, `log`, `captcha`, `js_challenge`, etc.
- `--domains.N` is the array form for domain filtering (repeatable, e.g. `--domains.1=example.com --domains.2=other.com`).
  **Do NOT use `--domain` (singular)**: it collides with the KooCLI system parameter of the same name and triggers an
  interactive confirmation, which fails with `[USE_ERROR]EOF` in non-interactive (Agent) execution.
- `pagesize` cannot be `-1`; at most 10,000 records can be queried.

### Show attack event detail

```bash
hcloud WAF ShowEvent --cli-region=cn-north-4 --project_id={project_id} --eventid={event_id}
```

### List access / protection logs

```bash
hcloud WAF ListEventLog --cli-region=cn-north-4 --project_id={project_id} --page={page} --pagesize={size}
```

### Attack statistics overview

```bash
hcloud WAF ListStatistics --cli-region=cn-north-4 --project_id={project_id} --from={from_ms} --to={to_ms}
```

### Threat overview (recent period)

```bash
hcloud WAF ListThreats --cli-region=cn-north-4 --project_id={project_id} --from={from_ms} --to={to_ms} --recent={yesterday|today|3days|1week|1month}
```

### Top attack source IPs

```bash
hcloud WAF ListTopIp --cli-region=cn-north-4 --project_id={project_id} --from={from_ms} --to={to_ms}
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
| ----------- | ---------- | ------------- | --------- |
| `--cli-region` | Yes | Huawei Cloud region | `cn-north-4` |
| `--project_id` | Yes | Project ID of the WAF instance | `0dd8cb4e...` |
| `--from` / `--to` | Yes (ListEvent/ListStatistics/ListThreats/ListTopIp) | Start/end time, millisecond timestamps, used together, max range 30 days | `1786885834203` |
| `--recent` | Yes (ListThreats) | Recent period keyword | `today`, `3days`, `1week` |
| `--attacks.[N]` | No | Attack type filter (repeatable) | `--attacks.1=sqli` |
| `--actions.[N]` | No | Protection action filter (repeatable) | `--actions.1=block` |
| `--domains.[N]` | No | Domain name filter, array form (repeatable, fuzzy match) | `--domains.1=example.com` |
| `--eventid` | Yes (ShowEvent) | Attack event ID | `e6c2d8e1...` |
| `--page` / `--pagesize` | No | Paging for ListEventLog | `--page=1 --pagesize=10` |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

- Service name: `WAF`
- Operation name: PascalCase, e.g. `ListEvent`, `ShowEvent`, `ListStatistics`
- Region parameter: `--cli-region=<value>` (e.g. `cn-north-4`)
- Simple parameter: `--key=value` (e.g. `--eventid=xxx`)
- Indexed array parameter: `--key.N=value` (e.g. `--attacks.1=sqli`)

## Reference Documents

- `references/cli-installation-guide.md` — KooCLI installation and authentication
- `references/iam-policies.md` — Least-privilege IAM policies for WAF read-only access
- `references/verification-method.md` — How to verify the skill works
- `references/dataflow-diagram.md` — Mermaid data flow diagram
- `references/acceptance-criteria.md` — Acceptance criteria for this skill
- `references/related-commands.md` — Command quick reference

## Edge Cases

| Scenario | Handling |
| ---------- | ---------- |
| `ListEvent` returns 0 events | Verify `from`/`to` are valid millisecond timestamps and the range ≤ 30 days; confirm the WAF instance has protected domains |
| `ListThreats` returns `[USE_ERROR]` for `--recent` | `--recent` only accepts `yesterday`, `today`, `3days`, `1week`, `1month` |
| Missing `--project_id` | Obtain the project ID via `hcloud IAM KeystoneListProjects --cli-region=<region> --name=<region>` |
| `pagesize` set to `-1` on `ListEvent` | Not allowed; use a positive integer (max 100) |
| `ShowEvent` with a non-existent `eventid` | Returns `{"total": 0, "items": []}` silently (no error) — treat it as "event not found", verify the event ID is valid and still within the retention period |
| Query range > 30 days | Split into multiple queries with sub-ranges |
| No WAF instance in the account | The API returns empty lists (`total: 0`) — confirm WAF is enabled and domains are added |
