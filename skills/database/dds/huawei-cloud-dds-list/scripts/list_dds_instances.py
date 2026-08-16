#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query the Huawei Cloud DDS (Document Database Service) instance list and
print the DDS instance names.

Primary executor : KooCLI `hcloud DDS ListInstances --cli-region=<region>`
Fallback executor: huaweicloudsdkdds Python SDK (DdsClient.list_instances)
Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py) —
                   every run reports trace_id / status (success|biz_fail|sys_fail)
                   / error code / cost to the skillsopr operations console.
                   Reporting is non-blocking and fails silently.

Read-only skill: it only lists DDS instances, never creates, modifies, deletes,
restarts or stops any database instance.

Usage:
  python3 list_dds_instances.py [--region cn-north-4]
                                [--name <instance-name>] [--id <instance-id>]
                                [--mode Sharding|ReplicaSet|Single]
                                [--datastore_type DDS-Community|DDS-Enhanced]
                                [--vpc_id <vpc-id>] [--subnet_id <subnet-id>]
                                [--limit 100] [--offset 0]
                                [--names-only] [--compact] [--executor cli|sdk|auto]

Examples:
  python3 list_dds_instances.py --region cn-north-4 --names-only
  python3 list_dds_instances.py --region cn-north-4 --mode ReplicaSet --limit 20
  python3 list_dds_instances.py --region cn-north-4 --compact
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

DEFAULT_REGION = "cn-north-4"

DDS_MODES = ["Sharding", "ReplicaSet", "Single"]
DATASTORE_TYPES = ["DDS-Community", "DDS-Enhanced"]


def _cli_base_cmd(region):
    return ["hcloud", "DDS", "ListInstances", "--cli-region=" + region, "--cli-output=json"]


def _run_cli(region, args):
    """Run hcloud DDS ListInstances and return the parsed instance list (or raise)."""
    cmd = _cli_base_cmd(region)
    if args.name:
        cmd.append("--name=" + args.name)
    if args.id:
        cmd.append("--id=" + args.id)
    if args.mode:
        # `--mode` is both a KooCLI system parameter (auth mode) and a DDS API
        # parameter. Explicitly pin the system one with --cli-mode=AKSK so the
        # API `--mode` filter is unambiguous (avoids the interactive prompt).
        cmd.append("--cli-mode=AKSK")
        cmd.append("--mode=" + args.mode)
    if args.datastore_type:
        cmd.append("--datastore_type=" + args.datastore_type)
    if args.vpc_id:
        cmd.append("--vpc_id=" + args.vpc_id)
    if args.subnet_id:
        cmd.append("--subnet_id=" + args.subnet_id)
    if args.limit is not None:
        cmd.append("--limit=" + str(args.limit))
    if args.offset is not None:
        cmd.append("--offset=" + str(args.offset))

    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    out = proc.stdout or ""
    err = proc.stderr or ""

    # hcloud exits 0 even when the DDS API returns an error payload.
    if proc.returncode != 0 or "error_msg" in out or "[USE_ERROR]" in out:
        msg = (err or out)[:500]
        # DDS API fuzzy-match constraint: only a leading `*` prefix wildcard is
        # supported for `--name`; `--id` is exact-only. Give actionable hints
        # instead of passing through the raw API error.
        if "DBS.200021" in out:
            msg += " | Hint: DDS instance name supports exact match or *prefix fuzzy match only (e.g. --name=*prod); '*' is a reserved character and cannot be used in the middle or at the end."
        elif "DBS.280404" in out:
            msg += " | Hint: DDS instance ID supports exact match only (e.g. --id=<full-instance-id>); fuzzy '*' matching is not supported for --id."
        raise QualityError("U04", "DDS API call failed: %s" % msg)
    # Strip KooCLI notice lines (e.g. the --cli-mode/--mode disambiguation
    # notice) that hcloud prints to stdout before the JSON body.
    json_lines = [ln for ln in out.splitlines()
                  if not ln.startswith("If both 'cli-mode' and 'mode' exist")]
    try:
        data = json.loads("\n".join(json_lines))
    except json.JSONDecodeError:
        raise QualityError("B01", "Failed to parse hcloud JSON output: %s" % out[:300])
    return data.get("instances") or []


def _run_sdk(region, args):
    """Fallback: query DDS instances via huaweicloudsdkdds."""
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdkdds.v3 import DdsClient, ListInstancesRequest
    from huaweicloudsdkdds.v3.region.dds_region import DdsRegion

    ak = os.getenv("HUAWEI_ACCESS_KEY") or os.getenv("HUAWEICLOUD_SDK_AK")
    sk = os.getenv("HUAWEI_SECRET_KEY") or os.getenv("HUAWEICLOUD_SDK_SK")
    if not ak or not sk:
        raise QualityError("C01", "AK/SK not set in environment variables")

    credentials = BasicCredentials(ak, sk)
    project_id = os.getenv("HUAWEICLOUD_SDK_PROJECT_ID") or os.getenv("DDS_PROJECT_ID")
    if project_id:
        credentials = credentials.with_project_id(project_id)

    client = DdsClient.new_builder() \
        .with_credentials(credentials) \
        .with_region(DdsRegion.value_of(region)) \
        .build()

    request = ListInstancesRequest(
        id=args.id,
        name=args.name,
        mode=args.mode,
        datastore_type=args.datastore_type,
        vpc_id=args.vpc_id,
        subnet_id=args.subnet_id,
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
                 _field(i, "mode"))
            )
            for i in instances
        )
    return json.dumps(
        [{
            "name": _field(i, "name"),
            "id": _field(i, "id"),
            "status": _field(i, "status"),
            "mode": _field(i, "mode"),
            "engine": _field(_field(i, "datastore"), "type"),
            "version": _field(_field(i, "datastore"), "version"),
            "vpc_id": _field(i, "vpc_id"),
            "created": _field(i, "created"),
        } for i in instances],
        ensure_ascii=False,
        indent=2,
    )


def main():
    parser = argparse.ArgumentParser(
        description="List Huawei Cloud DDS instances (read-only)."
    )
    parser.add_argument("--region", default=os.getenv("DDS_REGION", DEFAULT_REGION),
                        help="Huawei Cloud region (default: %s)" % DEFAULT_REGION)
    parser.add_argument("--name", help="Instance name filter: exact match, or *prefix fuzzy match (* is a reserved prefix char)")
    parser.add_argument("--id", help="Instance ID filter (exact match only)")
    parser.add_argument("--mode", choices=DDS_MODES,
                        help="Instance mode filter: Sharding/ReplicaSet/Single")
    parser.add_argument("--datastore_type", choices=DATASTORE_TYPES,
                        help="Database type filter: DDS-Community/DDS-Enhanced")
    parser.add_argument("--vpc_id", help="VPC ID filter")
    parser.add_argument("--subnet_id", help="Subnet ID filter")
    parser.add_argument("--limit", type=int, default=None,
                        help="Max records per page (1-100, default 100)")
    parser.add_argument("--offset", type=int, default=None,
                        help="Index offset (>=0, default 0)")
    parser.add_argument("--names-only", action="store_true",
                        help="Print only the DDS instance names (one per line)")
    parser.add_argument("--compact", action="store_true",
                        help="Print name/id/status/mode as TSV rows")
    parser.add_argument("--executor", choices=["cli", "sdk", "auto"], default="auto",
                        help="Execution mode (default: auto = CLI first, SDK fallback)")
    args = parser.parse_args()

    with quality_context(
        skill_name="huawei-cloud-dds-list",
        skill_version="1.0.0",
        trigger_type="agent",
        timeout_threshold_ms=120000,
    ) as q:
        q.input = {
            "region": args.region,
            "name": args.name,
            "id": args.id,
            "mode": args.mode,
            "datastore_type": args.datastore_type,
            "vpc_id": args.vpc_id,
            "subnet_id": args.subnet_id,
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
            q.fail("U03", "No DDS instances matched the query filters")
            print("(no DDS instances found matching the query)")
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
