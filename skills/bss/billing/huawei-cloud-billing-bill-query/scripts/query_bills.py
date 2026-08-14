#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query Huawei Cloud BSS bills (账单/费用) for the current account within one month.

Primary executor : huaweicloudsdkbss Python SDK (BssClient) — the KooCLI (hcloud)
                   does NOT support the BSS service, so the SDK is the only
                   execution path (verified: `hcloud BSS --help` -> "Unsupported
                   service: BSS").

Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py) —
                   every run reports trace_id / status (success|biz_fail|sys_fail)
                   / error code / cost to the skillsopr operations console.
                   Reporting is non-blocking and fails silently.

Read-only skill: queries only, never creates, modifies or deletes any billing
resource. The time scope is limited to ONE billing cycle (month).

Actions:
  fee-records      — bill fee records (账单费用记录/账单明细) for one bill_cycle (YYYY-MM)
  res-fee-records  — resource fee records (流水账单/资源费用记录) for one cycle (YYYY-MM)
  breakdown        — monthly cost breakdown (月度成本分析) for one shared_month (YYYY-MM)

Usage:
  python3 query_bills.py --action fee-records --bill-cycle 2026-07 [--format text|json]
  python3 query_bills.py --action res-fee-records --cycle 2026-07 [--bill-date-begin 2026-07-01 --bill-date-end 2026-07-31]
  python3 query_bills.py --action breakdown --shared-month 2026-07 [--limit 20]

Examples:
  python3 query_bills.py                                  # fee-records for current month
  python3 query_bills.py --action res-fee-records --cycle 2026-07
  python3 query_bills.py --action breakdown --shared-month 2026-07 --format json
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

_CYCLE_RE = re.compile(r"^\d{4}-\d{2}$")
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

ACTIONS = ("fee-records", "res-fee-records", "breakdown")


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


def _validate_cycle(value, label):
    if not value:
        raise QualityError("U01", "%s is required (format YYYY-MM)" % label)
    if not _CYCLE_RE.match(value):
        raise QualityError("U02", "%s must be in YYYY-MM format, got: %s" % (label, value))
    try:
        datetime.strptime(value, "%Y-%m")
    except ValueError:
        raise QualityError("U02", "%s is not a valid month, got: %s" % (label, value))
    return value


def _validate_date_range(begin, end, cycle=None):
    if begin and not _DATE_RE.match(begin):
        raise QualityError("U02", "bill_date_begin must be a date in YYYY-MM-DD format, got: %s" % begin)
    if end and not _DATE_RE.match(end):
        raise QualityError("U02", "bill_date_end must be a date in YYYY-MM-DD format, got: %s" % end)
    if begin and end and begin > end:
        raise QualityError("U02", "bill_date_begin (%s) must not be later than bill_date_end (%s)" % (begin, end))
    if cycle:
        for label, day in (("bill_date_begin", begin), ("bill_date_end", end)):
            if day and not day.startswith(cycle):
                raise QualityError(
                    "U02",
                    "%s (%s) must fall within the billing cycle %s" % (label, day, cycle),
                )


def _validate_pagination(offset, limit):
    """Validate --offset (>=1) and --limit (1-100) client-side (BUG-1 fix)."""
    if offset is not None and offset < 1:
        raise QualityError("U02", "offset must be >= 1, got: %s" % offset)
    if limit is not None and (limit < 1 or limit > 100):
        raise QualityError("U02", "limit must be between 1 and 100, got: %s" % limit)


def _validate_action_params(args):
    """Reject parameters that do not apply to the selected action (BUG-2 fix).

    Previously these were silently ignored (e.g. --shared-month with
    fee-records queried the current month without any warning, and
    --bill-date-* with breakdown was dropped). Mismatches now fail fast
    with a friendly U02 error instead of leaking raw SDK errors.
    """
    if args.action != "breakdown" and args.shared_month:
        raise QualityError(
            "U02",
            "--shared-month is only valid with --action breakdown, got action=%s" % args.action,
        )
    if args.action == "breakdown":
        if args.bill_date_begin or args.bill_date_end:
            raise QualityError(
                "U02",
                "--bill-date-begin/--bill-date-end are not supported by --action breakdown",
            )
        if args.bill_type:
            raise QualityError("U02", "--bill-type is not supported by --action breakdown")


def _current_month():
    return datetime.now().strftime("%Y-%m")


def _run_fee_records(client, args):
    from huaweicloudsdkbss.v2 import ListCustomerBillsFeeRecordsRequest

    bill_cycle = _validate_cycle(args.bill_cycle or args.cycle or _current_month(), "bill_cycle")
    _validate_date_range(args.bill_date_begin, args.bill_date_end, bill_cycle)

    req = ListCustomerBillsFeeRecordsRequest(
        bill_cycle=bill_cycle,
        bill_date_begin=args.bill_date_begin,
        bill_date_end=args.bill_date_end,
        bill_type=args.bill_type,
        offset=args.offset,
        limit=args.limit,
    )
    return client.list_customer_bills_fee_records(req)


def _run_res_fee_records(client, args):
    from huaweicloudsdkbss.v2 import ListCustomerselfResourceRecordsRequest

    cycle = _validate_cycle(args.cycle or args.bill_cycle or _current_month(), "cycle")
    _validate_date_range(args.bill_date_begin, args.bill_date_end, cycle)

    req = ListCustomerselfResourceRecordsRequest(
        cycle=cycle,
        bill_date_begin=args.bill_date_begin,
        bill_date_end=args.bill_date_end,
        bill_type=args.bill_type,
        offset=args.offset,
        limit=args.limit,
    )
    return client.list_customerself_resource_records(req)


def _run_breakdown(client, args):
    from huaweicloudsdkbss.v2 import ListCustomerBillsMonthlyBreakDownRequest

    shared_month = _validate_cycle(args.shared_month or args.cycle or args.bill_cycle or _current_month(), "shared_month")

    req = ListCustomerBillsMonthlyBreakDownRequest(
        shared_month=shared_month,
        offset=args.offset,
        limit=args.limit,
    )
    return client.list_customer_bills_monthly_break_down(req)


def _build_fee_records_report(resp, bill_cycle):
    records = []
    for r in (resp.records or []):
        records.append({
            "bill_cycle": r.bill_cycle,
            "bill_type": r.bill_type,
            "service_type_name": r.service_type_name,
            "resource_type_name": r.resource_type_name,
            "region_name": r.region_name,
            "charging_mode": r.charging_mode,
            "consume_time": r.consume_time,
            "trade_time": r.trade_time,
            "official_amount": _to_number(r.official_amount),
            "official_discount_amount": _to_number(r.official_discount_amount),
            "erase_amount": _to_number(r.erase_amount),
            "consume_amount": _to_number(r.consume_amount),
            "cash_amount": _to_number(r.cash_amount),
            "credit_amount": _to_number(r.credit_amount),
            "coupon_amount": _to_number(r.coupon_amount),
            "stored_value_card_amount": _to_number(r.stored_value_card_amount),
            "bonus_amount": _to_number(r.bonus_amount),
            "debt_amount": _to_number(r.debt_amount),
            "writeoff_amount": _to_number(r.writeoff_amount),
            "enterprise_project_name": r.enterprise_project_name,
            "account_name": r.account_name,
        })
    return {
        "action": "fee-records",
        "bill_cycle": bill_cycle,
        "total_count": _to_number(resp.total_count),
        "currency": resp.currency,
        "records": records,
    }


def _build_res_fee_records_report(resp, cycle):
    records = []
    for r in (resp.fee_records or []):
        records.append({
            "bill_date": r.bill_date,
            "bill_type": r.bill_type,
            "cloud_service_type_name": r.cloud_service_type_name,
            "resource_type_name": r.resource_type_name,
            "region_name": r.region_name,
            "resource_name": r.resource_name,
            "resource_id": r.resource_id,
            "product_name": r.product_name,
            "charge_mode": r.charge_mode,
            "trade_time": r.trade_time,
            "usage": _to_number(r.usage),
            "unit": r.unit,
            "unit_price": _to_number(r.unit_price),
            "official_amount": _to_number(r.official_amount),
            "discount_amount": _to_number(r.discount_amount),
            "amount": _to_number(r.amount),
            "cash_amount": _to_number(r.cash_amount),
            "credit_amount": _to_number(r.credit_amount),
            "coupon_amount": _to_number(r.coupon_amount),
            "flexipurchase_coupon_amount": _to_number(r.flexipurchase_coupon_amount),
            "stored_card_amount": _to_number(r.stored_card_amount),
            "debt_amount": _to_number(r.debt_amount),
            "enterprise_project_name": r.enterprise_project_name,
        })
    return {
        "action": "res-fee-records",
        "cycle": cycle,
        "total_count": _to_number(resp.total_count),
        "currency": resp.currency,
        "records": records,
    }


def _build_breakdown_report(resp, shared_month):
    details = []
    for d in (resp.details or []):
        details.append({
            "shared_month": d.shared_month,
            "bill_cycle": d.bill_cycle,
            "bill_type": d.bill_type,
            "service_type_name": d.service_type_name,
            "resource_type_name": d.resource_type_name,
            "region_name": d.region_name,
            "resource_name": d.resource_name,
            "resource_id": d.resource_id,
            "charging_mode": d.charging_mode,
            "consume_amount": _to_number(d.consume_amount),
            "current_month_amortized_amount": _to_number(d.current_month_amortized_amount),
            "past_months_amortized_amount": _to_number(d.past_months_amortized_amount),
            "future_months_amortized_amount": _to_number(d.future_months_amortized_amount),
            "amortized_cash_amount": _to_number(d.amortized_cash_amount),
            "amortized_credit_amount": _to_number(d.amortized_credit_amount),
            "amortized_coupon_amount": _to_number(d.amortized_coupon_amount),
            "enterprise_project_name": d.enterprise_project_name,
        })
    return {
        "action": "breakdown",
        "shared_month": shared_month,
        "total_count": _to_number(resp.total_count),
        "currency": resp.currency,
        "details": details,
    }


def _format_text(report):
    lines = []
    action = report.get("action")
    if action == "fee-records":
        lines.append("Bill fee records (账单费用记录) for %s — total %s, currency %s" % (
            report.get("bill_cycle"), report.get("total_count"), report.get("currency")))
        for r in report.get("records") or []:
            lines.append("\t%s | %s | %s | consume=%s | cash=%s | coupon=%s" % (
                r.get("consume_time") or r.get("trade_time") or "",
                r.get("service_type_name") or "",
                r.get("resource_type_name") or "",
                r.get("consume_amount"),
                r.get("cash_amount"),
                r.get("coupon_amount")))
    elif action == "res-fee-records":
        lines.append("Resource fee records (流水账单) for %s — total %s, currency %s" % (
            report.get("cycle"), report.get("total_count"), report.get("currency")))
        for r in report.get("records") or []:
            lines.append("\t%s | %s | %s | amount=%s | cash=%s" % (
                r.get("bill_date") or "",
                r.get("cloud_service_type_name") or "",
                r.get("resource_name") or "",
                r.get("amount"),
                r.get("cash_amount")))
    elif action == "breakdown":
        lines.append("Monthly cost breakdown (月度成本分析) for %s — total %s, currency %s" % (
            report.get("shared_month"), report.get("total_count"), report.get("currency")))
        for d in report.get("details") or []:
            lines.append("\t%s | %s | %s | consume=%s | amortized_current=%s" % (
                d.get("service_type_name") or "",
                d.get("resource_name") or "",
                d.get("charging_mode") or "",
                d.get("consume_amount"),
                d.get("current_month_amortized_amount")))
    else:
        lines.append(json.dumps(report, ensure_ascii=False, indent=2))
    if not lines[1:]:
        lines.append("\t(no records found for this billing cycle)")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Query Huawei Cloud BSS bills for the current account within one month (read-only)."
    )
    parser.add_argument("--action", choices=ACTIONS, default="fee-records",
                        help="Query action (default: fee-records)")
    parser.add_argument("--bill-cycle", help="Billing cycle YYYY-MM (fee-records)")
    parser.add_argument("--cycle", help="Billing cycle YYYY-MM (res-fee-records)")
    parser.add_argument("--shared-month", help="Shared month YYYY-MM (breakdown)")
    parser.add_argument("--bill-date-begin", dest="bill_date_begin",
                        help="Start date YYYY-MM-DD (fee-records / res-fee-records)")
    parser.add_argument("--bill-date-end", dest="bill_date_end",
                        help="End date YYYY-MM-DD (fee-records / res-fee-records)")
    parser.add_argument("--bill-type", choices=["1", "2", "3", "4", "5"],
                        help="Bill type: 1=consumption, 2=refund, 3=adjustment, 4=timed, 5=arrears")
    parser.add_argument("--offset", type=int, default=None, help="Page offset (>=1)")
    parser.add_argument("--limit", type=int, default=10, help="Max records per page (1-100)")
    parser.add_argument("--format", choices=["text", "json"], default="text",
                        help="Output format (default: text)")
    args = parser.parse_args()

    with quality_context(
        skill_name="huawei-cloud-billing-bill-query",
        skill_version="1.0.0",
        trigger_type="agent",
        timeout_threshold_ms=120000,
    ) as q:
        q.input = {
            "action": args.action,
            "bill_cycle": args.bill_cycle,
            "cycle": args.cycle,
            "shared_month": args.shared_month,
            "bill_date_begin": args.bill_date_begin,
            "bill_date_end": args.bill_date_end,
            "bill_type": args.bill_type,
            "offset": args.offset,
            "limit": args.limit,
        }
        # Fail fast on action/parameter mismatches and out-of-range values
        # instead of silently ignoring them or leaking raw SDK errors.
        _validate_action_params(args)
        _validate_pagination(args.offset, args.limit)
        client = _get_client()
        if args.action == "fee-records":
            resp = _run_fee_records(client, args)
            report = _build_fee_records_report(resp, args.bill_cycle or args.cycle or _current_month())
        elif args.action == "res-fee-records":
            resp = _run_res_fee_records(client, args)
            report = _build_res_fee_records_report(resp, args.cycle or args.bill_cycle or _current_month())
        else:
            resp = _run_breakdown(client, args)
            report = _build_breakdown_report(resp, args.shared_month or args.cycle or args.bill_cycle or _current_month())

        q.output = {"action": report["action"], "total_count": report.get("total_count")}
        result = json.dumps(report, ensure_ascii=False, indent=2) if args.format == "json" else _format_text(report)
        count = report.get("total_count") or 0
        if count == 0:
            q.fail("U03", "No bill records found for the requested billing cycle")
            print(result)
        else:
            print(result)


if __name__ == "__main__":
    try:
        main()
    except QualityError as e:
        print("ERROR: %s (%s)" % (e.message, e.error_code), file=sys.stderr)
        sys.exit(1)
    except Exception as e:  # noqa: BLE001
        print("ERROR: %s" % e, file=sys.stderr)
        sys.exit(1)
