#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query Huawei Cloud BSS account balance / balance change history / monthly bill summary.

Primary executor : huaweicloudsdkbss Python SDK (BssClient) — the KooCLI (hcloud)
                   does NOT support the BSS service, so the SDK is the only
                   execution path (verified: `hcloud BSS --help` -> "Unsupported
                   service: BSS").

Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py) —
                   every run reports trace_id / status (success|biz_fail|sys_fail)
                   / error code / cost to the skillsopr operations console.
                   Reporting is non-blocking and fails silently.

Read-only skill: queries only, never creates, modifies or deletes any billing
resource.

Actions:
  balance      — current customer account balances (cash/credit/reward/deposit) + debt
  changes      — balance change records (income/expense detail) in a time range
  monthly-sum  — monthly consumption summary for a billing cycle (YYYY-MM)

Usage:
  python3 query_balance_history.py --action balance [--format text|json]
  python3 query_balance_history.py --action changes --begin 2026-07-01 --end 2026-08-01 [--format text|json]
  python3 query_balance_history.py --action monthly-sum --bill-cycle 2026-07 [--format text|json]

Examples:
  python3 query_balance_history.py
  python3 query_balance_history.py --action changes --begin 2026-07-01 --end 2026-07-31
  python3 query_balance_history.py --action monthly-sum --bill-cycle 2026-07 --format json
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime

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

# Balance types for list_customer_account_change_records (BSS API)
BALANCE_TYPES = {
    "DEBIT": "BALANCE_TYPE_DEBIT",
    "CREDIT": "BALANCE_TYPE_CREDIT",
}

REVENUE_EXPENSE_TYPES = {"REVENUE": "REVENUE", "EXPENSE": "EXPENSE"}

_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_CYCLE_RE = re.compile(r"^\d{4}-\d{2}$")


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


def _get_client():
    from huaweicloudsdkcore.auth.credentials import GlobalCredentials
    from huaweicloudsdkbss.v2 import BssClient

    ak_cred, sk_cred = _get_credentials()
    # BSS is a global service: GlobalCredentials + explicit endpoint.
    return (
        BssClient.new_builder()
        .with_credentials(GlobalCredentials(ak_cred, sk_cred))
        .with_endpoints([BSS_ENDPOINT])
        .build()
    )


def _run_balance(client):
    from huaweicloudsdkbss.v2 import ShowCustomerAccountBalancesRequest

    return client.show_customer_account_balances(ShowCustomerAccountBalancesRequest())


def _run_changes(client, args):
    from huaweicloudsdkbss.v2 import ListCustomerAccountChangeRecordsRequest

    balance_type = BALANCE_TYPES.get(args.balance_type)
    if not balance_type:
        raise QualityError("U02", "balance_type must be one of: %s" % ", ".join(sorted(BALANCE_TYPES)))

    if args.begin and not _DATE_RE.match(args.begin):
        raise QualityError("U02", "begin must be a date in YYYY-MM-DD format, got: %s" % args.begin)
    if args.end and not _DATE_RE.match(args.end):
        raise QualityError("U02", "end must be a date in YYYY-MM-DD format, got: %s" % args.end)
    if args.begin and args.end and args.begin > args.end:
        raise QualityError("U02", "begin (%s) must not be later than end (%s)" % (args.begin, args.end))
    if args.revenue_expense_type and args.revenue_expense_type not in REVENUE_EXPENSE_TYPES:
        raise QualityError("U02", "revenue_expense_type must be one of: %s" % ", ".join(sorted(REVENUE_EXPENSE_TYPES)))

    req = ListCustomerAccountChangeRecordsRequest(
        balance_type=balance_type,
        trade_time_begin=args.begin,
        trade_time_end=args.end,
        revenue_expense_type=REVENUE_EXPENSE_TYPES.get(args.revenue_expense_type),
        limit=args.limit,
    )
    return client.list_customer_account_change_records(req)


def _run_monthly_sum(client, args):
    from huaweicloudsdkbss.v2 import ShowCustomerMonthlySumRequest

    if not args.bill_cycle:
        raise QualityError("U01", "bill_cycle is required for action monthly-sum (format YYYY-MM)")
    if not _CYCLE_RE.match(args.bill_cycle):
        raise QualityError("U02", "bill_cycle must be in YYYY-MM format, got: %s" % args.bill_cycle)

    req = ShowCustomerMonthlySumRequest(bill_cycle=args.bill_cycle, limit=args.limit)
    return client.show_customer_monthly_sum(req)


def _build_balance_report(resp):
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
        "action": "balance",
        "currency": resp.currency,
        "measure_id": resp.measure_id,
        "debt_amount": _to_number(resp.debt_amount),
        "accounts": accounts,
    }


def _build_changes_report(resp):
    records = []
    for r in (resp.records or []):
        records.append({
            "account_change_id": r.account_change_id,
            "trade_detail_type": r.trade_detail_type,
            "trade_time": r.trade_time,
            "trade_id": r.trade_id,
            "change_amount": _to_number(r.change_amount),
            "balance_after_change": _to_number(r.balance_after_change),
            "revenue_expense_type": r.revenue_expense_type,
            "bill_cycle": r.bill_cycle,
            "payment_channel_id": r.payment_channel_id,
            "payment_channel_no": r.payment_channel_no,
            "consume_time": r.consume_time,
            "account_name": r.account_name,
            "cloud_service_type_name": r.cloud_service_type_name,
            "resource_type_name": r.resource_type_name,
        })
    return {
        "action": "changes",
        "total_count": _to_number(resp.total_count),
        "currency": getattr(resp, "currency", None),
        "records": records,
    }


def _build_monthly_sum_report(resp):
    sums = []
    for s in (resp.bill_sums or []):
        sums.append({
            "bill_cycle": s.bill_cycle,
            "bill_type": s.bill_type,
            "customer_id": s.customer_id,
            "account_name": s.account_name,
            "service_type_code": s.service_type_code,
            "service_type_name": s.service_type_name,
            "resource_type_code": s.resource_type_code,
            "resource_type_name": s.resource_type_name,
            "charging_mode": s.charging_mode,
            "official_amount": _to_number(s.official_amount),
            "official_discount_amount": _to_number(s.official_discount_amount),
            "truncated_amount": _to_number(s.truncated_amount),
            "consume_amount": _to_number(s.consume_amount),
            "coupon_amount": _to_number(s.coupon_amount),
            "flexipurchase_coupon_amount": _to_number(s.flexipurchase_coupon_amount),
            "stored_value_card_amount": _to_number(s.stored_value_card_amount),
            "debt_amount": _to_number(s.debt_amount),
            "writeoff_amount": _to_number(s.writeoff_amount),
            "cash_amount": _to_number(s.cash_amount),
            "credit_amount": _to_number(s.credit_amount),
            "measure_id": s.measure_id,
        })
    return {
        "action": "monthly-sum",
        "total_count": _to_number(resp.total_count),
        "consume_amount": _to_number(resp.consume_amount),
        "debt_amount": _to_number(resp.debt_amount),
        "coupon_amount": _to_number(resp.coupon_amount),
        "cash_amount": _to_number(resp.cash_amount),
        "credit_amount": _to_number(resp.credit_amount),
        "writeoff_amount": _to_number(resp.writeoff_amount),
        "measure_id": resp.measure_id,
        "currency": resp.currency,
        "bill_sums": sums,
    }


def _format_text(report):
    action = report.get("action")
    lines = []
    if action == "balance":
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
    elif action == "changes":
        lines.append("=== Huawei Cloud Account Balance Change Records ===")
        lines.append("Total count: %s" % report.get("total_count"))
        if not report.get("records"):
            lines.append("No balance change records in the given time range.")
        for r in report.get("records", []):
            lines.append(
                "- %s | %s | change=%s | balance_after=%s | %s"
                % (
                    r["trade_time"] or "-",
                    r["revenue_expense_type"] or "-",
                    r["change_amount"] if r["change_amount"] is not None else 0,
                    r["balance_after_change"] if r["balance_after_change"] is not None else "-",
                    r["trade_detail_type"] or r["trade_id"] or "-",
                )
            )
    elif action == "monthly-sum":
        lines.append("=== Huawei Cloud Monthly Bill Summary ===")
        lines.append("Currency: %s" % (report.get("currency") or "CNY"))
        lines.append("Total consume amount: %s" % (report.get("consume_amount") if report.get("consume_amount") is not None else 0))
        lines.append("Debt amount: %s" % (report.get("debt_amount") if report.get("debt_amount") is not None else 0))
        if not report.get("bill_sums"):
            lines.append("No bill summary records returned for this cycle.")
        for s in report.get("bill_sums", [])[:20]:
            lines.append(
                "- %s | %s | consume=%s"
                % (
                    s["service_type_name"] or s["service_type_code"] or "-",
                    s["resource_type_name"] or "-",
                    s["consume_amount"] if s["consume_amount"] is not None else 0,
                )
            )
        total = report.get("total_count") or 0
        if total > 20:
            lines.append("... (%d more records, use --format json or --limit to page)" % (total - 20))
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Query Huawei Cloud BSS account balance / balance change history / monthly bill summary (read-only)."
    )
    parser.add_argument(
        "--action",
        choices=["balance", "changes", "monthly-sum"],
        default="balance",
        help="Query action (default: balance)",
    )
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--balance-type",
        choices=sorted(BALANCE_TYPES),
        default="DEBIT",
        help="Balance type for action=changes (default: DEBIT=cash account)",
    )
    parser.add_argument(
        "--begin",
        default=None,
        help="Start date YYYY-MM-DD for action=changes (balance change records)",
    )
    parser.add_argument(
        "--end",
        default=None,
        help="End date YYYY-MM-DD for action=changes (balance change records)",
    )
    parser.add_argument(
        "--revenue-expense-type",
        choices=sorted(REVENUE_EXPENSE_TYPES),
        default=None,
        help="Filter income/expense for action=changes (REVENUE or EXPENSE)",
    )
    parser.add_argument(
        "--bill-cycle",
        default=None,
        help="Billing cycle YYYY-MM for action=monthly-sum",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Page size (default: 10, max 100 for BSS)",
    )
    parser.add_argument(
        "--executor",
        choices=["sdk"],
        default="sdk",
        help="Execution mode (default: sdk — the only supported mode for BSS)",
    )
    args = parser.parse_args()

    if args.limit < 1 or args.limit > 100:
        raise QualityError("U02", "limit must be between 1 and 100 (BSS API limit)")

    with quality_context(
        skill_name="huawei-cloud-billing-balance-history",
        skill_version="1.0.0",
        trigger_type="agent",
        timeout_threshold_ms=60000,
    ) as q:
        q.input = {
            "action": args.action,
            "format": args.format,
            "balance_type": args.balance_type,
            "begin": args.begin,
            "end": args.end,
            "bill_cycle": args.bill_cycle,
            "limit": args.limit,
        }
        try:
            client = _get_client()
            if args.action == "balance":
                resp = _run_balance(client)
                report = _build_balance_report(resp)
            elif args.action == "changes":
                resp = _run_changes(client, args)
                report = _build_changes_report(resp)
            else:
                resp = _run_monthly_sum(client, args)
                report = _build_monthly_sum_report(resp)
        except QualityError:
            raise
        except Exception as e:  # noqa: BLE001 — wrap unexpected SDK errors
            raise QualityError("B01", "%s: %s" % (type(e).__name__, str(e)))

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
