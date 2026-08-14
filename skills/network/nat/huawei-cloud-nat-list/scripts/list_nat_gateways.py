#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query the Huawei Cloud public NAT gateway list and print gateway names.

Primary executor : KooCLI `hcloud NAT ListNatGateways --cli-region=<region>` (v2 API)
Fallback executor: huaweicloudsdknat Python SDK (NatClient.list_nat_gateways)
Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py) — every
                   run reports trace_id / status (success|biz_fail|sys_fail) / error
                   code / cost to the skillsopr operations console. Reporting is
                   non-blocking and fails silently.

Read-only skill: it only lists public NAT gateways, never creates, modifies or
deletes them (or their SNAT/DNAT rules).

Usage:
  python3 list_nat_gateways.py [--region cn-north-4]
                               [--name <gateway-name>] [--id <gateway-id>]
                               [--status ACTIVE] [--spec 1|2|3|4|5]
                               [--enterprise_project_id <ep-id>]
                               [--limit 100] [--marker <gateway-id>]
                               [--sort_key id|name|status|created_at]
                               [--sort_dir asc|desc]
                               [--names-only] [--compact] [--executor cli|sdk|auto]

Examples:
  python3 list_nat_gateways.py --region cn-north-4 --names-only
  python3 list_nat_gateways.py --region cn-north-4 --status ACTIVE --limit 20
  python3 list_nat_gateways.py --region cn-north-4 --sort_key created_at --sort_dir desc --compact
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

DEFAULT_REGION = "cn-north-4"

# NAT gateway spec number → human-readable name
SPEC_NAMES = {
    "1": "small",
    "2": "medium",
    "3": "large",
    "4": "extra-large",
    "5": "enterprise",
}


def _cli_base_cmd(region):
    return ["hcloud", "NAT", "ListNatGateways", "--cli-region=" + region, "--cli-output=json"]


def _run_cli(region, args):
    """Run hcloud NAT ListNatGateways and return the parsed gateway list (or raise)."""
    cmd = _cli_base_cmd(region)
    if args.name:
        cmd.append("--name=" + args.name)
    if args.id:
        cmd.append("--id=" + args.id)
    if args.status:
        cmd.append("--status.1=" + args.status)
    if args.spec:
        cmd.append("--spec.1=" + args.spec)
    if args.enterprise_project_id:
        cmd.append("--enterprise_project_id=" + args.enterprise_project_id)
    if args.limit is not None:
        cmd.append("--limit=" + str(args.limit))
    if args.marker:
        cmd.append("--marker=" + args.marker)
    if args.sort_key:
        cmd.append("--sort_key=" + args.sort_key)
    if args.sort_dir:
        cmd.append("--sort_dir=" + args.sort_dir)

    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    out = proc.stdout or ""
    err = proc.stderr or ""

    # hcloud exits 0 even when the NAT API returns an error payload.
    if proc.returncode != 0 or "error_msg" in out or "[USE_ERROR]" in out:
        raise QualityError("U04", "NAT API call failed: %s" % (err or out)[:500])
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        raise QualityError("B01", "Failed to parse hcloud JSON output: %s" % out[:300])
    return data.get("nat_gateways") or []


def _run_sdk(region, args):
    """Fallback: query public NAT gateways via huaweicloudsdknat."""
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdknat.v2 import ListNatGatewaysRequest, NatClient
    from huaweicloudsdknat.v2.region.nat_region import NatRegion

    ak = os.getenv("HUAWEI_ACCESS_KEY") or os.getenv("HUAWEICLOUD_SDK_AK")
    sk = os.getenv("HUAWEI_SECRET_KEY") or os.getenv("HUAWEICLOUD_SDK_SK")
    if not ak or not sk:
        raise QualityError("C01", "AK/SK not set in environment variables")

    credentials = BasicCredentials(ak, sk)
    # Optional: pin the project id (e.g. HUAWEICLOUD_SDK_PROJECT_ID) when the
    # auto-resolved project differs from the account that owns the gateways.
    project_id = os.getenv("HUAWEICLOUD_SDK_PROJECT_ID") or os.getenv("NAT_PROJECT_ID")
    if project_id:
        credentials = credentials.with_project_id(project_id)

    client = NatClient.new_builder() \
        .with_credentials(credentials) \
        .with_region(NatRegion.value_of(region)) \
        .build()

    request = ListNatGatewaysRequest(
        id=args.id,
        name=args.name,
        status=[args.status] if args.status else None,
        spec=[args.spec] if args.spec else None,
        enterprise_project_id=args.enterprise_project_id,
        limit=args.limit or 100,
        marker=args.marker,
        sort_key=args.sort_key,
        sort_dir=args.sort_dir,
    )
    resp = client.list_nat_gateways(request)
    return list(resp.nat_gateways or [])


def _field(obj, key):
    """Read a field from either a parsed JSON dict or an SDK model object."""
    if isinstance(obj, dict):
        return obj.get(key, "") or ""
    return getattr(obj, key, "") or ""


def _format_result(gateways, names_only, compact):
    if names_only:
        return "\n".join(_field(g, "name") for g in gateways if _field(g, "name"))
    if compact:
        return "\n".join(
            "\t".join(
                _field(g, k) for k in ("name", "id", "status", "spec")
            )
            for g in gateways
        )
    return json.dumps(
        [{
            "name": _field(g, "name"),
            "id": _field(g, "id"),
            "status": _field(g, "status"),
            "spec": _field(g, "spec"),
            "spec_name": SPEC_NAMES.get(_field(g, "spec"), _field(g, "spec")),
            "router_id": _field(g, "router_id"),
            "internal_network_id": _field(g, "internal_network_id"),
            "created_at": _field(g, "created_at"),
        } for g in gateways],
        ensure_ascii=False,
        indent=2,
    )


def main():
    parser = argparse.ArgumentParser(
        description="List Huawei Cloud public NAT gateways (read-only)."
    )
    parser.add_argument("--region", default=os.getenv("NAT_REGION", DEFAULT_REGION),
                        help="Huawei Cloud region (default: %s)" % DEFAULT_REGION)
    parser.add_argument("--name", help="Gateway name filter (max 64 chars)")
    parser.add_argument("--id", help="Exact gateway id filter")
    parser.add_argument("--status",
                        choices=["ACTIVE", "PENDING_CREATE", "PENDING_UPDATE",
                                 "PENDING_DELETE", "INACTIVE"],
                        help="Gateway status filter")
    parser.add_argument("--spec", choices=["1", "2", "3", "4", "5"],
                        help="Gateway spec filter (1=small..5=enterprise)")
    parser.add_argument("--enterprise_project_id", help="Enterprise project id filter")
    parser.add_argument("--limit", type=int, default=None, help="Max records (1-2000)")
    parser.add_argument("--marker", help="Pagination marker (gateway id of the start position)")
    parser.add_argument("--sort_key", choices=["id", "name", "status", "created_at"],
                        help="Sort key (id/name/status/created_at)")
    parser.add_argument("--sort_dir", choices=["asc", "desc"],
                        help="Sort direction (asc/desc)")
    parser.add_argument("--names-only", action="store_true",
                        help="Print only the gateway names (one per line)")
    parser.add_argument("--compact", action="store_true",
                        help="Print name/id/status/spec as TSV rows")
    parser.add_argument("--executor", choices=["cli", "sdk", "auto"], default="auto",
                        help="Execution mode (default: auto = CLI first, SDK fallback)")
    args = parser.parse_args()

    with quality_context(
        skill_name="huawei-cloud-nat-list",
        skill_version="1.0.0",
        trigger_type="agent",
        timeout_threshold_ms=120000,
    ) as q:
        q.input = {
            "region": args.region,
            "name": args.name,
            "id": args.id,
            "status": args.status,
            "spec": args.spec,
            "enterprise_project_id": args.enterprise_project_id,
            "limit": args.limit,
            "marker": args.marker,
            "sort_key": args.sort_key,
            "sort_dir": args.sort_dir,
            "names_only": args.names_only,
            "compact": args.compact,
        }
        gateways = None
        last_error = None
        for mode in (["cli", "sdk"] if args.executor == "auto" else [args.executor]):
            try:
                if mode == "cli":
                    if not _have_cli():
                        raise QualityError("C01", "hcloud CLI not found")
                    gateways = _run_cli(args.region, args)
                else:
                    gateways = _run_sdk(args.region, args)
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

        if gateways is None:
            raise last_error or QualityError("N02", "All executors failed")

        result = _format_result(gateways, args.names_only, args.compact)
        q.output = {"count": len(gateways), "result": result[:2000]}
        if len(gateways) == 0:
            q.fail("U03", "No public NAT gateways matched the query filters")
            if args.names_only or args.compact:
                # Do not silently print nothing: make "no data" distinguishable
                # from a failed query.
                print("(no public NAT gateways found matching the query)")
            else:
                print(result)
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
