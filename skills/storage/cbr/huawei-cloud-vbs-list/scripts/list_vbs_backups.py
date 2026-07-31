#!/usr/bin/env python3
"""List Huawei Cloud VBS/CBR backups and print a concise summary.

Reads AK/SK from environment variables (HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY or
HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK) and lists backups via the CBR SDK.

Usage:
  python3 list_vbs_backups.py --region cn-north-4 [--status available] \
      [--name backup_for_image] [--resource-type OS::Nova::Server] \
      [--vault-id <id>] [--limit 50] [--offset 0]
"""

import argparse
import os
import sys


def load_credentials():
    access_key_id = os.environ.get("HUAWEI_ACCESS_KEY") or os.environ.get("HUAWEICLOUD_SDK_AK")
    secret_value = os.environ.get("HUAWEI_SECRET_KEY") or os.environ.get("HUAWEICLOUD_SDK_SK")
    return access_key_id, secret_value


def main():
    parser = argparse.ArgumentParser(description="List Huawei Cloud VBS/CBR backups")
    parser.add_argument("--region", required=True, help="Huawei Cloud region, e.g. cn-north-4")
    parser.add_argument("--status", help="Filter by status, e.g. available")
    parser.add_argument("--name", help="Filter by backup name (fuzzy)")
    parser.add_argument("--resource-type", help="Filter by resource type, e.g. OS::Nova::Server")
    parser.add_argument("--vault-id", help="Filter by vault ID")
    parser.add_argument("--start-time", help="Start time, e.g. 2026-01-01T00:00:00Z")
    parser.add_argument("--end-time", help="End time, e.g. 2026-12-31T23:59:59Z")
    parser.add_argument("--limit", type=int, default=50, help="Page size (default 50)")
    parser.add_argument("--offset", type=int, default=0, help="Page offset (default 0)")
    args = parser.parse_args()

    access_key_id, secret_value = load_credentials()
    if not access_key_id or not secret_value:
        print("ERROR: AK/SK not found. Set HUAWEICLOUD_SDK_AK and HUAWEICLOUD_SDK_SK "
              "(or HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY) environment variables.",
              file=sys.stderr)
        sys.exit(1)

    try:
        from huaweicloudsdkcore.auth.credentials import BasicCredentials
        from huaweicloudsdkcbr.v1.region.cbr_region import CbrRegion
        from huaweicloudsdkcbr.v1 import CbrClient, ListBackupsRequest
    except ImportError as e:
        print(f"ERROR: missing dependency: {e}. Run: pip install huaweicloudsdkcbr",
              file=sys.stderr)
        sys.exit(1)

    credentials = BasicCredentials(access_key_id, secret_value)
    client = CbrClient.new_builder() \
        .with_credentials(credentials) \
        .with_region(CbrRegion.value_of(args.region)) \
        .build()

    request = ListBackupsRequest(
        limit=args.limit,
        offset=args.offset,
    )
    if args.status:
        request.status = args.status
    if args.name:
        request.name = args.name
    if args.resource_type:
        request.resource_type = args.resource_type
    if args.vault_id:
        request.vault_id = args.vault_id
    if args.start_time:
        request.start_time = args.start_time
    if args.end_time:
        request.end_time = args.end_time

    try:
        response = client.list_backups(request)
    except Exception as e:
        print(f"ERROR: ListBackups failed: {e}", file=sys.stderr)
        sys.exit(1)

    backups = response.backups or []
    if not backups:
        print("No backups found.")
        return

    print(f"{'ID':<38} {'Name':<40} {'Status':<16} {'ResourceType':<20} {'CreatedAt'}")
    for b in backups:
        print(f"{str(b.id):<38} {str(b.name or ''):<40} {str(b.status or ''):<16} "
              f"{str(b.resource_type or ''):<20} {str(b.created_at or '')}")
    print(f"\nTotal: {len(backups)} (page offset={args.offset}, limit={args.limit}, "
          f"matched_count={response.count})")


if __name__ == "__main__":
    main()
