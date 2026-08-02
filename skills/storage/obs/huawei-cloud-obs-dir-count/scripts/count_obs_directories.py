#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Count the number of directories (folders) in a Huawei Cloud OBS bucket.

Prints ONLY the count (a single integer) — nothing else.

Primary executor : KooCLI obsutil-backed `hcloud OBS ls <cloud_url> -d`
                   (counts immediate subdirectories at the given level).
Fallback executor: huaweicloudsdkobs Python SDK
                   (supports immediate and recursive directory counting).

Usage:
  python3 count_obs_directories.py --bucket <bucket> [--prefix <prefix>]
      [--recursive] [--region <region>] [--executor cli|sdk|auto]

Examples:
  python3 count_obs_directories.py --bucket my-bucket
  python3 count_obs_directories.py --bucket my-bucket --prefix photos
  python3 count_obs_directories.py --bucket my-bucket --recursive
"""

import argparse
import os
import re
import subprocess
import sys


def _get_ak_sk():
    """Resolve AK/SK from common Huawei Cloud environment variables."""
    ak = (
        os.environ.get("HUAWEI_ACCESS_KEY")
        or os.environ.get("HUAWEICLOUD_SDK_AK")
        or os.environ.get("HUAWEI_CLOUD_ACCESS_KEY")
        or os.environ.get("HW_ACCESS_KEY")
    )
    sk = (
        os.environ.get("HUAWEI_SECRET_KEY")
        or os.environ.get("HUAWEICLOUD_SDK_SK")
        or os.environ.get("HUAWEI_CLOUD_SECRET_KEY")
        or os.environ.get("HW_SECRET_KEY")
    )
    return ak, sk


def _build_sdk_client(region):
    from huaweicloudsdkobs.v1.obs_client import ObsClient
    from huaweicloudsdkobs.v1.obs_credentials import ObsCredentials
    from huaweicloudsdkobs.v1.region.obs_region import ObsRegion

    ak, sk = _get_ak_sk()
    if not ak or not sk:
        raise RuntimeError(
            "AK/SK not found. Set HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY "
            "(or HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK) in the environment."
        )
    credentials = ObsCredentials(ak, sk)
    return ObsClient.new_builder().with_credentials(credentials).with_region(ObsRegion.value_of(region)).build()


def _parse_folder_number(text):
    m = re.search(r"Folder number:\s*(\d+)", text)
    return int(m.group(1)) if m else None


def count_cli_immediate(bucket, prefix):
    """Count immediate subdirectories under bucket/prefix via hcloud OBS ls -d."""
    url = "obs://%s" % bucket
    if prefix:
        url += "/" + prefix.strip("/")
    url += "/"
    proc = subprocess.run(
        ["hcloud", "OBS", "ls", url, "-d"],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "").strip())
    n = _parse_folder_number(proc.stdout)
    if n is None:
        raise RuntimeError("Could not parse 'Folder number' from hcloud output")
    return n


def count_sdk_immediate(client, bucket, prefix):
    """Count immediate subdirectories via SDK (delimiter='/'), paginated."""
    from huaweicloudsdkobs.v1.model import ListObjectsRequest

    # OBS lists delimiter groups only when the prefix ends with '/', otherwise
    # it may return the folder marker itself instead of its children.
    if prefix and not prefix.endswith("/"):
        prefix = prefix + "/"

    count = 0
    marker = None
    while True:
        req = ListObjectsRequest(
            bucket_name=bucket,
            prefix=prefix or None,
            delimiter="/",
            max_keys=1000,
            marker=marker,
        )
        d = client.list_objects(req).to_dict()
        count += len(d.get("common_prefixes") or [])
        marker = d.get("next_marker")
        if not d.get("is_truncated") or not marker:
            break
    return count


def count_sdk_recursive(client, bucket, prefix):
    """Count all directories (all levels) under bucket/prefix via SDK.

    Walks every object key and records each ancestor prefix ending with '/'.
    Zero-byte folder-marker keys (e.g. "photos/") are directories themselves.
    When a prefix is given, only directories strictly under it are counted
    (the prefix itself is not included).
    """
    from huaweicloudsdkobs.v1.model import ListObjectsRequest

    base = prefix.rstrip("/") + "/" if prefix else ""

    dirs = set()
    marker = None
    while True:
        req = ListObjectsRequest(
            bucket_name=bucket,
            prefix=prefix or None,
            max_keys=1000,
            marker=marker,
        )
        d = client.list_objects(req).to_dict()
        for c in d.get("contents") or []:
            key = c.get("key") or ""
            if base:
                if not key.startswith(base):
                    continue
                rel = key[len(base):]
            else:
                rel = key
            parts = rel.split("/")
            # Ancestor prefixes of each object key; a trailing empty part (folder
            # marker) makes the marker itself a directory.
            for i in range(1, len(parts)):
                dirs.add("/".join(parts[:i]) + "/")
        marker = d.get("next_marker")
        if not d.get("is_truncated") or not marker:
            break
    return len(dirs)


def main():
    parser = argparse.ArgumentParser(
        description="Count directories in a Huawei Cloud OBS bucket. Prints ONLY the count."
    )
    parser.add_argument("--bucket", required=True, help="OBS bucket name")
    parser.add_argument("--prefix", default="", help="Optional directory prefix to count under")
    parser.add_argument("--recursive", action="store_true", help="Count all nested directories")
    parser.add_argument("--region", default="cn-north-4", help="Huawei Cloud region (default cn-north-4)")
    parser.add_argument(
        "--executor", default="auto", choices=["auto", "cli", "sdk"],
        help="Execution method: cli (hcloud obsutil), sdk (python SDK), auto (try cli first, fallback to sdk)",
    )
    args = parser.parse_args()

    recursive = args.recursive

    # --- Auto: prefer CLI for immediate counts, SDK for recursive ---
    if args.executor == "auto":
        if recursive:
            client = _build_sdk_client(args.region)
            print(count_sdk_recursive(client, args.bucket, args.prefix))
            return
        try:
            print(count_cli_immediate(args.bucket, args.prefix))
            return
        except Exception:
            client = _build_sdk_client(args.region)
            print(count_sdk_immediate(client, args.bucket, args.prefix))
            return

    # --- Explicit executor ---
    if args.executor == "cli":
        if recursive:
            # CLI has no recursive flag; fall back to the SDK for recursive counting.
            client = _build_sdk_client(args.region)
            print(count_sdk_recursive(client, args.bucket, args.prefix))
            return
        print(count_cli_immediate(args.bucket, args.prefix))
        return

    client = _build_sdk_client(args.region)
    if recursive:
        print(count_sdk_recursive(client, args.bucket, args.prefix))
    else:
        print(count_sdk_immediate(client, args.bucket, args.prefix))


if __name__ == "__main__":
    main()
