#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query the Huawei Cloud BSS customer account balance and print a report.

Primary executor : huaweicloudsdkbss Python SDK (BssClient.show_customer_account_balances)
                    — the KooCLI (hcloud) does NOT support the BSS service,
                      so the SDK is the only execution path.
Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py) — every
                   run reports trace_id / status (success|biz_fail|sys_fail) / error
                   code / cost to the skillsopr operations console. Reporting is
                   non-blocking and fails silently.

Read-only skill: it only queries the customer account balance, never creates,
modifies or deletes any billing resource.

Usage:
  python3 query_account_balance.py [--format text|json]
                                   [--executor sdk]

Examples:
  python3 query_account_balance.py
  python3 query_account_balance.py --format json
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

BSS_ENDPOINT = "https://bss.myhuaweicloud.com"

# Account type mapping from the BSS AccountBalanceV3 model:
# 1: balance (现金账户余额), 2: credit (信用账户), 5: reward (奖励金账户), 7: deposit (保证金账户)
ACCOUNT_TYPE_NAMES = {
    1: "balance",
    2: "credit",
    5: "reward",
    7: "deposit",
}


def _get_credentials():
    ak = os.getenv("HUAWEI_ACCESS_KEY") or os.getenv("HUAWEICLOUD_SDK_AK")
    sk = os.getenv("HUAWEI_SECRET_KEY") or os.getenv("HUAWEICLOUD_SDK_SK")
    if not ak or not sk:
        raise QualityError(
            "C01",
            "AK/SK not set in environment variables "
            "(HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY or HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK)",
        )
    return ak, sk


def _to_number(value):
    """Convert SDK Decimal fields to float for JSON output."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return value


def _run_sdk():
    """Query the customer account balance via huaweicloudsdkbss (global service)."""
    from huaweicloudsdkcore.auth.credentials import GlobalCredentials
    from huaweicloudsdkbss.v2 import BssClient, ShowCustomerAccountBalancesRequest

    ak, sk = _get_credentials()
    # BSS is a global service: GlobalCredentials + explicit endpoint.
    client = BssClient.new_builder() \
        .with_credentials(GlobalCredentials(ak, sk)) \
        .with_endpoints([BSS_ENDPOINT]) \
        .build()

    resp = client.show_customer_account_balances(ShowCustomerAccountBalancesRequest())
    return resp


def _build_report(resp):
    """Normalize the SDK response into a JSON report."""
    accounts = []
    for ab in (resp.account_balances or []):
        accounts.append({
            "account_id": ab.account_id,
            "account_type": ab.account_type,
            "account_type_name": ACCOUNT_TYPE_NAMES.get(ab.account_type, "unknown"),
            "amount": _to_number(ab.amount),
            "currency": ab.currency,
            "designated_amount": _to_number(ab.designated_amount),
            "credit_amount": _to_number(ab.credit_amount),
        })
    return {
        "currency": resp.currency,
        "measure_id": resp.measure_id,
        "debt_amount": _to_number(resp.debt_amount),
        "accounts": accounts,
    }


def _format_text(report):
    lines = []
    lines.append("=== Huawei Cloud Customer Account Balance ===")
    lines.append("Currency: %s" % (report.get("currency") or "CNY"))
    lines.append("Debt amount: %s" % (report.get("debt_amount") if report.get("debt_amount") is not None else 0))
    if not report.get("accounts"):
        lines.append("No account balance records returned.")
    for acc in report.get("accounts", []):
        lines.append(
            "- %s (%s): amount=%s currency=%s"
            % (
                acc["account_type_name"],
                acc["account_type"],
                acc["amount"] if acc["amount"] is not None else 0,
                acc["currency"] or report.get("currency") or "CNY",
            )
        )
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Query Huawei Cloud BSS customer account balance (read-only)."
    )
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--executor",
        choices=["sdk"],
        default="sdk",
        help="Execution mode (default: sdk — the only supported mode for BSS)",
    )
    args = parser.parse_args()

    with quality_context(
        skill_name="huawei-cloud-billing-account-balance",
        skill_version="1.0.0",
        trigger_type="agent",
        timeout_threshold_ms=60000,
    ) as q:
        q.input = {"format": args.format, "executor": args.executor}
        try:
            resp = _run_sdk()
        except QualityError:
            raise
        except Exception as e:  # noqa: BLE001 — wrap unexpected SDK errors
            raise QualityError("B01", "%s: %s" % (type(e).__name__, str(e)))

        report = _build_report(resp)
        q.output = report

        if args.format == "json":
            print(json.dumps(report, ensure_ascii=False, indent=2))
        else:
            print(_format_text(report))


if __name__ == "__main__":
    try:
        main()
    except QualityError as e:
        print("ERROR: %s (%s)" % (e.message, e.error_code), file=sys.stderr)
        sys.exit(1)
    except Exception as e:  # noqa: BLE001
        print("ERROR: %s" % e, file=sys.stderr)
        sys.exit(1)
