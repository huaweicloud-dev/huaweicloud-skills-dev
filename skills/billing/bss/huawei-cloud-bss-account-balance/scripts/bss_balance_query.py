#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
bss_balance_query.py — Query Huawei Cloud account balance and recent (default 6 months)
account change records via the BSS (Business Support System) SDK.

Feature points:
  FP-01 Query current account balance   -> show_customer_account_balances
       (GET /v2/accounts/customer-accounts/balances)
  FP-02 Query last-N-months change records -> list_customer_account_change_records
       (GET /v2/accounts/customer-accounts/account-change-records)

Endpoints verified from huaweicloudsdkbss v2 SDK source (bss_client.py _http_info).

Usage:
  python3 scripts/bss_balance_query.py [--balance-type BALANCE_TYPE_DEBIT] [--months 6]
                                       [--begin YYYY-MM-DD] [--end YYYY-MM-DD]
                                       [--offset 0] [--limit 100] [--raw]

Credentials are read from environment variables only (never hardcoded):
  HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY
  HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK
  HW_ACCESS_KEY / HW_SECRET_KEY
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from decimal import Decimal

# Vendored skill quality reporting SDK (scripts/skill_quality_sdk.py):
# non-blocking reporting of trace_id / status / error code / cost to the
# skillsopr operations console. It never affects the query result.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from skill_quality_sdk import quality_context, QualityError  # noqa: E402

BSS_ENDPOINT = "https://bss.myhuaweicloud.com"

BALANCE_TYPES = ("BALANCE_TYPE_DEBIT", "BALANCE_TYPE_CREDIT")
DATE_FMT = "%Y-%m-%d"
MIN_LIMIT, MAX_LIMIT = 1, 100

# BSS is a global service: must use GlobalCredentials + with_endpoints.
from huaweicloudsdkcore.auth.credentials import GlobalCredentials  # noqa: E402
from huaweicloudsdkcore.exceptions.exceptions import ClientRequestException  # noqa: E402
from huaweicloudsdkbss.v2 import BssClient  # noqa: E402
from huaweicloudsdkbss.v2.model import (  # noqa: E402
    ShowCustomerAccountBalancesRequest,
    ListCustomerAccountChangeRecordsRequest,
)


def _load_credentials():
    """Load AK/SK from environment variables. Raises if missing."""
    ak = (
        os.environ.get("HUAWEI_ACCESS_KEY")
        or os.environ.get("HUAWEICLOUD_SDK_AK")
        or os.environ.get("HW_ACCESS_KEY")
    )
    sk = (
        os.environ.get("HUAWEI_SECRET_KEY")
        or os.environ.get("HUAWEICLOUD_SDK_SK")
        or os.environ.get("HW_SECRET_KEY")
    )
    if not ak or not sk:
        raise RuntimeError(
            "Huawei Cloud credentials not found. Please set HUAWEI_ACCESS_KEY/"
            "HUAWEI_SECRET_KEY (or HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK) "
            "environment variables first."
        )
    return ak, sk


def _build_client():
    cred_ak, cred_sk = _load_credentials()
    credentials = GlobalCredentials(cred_ak, cred_sk)
    return BssClient.new_builder() \
        .with_credentials(credentials) \
        .with_endpoints([BSS_ENDPOINT]) \
        .build()


def query_balance(client):
    """FP-01: query current account balance."""
    request = ShowCustomerAccountBalancesRequest()
    response = client.show_customer_account_balances(request)
    return response


def query_change_records(client, balance_type, begin, end, offset, limit):
    """FP-02: query account change records in [begin, end]."""
    request = ListCustomerAccountChangeRecordsRequest(
        balance_type=balance_type,
        trade_time_begin=begin,
        trade_time_end=end,
        offset=offset,
        limit=limit,
    )
    response = client.list_customer_account_change_records(request)
    return response


def _iso_today():
    return datetime.now().strftime("%Y-%m-%d")


def _default_range(months):
    end = datetime.now()
    begin = end - timedelta(days=30 * int(months))
    return begin.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d")


def _balance_summary(balance_resp):
    rows = []
    for acc in (balance_resp.account_balances or []):
        rows.append({
            "account_type": acc.account_type,
            "amount": acc.amount,
            "currency": acc.currency,
            "credit_amount": acc.credit_amount,
        })
    return {
        "account_balances": rows,
        "debt_amount": balance_resp.debt_amount,
        "currency": balance_resp.currency,
    }


def _records_summary(records_resp):
    records = []
    for r in (records_resp.records or []):
        records.append({
            "trade_time": r.trade_time,
            "trade_id": r.trade_id,
            "trade_detail_type": r.trade_detail_type,
            "change_amount": r.change_amount,
            "balance_after_change": r.balance_after_change,
            # CustomerAccountChangeRecord has revenue_expense_type (no 'type' field)
            "revenue_expense_type": r.revenue_expense_type,
        })
    return {
        "total_count": records_resp.total_count,
        "currency": records_resp.currency,
        "records": records,
    }


def _json_default(obj):
    """json.dumps default handler: serialize Decimal (BSS amounts) as float/str."""
    if isinstance(obj, Decimal):
        return float(obj)
    return str(obj)


def _validate_args(args):
    """Entry-level input validation with clear, actionable error messages.

    Returns (begin, end) date range as strings.
    Raises QualityError with a readable message on invalid input.
    """
    # ISSUE-001: --begin / --end must be provided together (no silent fallback)
    if bool(args.begin) != bool(args.end):
        raise QualityError(
            "U02",
            "--begin and --end must be provided together. "
            "Example: --begin 2026-02-10 --end 2026-08-10. "
            "If you only want the default window, omit both and use --months.",
        )

    # ISSUE-003: balance-type enum validation
    if args.balance_type not in BALANCE_TYPES:
        raise QualityError(
            "U02",
            "Invalid --balance-type '{}'. Allowed values: {}.".format(
                args.balance_type, ", ".join(BALANCE_TYPES)
            ),
        )

    # ISSUE-003: limit range validation (BSS caps page size at 100)
    if args.limit < MIN_LIMIT or args.limit > MAX_LIMIT:
        raise QualityError(
            "U02",
            "--limit must be between {} and {} (BSS caps page size at 100), "
            "got {}.".format(MIN_LIMIT, MAX_LIMIT, args.limit),
        )

    # --months must be a positive integer
    if args.months < 1:
        raise QualityError(
            "U02",
            "--months must be a positive integer (>= 1), got {}.".format(args.months),
        )

    # ISSUE-003: date format validation
    def _parse_date(value, name):
        try:
            return datetime.strptime(value, DATE_FMT)
        except (TypeError, ValueError):
            raise QualityError(
                "U02",
                "Invalid {} '{}'. Expected date format YYYY-MM-DD, "
                "e.g. 2026-02-10.".format(name, value),
            )

    if args.begin and args.end:
        begin_dt = _parse_date(args.begin, "--begin")
        end_dt = _parse_date(args.end, "--end")
        # ISSUE-003: begin <= end validation (reversed range)
        if begin_dt > end_dt:
            raise QualityError(
                "U02",
                "--begin ({}) must be earlier than or equal to --end ({}). "
                "Please swap the two dates.".format(args.begin, args.end),
            )
        return args.begin, args.end

    # Default window: last N months (ISSUE-002: --months is parsed as int by argparse)
    return _default_range(args.months)


def _friendly_error(exc):
    """Render a ClientRequestException into a readable message."""
    err_code = getattr(exc, "error_code", None) or "unknown"
    err_msg = getattr(exc, "error_msg", None) or str(exc)
    request_id = getattr(exc, "request_id", None)
    hint = ""
    if "limit" in str(err_msg).lower() or "400" in str(getattr(exc, "status_code", "")):
        hint = " Suggestion: reduce --limit (max 100) or narrow the date range."
    elif "permission" in str(err_msg).lower() or "denied" in str(err_msg).lower():
        hint = " Suggestion: check IAM permissions bss:balance:view / bss:bill:view."
    msg = "BSS API error: code={}, message={}".format(err_code, err_msg)
    if request_id:
        msg += " (request_id={})".format(request_id)
    return msg + hint


def main():
    parser = argparse.ArgumentParser(
        description="Query Huawei Cloud account balance and last-N-months change records (BSS)."
    )
    parser.add_argument("--balance-type", default="BALANCE_TYPE_DEBIT",
                        help="BALANCE_TYPE_DEBIT (cash) or BALANCE_TYPE_CREDIT (credit)")
    parser.add_argument("--months", type=int, default=6,
                        help="Query window in months (default 6, ~half a year)")
    parser.add_argument("--begin", default=None,
                        help="Explicit start date YYYY-MM-DD (must be paired with --end)")
    parser.add_argument("--end", default=None,
                        help="Explicit end date YYYY-MM-DD (must be paired with --begin)")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=100,
                        help="Page size for change records (1-100)")
    parser.add_argument("--raw", action="store_true",
                        help="Print raw API response instead of the summary")
    args = parser.parse_args()

    # ISSUE-001/002/003: entry-level validation with readable errors
    try:
        begin, end = _validate_args(args)
    except QualityError as exc:
        print("Error: {}".format(exc.message), file=sys.stderr)
        return 1

    with quality_context("huawei-cloud-bss-account-balance") as q:
        q.input = {
            "balance_type": args.balance_type,
            "begin": begin,
            "end": end,
            "offset": args.offset,
            "limit": args.limit,
        }
        try:
            client = _build_client()

            balance_resp = query_balance(client)
            records_resp = query_change_records(
                client, args.balance_type, begin, end, args.offset, args.limit
            )
        except ClientRequestException as exc:
            # ISSUE-003: readable error instead of raw SDK traceback
            msg = _friendly_error(exc)
            print("Error: {}".format(msg), file=sys.stderr)
            q.fail("N03", msg)
            return 1
        except RuntimeError as exc:
            # e.g. credentials not found
            msg = str(exc)
            print("Error: {}".format(msg), file=sys.stderr)
            q.fail("C01", msg)
            return 1

        if args.raw:
            result = {
                "balance": balance_resp.to_dict(),
                "change_records": records_resp.to_dict(),
            }
        else:
            result = {
                "query_range": {"begin": begin, "end": end},
                "balance": _balance_summary(balance_resp),
                "change_records": _records_summary(records_resp),
            }
        q.output = result
        # default=_json_default handles Decimal amounts returned by the BSS SDK
        print(json.dumps(result, ensure_ascii=False, indent=2, default=_json_default))
        return 0


if __name__ == "__main__":
    sys.exit(main())
