#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query the Huawei Cloud RDS (Relational Database Service) instance list and
print the RDS instance names.

Primary executor : KooCLI `hcloud RDS ListInstances --cli-region=<region>`
Fallback executor: huaweicloudsdkrds Python SDK (RdsClient.list_instances)
Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py) —
                   every run reports trace_id / status (success|biz_fail|sys_fail)
                   / error code / cost to the skillsopr operations console.
                   Reporting is non-blocking and fails silently.

Read-only skill: it only lists RDS instances, never creates, modifies, deletes,
restarts or stops any database instance.

Usage:
  python3 list_rds_instances.py [--region cn-north-4]
                                [--name <instance-name>] [--id <instance-id>]
                                [--type Single|Ha|Replica]
                                [--datastore_type MySQL|PostgreSQL|SQLServer|MariaDB]
                                [--vpc_id <vpc-id>] [--limit 100] [--offset 0]
                                [--names-only] [--compact] [--executor cli|sdk|auto]

Examples:
  python3 list_rds_instances.py --region cn-north-4 --names-only
  python3 list_rds_instances.py --region cn-north-4 --type Ha --limit 20
  python3 list_rds_instances.py --region cn-north-4 --compact
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

DEFAULT_REGION = "cn-north-4"

RDS_TYPES = ["Single", "Ha", "Replica"]
DATASTORE_TYPES = ["MySQL", "PostgreSQL", "SQLServer", "MariaDB"]


def _cli_base_cmd(region):
    return ["hcloud", "RDS", "ListInstances", "--cli-region=" + region, "--cli-output=json"]


def _run_cli(region, args):
    """Run hcloud RDS ListInstances and return the parsed instance list (or raise)."""
    cmd = _cli_base_cmd(region)
    if args.name:
        cmd.append("--name=" + args.name)
    if args.id:
        cmd.append("--id=" + args.id)
    if args.type:
        cmd.append("--type=" + args.type)
    if args.datastore_type:
        cmd.append("--datastore_type=" + args.datastore_type)
    if args.vpc_id:
        cmd.append("--vpc_id=" + args.vpc_id)
    if args.limit is not None:
        cmd.append("--limit=" + str(args.limit))
    if args.offset is not None:
        cmd.append("--offset=" + str(args.offset))

    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    out = proc.stdout or ""
    err = proc.stderr or ""

    # hcloud exits 0 even when the RDS API returns an error payload.
    if proc.returncode != 0 or "error_msg" in out or "[USE_ERROR]" in out:
        raise QualityError("U04", "RDS API call failed: %s" % (err or out)[:500])
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        raise QualityError("B01", "Failed to parse hcloud JSON output: %s" % out[:300])
    return data.get("instances") or []


def _run_sdk(region, args):
    """Fallback: query RDS instances via huaweicloudsdkrds."""
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdkrds.v3 import ListInstancesRequest, RdsClient
    from huaweicloudsdkrds.v3.region.rds_region import RdsRegion

    ak = os.getenv("HUAWEI_ACCESS_KEY") or os.getenv("HUAWEICLOUD_SDK_AK")
    sk = os.getenv("HUAWEI_SECRET_KEY") or os.getenv("HUAWEICLOUD_SDK_SK")
    if not ak or not sk:
        raise QualityError("C01", "AK/SK not set in environment variables")

    credentials = BasicCredentials(ak, sk)
    project_id = os.getenv("HUAWEICLOUD_SDK_PROJECT_ID") or os.getenv("RDS_PROJECT_ID")
    if project_id:
        credentials = credentials.with_project_id(project_id)

    client = RdsClient.new_builder() \
        .with_credentials(credentials) \
        .with_region(RdsRegion.value_of(region)) \
        .build()

    request = ListInstancesRequest(
        id=args.id,
        name=args.name,
        type=args.type,
        datastore_type=args.datastore_type,
        vpc_id=args.vpc_id,
        limit=args.limit,
        offset=args.offset,
    )
    resp = client.list_instances(request)
    return list(resp.instances or [])


def _field(obj, key):
    """Read a field from either a parsed JSON dict or an SDK model object."""
    if isinstance(obj, dict):
        return obj.get(key, "") or ""
    return getattr(obj, key, "") or ""


def _format_result(instances, names_only, compact):
    if names_only:
        return "\n".join(_field(i, "name") for i in instances if _field(i, "name"))
    if compact:
        return "\n".join(
            "\t".join(
                (_field(i, "name"), _field(i, "id"), _field(i, "status"),
                 _field(_field(i, "datastore"), "type"))
            )
            for i in instances
        )
    return json.dumps(
        [{
            "name": _field(i, "name"),
            "id": _field(i, "id"),
            "status": _field(i, "status"),
            "type": _field(i, "type"),
            "engine": _field(_field(i, "datastore"), "type"),
            "version": _field(_field(i, "datastore"), "version"),
            "flavor": _field(i, "flavor_ref"),
            "private_ips": _field(i, "private_ips"),
            "created": _field(i, "created"),
        } for i in instances],
        ensure_ascii=False,
        indent=2,
    )


def main():
    parser = argparse.ArgumentParser(
        description="List Huawei Cloud RDS instances (read-only)."
    )
    parser.add_argument("--region", default=os.getenv("RDS_REGION", DEFAULT_REGION),
                        help="Huawei Cloud region (default: %s)" % DEFAULT_REGION)
    parser.add_argument("--name", help="Instance name filter (exact or *fuzzy* match)")
    parser.add_argument("--id", help="Instance ID filter (exact or *fuzzy* match)")
    parser.add_argument("--type", choices=RDS_TYPES,
                        help="Instance type filter: Single/Ha/Replica")
    parser.add_argument("--datastore_type", choices=DATASTORE_TYPES,
                        help="Engine type filter: MySQL/PostgreSQL/SQLServer/MariaDB")
    parser.add_argument("--vpc_id", help="VPC ID filter")
    parser.add_argument("--limit", type=int, default=None,
                        help="Max records per page (1-100, default 100)")
    parser.add_argument("--offset", type=int, default=None,
                        help="Index offset (>=0, default 0)")
    parser.add_argument("--names-only", action="store_true",
                        help="Print only the RDS instance names (one per line)")
    parser.add_argument("--compact", action="store_true",
                        help="Print name/id/status/engine as TSV rows")
    parser.add_argument("--executor", choices=["cli", "sdk", "auto"], default="auto",
                        help="Execution mode (default: auto = CLI first, SDK fallback)")
    args = parser.parse_args()

    with quality_context(
        skill_name="huawei-cloud-rds-list",
        skill_version="1.0.0",
        trigger_type="agent",
        timeout_threshold_ms=120000,
    ) as q:
        q.input = {
            "region": args.region,
            "name": args.name,
            "id": args.id,
            "type": args.type,
            "datastore_type": args.datastore_type,
            "vpc_id": args.vpc_id,
            "limit": args.limit,
            "offset": args.offset,
            "names_only": args.names_only,
            "compact": args.compact,
        }
        instances = None
        last_error = None
        for mode in (["cli", "sdk"] if args.executor == "auto" else [args.executor]):
            try:
                if mode == "cli":
                    if not _have_cli():
                        raise QualityError("C01", "hcloud CLI not found")
                    instances = _run_cli(args.region, args)
                else:
                    instances = _run_sdk(args.region, args)
                break
            except QualityError as e:
                # User-input errors (U-prefix: invalid region, bad params,
                # permission denied) are definitive — falling back to the SDK
                # would only replace a clear message with a raw KeyError.
                # Only retry with the SDK for environment/system issues.
                if args.executor == "auto" and e.error_code and e.error_code.startswith("U"):
                    raise
                last_error = e
                if args.executor != "auto":
                    raise
            except Exception as e:  # noqa: BLE001 — wrap unexpected errors
                last_error = QualityError("B01", "%s: %s" % (type(e).__name__, str(e)))
                if args.executor != "auto":
                    raise

        if instances is None:
            raise last_error or QualityError("N02", "All executors failed")

        result = _format_result(instances, args.names_only, args.compact)
        q.output = {"count": len(instances), "result": result[:2000]}
        if len(instances) == 0:
            q.fail("U03", "No RDS instances matched the query filters")
            print("(no RDS instances found matching the query)")
        else:
            print(result)


def _have_cli():
    try:
        proc = subprocess.run(["hcloud", "version"], capture_output=True, text=True, timeout=30)
        return proc.returncode == 0
    except Exception:
        return False


if __name__ == "__main__":
    try:
        main()
    except QualityError as e:
        print("ERROR: %s (%s)" % (e.message, e.error_code), file=sys.stderr)
        sys.exit(1)
    except Exception as e:  # noqa: BLE001
        print("ERROR: %s" % e, file=sys.stderr)
        sys.exit(1)
