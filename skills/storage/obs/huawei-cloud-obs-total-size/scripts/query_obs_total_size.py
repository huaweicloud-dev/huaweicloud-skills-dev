#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Query the total size of Huawei Cloud OBS buckets.

Prints ONLY the size value (a single number, in bytes by default) — nothing else.

Primary executor : KooCLI obsutil-backed `hcloud OBS ls obs://<bucket>/ -du -bf=raw`
                   (returns the exact bucket size in bytes; `hcloud OBS ls` lists buckets).
Fallback executor: huaweicloudsdkobs Python SDK
                   (lists buckets, lists objects per bucket and sums their sizes).

Usage:
  python3 query_obs_total_size.py [--bucket <name>] [--all]
      [--unit bytes|kb|mb|gb] [--human] [--region <region>] [--executor auto|cli|sdk]

Examples:
  python3 query_obs_total_size.py --bucket my-bucket          # single bucket size in bytes
  python3 query_obs_total_size.py --all                       # total across all buckets
  python3 query_obs_total_size.py --all --unit mb             # total in MB
  python3 query_obs_total_size.py --all --human               # human readable
"""

import argparse
import os
import re
import subprocess
import sys


def _resolve_credentials():
    """Resolve AK/SK from common Huawei Cloud environment variables."""
    a_key = (
        os.environ.get("HUAWEI_ACCESS_KEY")
        or os.environ.get("HUAWEICLOUD_SDK_AK")
        or os.environ.get("HUAWEI_CLOUD_ACCESS_KEY")
        or os.environ.get("HW_ACCESS_KEY")
    )
    s_key = (
        os.environ.get("HUAWEI_SECRET_KEY")
        or os.environ.get("HUAWEICLOUD_SDK_SK")
        or os.environ.get("HUAWEI_CLOUD_SECRET_KEY")
        or os.environ.get("HW_SECRET_KEY")
    )
    return a_key, s_key


def _build_sdk_client(region):
    from huaweicloudsdkobs.v1.obs_client import ObsClient
    from huaweicloudsdkobs.v1.obs_credentials import ObsCredentials
    from huaweicloudsdkobs.v1.region.obs_region import ObsRegion

    a_key, s_key = _resolve_credentials()
    if not a_key or not s_key:
        raise RuntimeError(
            "AK/SK not found. Set HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY "
            "(or HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK) in the environment."
        )
    credentials = ObsCredentials(a_key, s_key)
    return ObsClient.new_builder().with_credentials(credentials).with_region(ObsRegion.value_of(region)).build()


def _run_cli(cmd):
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "").strip())
    return proc.stdout


def list_buckets_cli():
    """List all bucket names via `hcloud OBS ls`."""
    out = _run_cli(["hcloud", "OBS", "ls"])
    return re.findall(r"obs://([^\s/]+)", out)


def _parse_cli_size(text):
    """Parse the '[DU] Total bucket size: N[unit]' line into bytes.

    Tolerant of obsutil output variations: a bare integer (e.g. `5002295`),
    an integer with a 'B' suffix (`5002295B`), or a human-readable value with
    a unit suffix (`4.77MB`). Returns None if the line cannot be parsed.
    """
    m = re.search(r"Total bucket size:\s*([\d.]+)\s*([KMGTP]?B?)\b", text, re.IGNORECASE)
    if m is None:
        return None
    num = float(m.group(1))
    unit = (m.group(2) or "B").upper()
    factors = {
        "B": 1,
        "KB": 1024,
        "MB": 1024 ** 2,
        "GB": 1024 ** 3,
        "TB": 1024 ** 4,
        "PB": 1024 ** 5,
    }
    return int(num * factors.get(unit, 1))


def bucket_size_cli(bucket):
    """Get exact bucket size in bytes via `hcloud OBS ls obs://<bucket>/ -du -bf=raw`."""
    out = _run_cli(["hcloud", "OBS", "ls", "obs://%s" % bucket, "-du", "-bf=raw"])
    size = _parse_cli_size(out)
    if size is None:
        raise RuntimeError("Could not parse 'Total bucket size' from hcloud output for %s" % bucket)
    return size


def total_size_cli(buckets):
    return sum(bucket_size_cli(b) for b in buckets)


def list_buckets_sdk(client):
    from huaweicloudsdkobs.v1.model import ListBucketsRequest

    res = client.list_buckets(ListBucketsRequest()).to_dict()
    buckets = (res.get("buckets") or {}).get("bucket") or []
    return [(b.get("name"), b.get("location") or "") for b in buckets]


def bucket_size_sdk(client, bucket):
    """Sum sizes of all objects in a bucket via the SDK (paginated)."""
    from huaweicloudsdkobs.v1.model import ListObjectsRequest

    total = 0
    marker = None
    while True:
        req = ListObjectsRequest(bucket_name=bucket, max_keys=1000, marker=marker)
        d = client.list_objects(req).to_dict()
        for c in d.get("contents") or []:
            total += int(c.get("size") or 0)
        marker = d.get("next_marker")
        if not d.get("is_truncated") or not marker:
            break
    return total


def total_size_sdk(client, buckets, default_region):
    """Sum sizes of buckets via the SDK. Buckets may live in different regions;
    a client bound to the bucket's own location is used when known."""
    total = 0
    for entry in buckets:
        if isinstance(entry, tuple):
            name, loc = entry
        else:
            name, loc = entry, ""
        region = loc or default_region
        region = region.replace("-oss-", "-").split(".")[0]
        if not region:
            region = default_region
        try:
            c = _build_sdk_client(region)
        except Exception:
            c = client
        total += bucket_size_sdk(c, name)
    return total


def format_size(value, unit, human):
    if human:
        size = float(value)
        for u in ("B", "KB", "MB", "GB", "TB"):
            if size < 1024 or u == "TB":
                return "%.2f%s" % (size, u)
            size /= 1024
        return str(int(value))
    if unit == "bytes":
        return str(int(value))
    factors = {"kb": 1024.0, "mb": 1024.0 * 1024.0, "gb": 1024.0 ** 3}
    if unit in factors:
        return "%.2f" % (value / factors[unit])
    return str(int(value))

def main():
    parser = argparse.ArgumentParser(
        description="Query total size of Huawei Cloud OBS buckets. Prints ONLY the size value."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--bucket", default="", help="OBS bucket name; total size of this bucket only")
    group.add_argument(
        "--all", action="store_true",
        help="Total size across all buckets (default when --bucket is not given)",
    )
    parser.add_argument(
        "--unit", default="bytes", choices=["bytes", "kb", "mb", "gb"],
        help="Output unit (default bytes)",
    )
    parser.add_argument("--human", action="store_true", help="Human readable size (e.g. 4.77MB)")
    parser.add_argument("--region", default="cn-north-4", help="Huawei Cloud region (default cn-north-4)")
    parser.add_argument(
        "--executor", default="auto", choices=["auto", "cli", "sdk"],
        help="Execution method: cli (hcloud obsutil), sdk (python SDK), auto (try cli first, fallback to sdk)",
    )
    args = parser.parse_args()

    buckets = [args.bucket] if args.bucket else None

    if args.executor == "cli":
        names = buckets if buckets else list_buckets_cli()
        total = total_size_cli(names)
    elif args.executor == "sdk":
        client = _build_sdk_client(args.region)
        all_buckets = list_buckets_sdk(client)
        if buckets:
            loc_map = {n: (n, loc) for n, loc in all_buckets}
            names = [loc_map.get(b, (b, "")) for b in buckets]
        else:
            names = all_buckets
        total = total_size_sdk(client, names, args.region)
    else:  # auto
        try:
            names = buckets if buckets else list_buckets_cli()
            total = total_size_cli(names)
        except Exception:
            client = _build_sdk_client(args.region)
            all_buckets = list_buckets_sdk(client)
            if buckets:
                loc_map = {n: (n, loc) for n, loc in all_buckets}
                names = [loc_map.get(b, (b, "")) for b in buckets]
            else:
                names = all_buckets
            total = total_size_sdk(client, names, args.region)

    print(format_size(total, args.unit, args.human))


if __name__ == "__main__":
    main()
