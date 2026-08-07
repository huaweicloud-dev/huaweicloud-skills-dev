#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""List Huawei Cloud OBS buckets and folder names inside a bucket.

Primary executor : KooCLI obsutil-backed `hcloud OBS ls [obs://bucket[/prefix]]`
                   — parses the "Folder list:" section of obsutil output.
Fallback executor: huaweicloudsdkobs Python SDK
                   (ObsClient.list_buckets / list_objects with delimiter=/;
                   a folder = an object key ending in '/').

Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py)
                   — every run reports trace_id / status (success|biz_fail|
                   sys_fail) / error code / cost to the skillsopr operations
                   console. Reporting is non-blocking and fails silently.

Read-only skill: it only lists buckets and folder names, never creates,
modifies or deletes buckets, folders or objects.

Usage:
  python3 list_obs_folders.py [--region cn-north-4]
                              [--bucket <bucket>] [--prefix <prefix>]
                              [--folders-only] [--buckets-only]
                              [--executor cli|sdk|auto]

Examples:
  python3 list_obs_folders.py --buckets-only
  python3 list_obs_folders.py --bucket my-bucket --folders-only
  python3 list_obs_folders.py --bucket my-bucket --prefix photos --folders-only
  python3 list_obs_folders.py --bucket my-bucket --executor sdk
"""

import argparse
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

DEFAULT_REGION = "cn-north-4"

CONFIG_GUIDANCE = (
    "请先在您的终端完成以下配置后重试：\n"
    "  1) 安装 KooCLI(hcloud) 并配置 obsutil 凭证：\n"
    "     hcloud OBS config -i=<YourAK> -k=<YourSK> -e=obs.<Region>.myhuaweicloud.com\n"
    "     示例(cn-north-4)：hcloud OBS config -i=<YourAK> -k=<YourSK> -e=obs.cn-north-4.myhuaweicloud.com\n"
    "  2) 或在环境变量中设置 AK/SK：HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY\n"
    "     （或 HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK）\n"
    "  AK/SK 可在华为云控制台『我的凭证』页面获取。请勿在对话中粘贴 AK/SK。"
)


def _translate_cli_error(raw):
    """Map common obsutil CLI error patterns to clear Chinese hints."""
    lower = (raw or "").lower()
    if "nosuchbucket" in lower or "bucket does not exist" in lower:
        return (
            "错误：指定的 OBS 桶不存在，或当前 AK/SK 无权访问该桶（NoSuchBucket）。\n"
            "请检查桶名是否正确，以及 IAM 权限是否包含 obs:bucket:ListBucket / obs:object:List。"
        )
    if "invalidaccesskeyid" in lower:
        return (
            "错误：AK/SK 无效或已过期（InvalidAccessKeyId）。\n"
            "请检查 obsutil 配置中的 AK/SK 是否正确：hcloud OBS config -i=<YourAK> -k=<YourSK> -e=obs.<Region>.myhuaweicloud.com"
        )
    if "signaturedoesnotmatch" in lower or "signature" in lower:
        return "错误：请求签名校验失败，请核对 AK/SK 与端点配置是否正确。"
    if "accessdenied" in lower or "forbidden" in lower or "403" in lower:
        return (
            "错误：访问被拒绝（AccessDenied）。当前 AK/SK 无权限读取该桶，\n"
            "请检查 IAM 策略是否包含 obs:bucket:ListBucket / obs:object:List。"
        )
    if "please set ak, sk and endpoint" in lower or "configure the ak, sk and endpoint" in lower or "configuration file" in lower:
        return "错误：未配置 obsutil 凭证（AK/SK/endpoint）。\n" + CONFIG_GUIDANCE
    return None


def _translate_sdk_error(exc):
    """Map common huaweicloudsdkobs exceptions to clear Chinese hints."""
    msg = str(exc)
    lower = msg.lower()
    try:
        code = getattr(exc, "error_code", None) or ""
        lower = (msg + " " + str(code)).lower()
    except Exception:
        pass
    if "nosuchbucket" in lower or "bucket does not exist" in lower:
        return (
            "错误：指定的 OBS 桶不存在，或当前 AK/SK 无权访问该桶（NoSuchBucket）。\n"
            "请检查桶名是否正确，以及 IAM 权限是否包含 obs:bucket:ListBucket / obs:object:List。"
        )
    if "invalidaccesskeyid" in lower:
        return (
            "错误：AK/SK 无效或已过期（InvalidAccessKeyId）。\n"
            "请检查环境变量中的 AK/SK 是否正确（HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY）。"
        )
    if "signaturedoesnotmatch" in lower:
        return "错误：请求签名校验失败，请核对 AK/SK 与区域(region)参数是否正确。"
    if "accessdenied" in lower or "forbidden" in lower or "403" in lower:
        return (
            "错误：访问被拒绝（AccessDenied）。当前 AK/SK 无权限读取该桶，\n"
            "请检查 IAM 策略是否包含 obs:bucket:ListBucket / obs:object:List。"
        )
    if "connection" in lower or "timed out" in lower or "timeout" in lower:
        return "错误：网络连接失败或超时，请检查网络与区域(region)参数。"
    return None


def _get_ak_sk():
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
            "错误：未找到 AK/SK 凭证（HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY，"
            "或 HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK）。\n" + CONFIG_GUIDANCE
        )
    credentials = ObsCredentials(ak, sk)
    return ObsClient.new_builder().with_credentials(credentials).with_region(ObsRegion.value_of(region)).build()


def _parse_bucket_names(text):
    """Parse bucket names ('obs://<name>') from `hcloud OBS ls` output."""
    names = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("obs://"):
            names.append(line[len("obs://"):].split()[0])
    return names


def _parse_folder_names(text):
    """Parse folder names from the 'Folder list:' section of obsutil output."""
    folders = []
    in_folder_list = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("Folder list:"):
            in_folder_list = True
            continue
        if stripped.startswith("Object list:"):
            in_folder_list = False
            continue
        if in_folder_list and stripped.startswith("obs://"):
            folders.append(stripped)
    return folders


def list_buckets_cli():
    """List bucket names via `hcloud OBS ls`."""
    try:
        proc = subprocess.run(
            ["hcloud", "OBS", "ls"],
            capture_output=True,
            text=True,
            timeout=120,
        )
    except FileNotFoundError:
        raise RuntimeError(
            "错误：未找到 hcloud (KooCLI) 命令。请先安装 KooCLI（见 "
            "references/cli-installation-guide.md），或使用 --executor sdk 走 SDK 路径。"
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("错误：执行 hcloud OBS ls 超时，请检查网络后重试。")
    if proc.returncode != 0:
        raw = (proc.stderr or proc.stdout or "").strip()
        hint = _translate_cli_error(raw)
        raise RuntimeError(hint if hint else raw)
    names = _parse_bucket_names(proc.stdout)
    if not names:
        raise RuntimeError("Could not parse any bucket name from hcloud OBS ls output")
    return names


def list_folders_cli(bucket, prefix):
    """List folder names under bucket[/prefix] via `hcloud OBS ls <url> -d`.

    The `-d` flag makes obsutil list the objects and sub-folders *inside* the
    given folder (without it, obsutil only echoes the folder that matches the
    prefix itself). obsutil also echoes the queried prefix in the folder list,
    so the queried folder itself is filtered out of the result.
    """
    url = "obs://%s" % bucket
    if prefix:
        url += "/" + prefix.strip("/")
    try:
        proc = subprocess.run(
            ["hcloud", "OBS", "ls", url, "-d"],
            capture_output=True,
            text=True,
            timeout=180,
        )
    except FileNotFoundError:
        raise RuntimeError(
            "错误：未找到 hcloud (KooCLI) 命令。请先安装 KooCLI（见 "
            "references/cli-installation-guide.md），或使用 --executor sdk 走 SDK 路径。"
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("错误：执行 hcloud OBS ls 超时，请检查网络后重试。")
    if proc.returncode != 0:
        raw = (proc.stderr or proc.stdout or "").strip()
        hint = _translate_cli_error(raw)
        raise RuntimeError(hint if hint else raw)
    folders = _parse_folder_names(proc.stdout)
    # Exclude the queried folder itself (obsutil echoes it in the folder list).
    query_folder = url.rstrip("/") + "/"
    return [f for f in folders if f != query_folder]


def list_buckets_sdk(client):
    """List bucket names via SDK ObsClient.list_buckets.

    The SDK response model is `ListBucketsResponse.buckets` of type `Buckets`
    (a wrapper object). `to_dict()` therefore yields
    `{"buckets": {"bucket": [{...}]}}` — NOT a bare list. Both shapes are
    handled defensively (empty responses may serialize `buckets` as `[]`).
    """
    from huaweicloudsdkobs.v1.model import ListBucketsRequest

    d = client.list_buckets(ListBucketsRequest()).to_dict()
    buckets = d.get("buckets") or []
    if isinstance(buckets, dict):
        buckets = buckets.get("bucket") or []
    return [b.get("name") for b in buckets if isinstance(b, dict) and b.get("name")]


def list_folders_sdk(client, bucket, prefix):
    """List folder names via SDK paginated ListObjects with delimiter='/'.

    A folder is an object key ending with '/'. With delimiter='/', the
    response returns CommonPrefixes for the folders and Contents for the
    objects. The prefix MUST keep its trailing slash (e.g. ``photos/``):
    without it, CommonPrefixes returns the prefix itself instead of the
    sub-folders below it. The queried prefix itself is excluded from the
    result.
    """
    from huaweicloudsdkobs.v1.model import ListObjectsRequest

    folders = []
    marker = None
    sdk_prefix = (prefix.rstrip("/") + "/") if prefix else None
    while True:
        req = ListObjectsRequest(
            bucket_name=bucket,
            prefix=sdk_prefix,
            delimiter="/",
            max_keys=1000,
            marker=marker,
        )
        d = client.list_objects(req).to_dict()
        for cp in d.get("common_prefixes") or []:
            p = cp.get("prefix")
            if p and p != sdk_prefix and p not in folders:
                folders.append(p)
        for c in d.get("contents") or []:
            key = c.get("key", "")
            if key.endswith("/") and key != sdk_prefix and key not in folders:
                folders.append(key)
        marker = d.get("next_marker")
        if not d.get("is_truncated") or not marker:
            break
    return folders


def main():
    parser = argparse.ArgumentParser(description="List Huawei Cloud OBS buckets and folder names")
    parser.add_argument("--region", default=DEFAULT_REGION, help="OBS region (default: cn-north-4)")
    parser.add_argument("--bucket", default=None, help="OBS bucket name; list folders in it")
    parser.add_argument("--prefix", default=None, help="List sub-folders under this prefix (folder)")
    parser.add_argument("--folders-only", action="store_true", help="Print only folder names (one per line)")
    parser.add_argument("--buckets-only", action="store_true", help="Print only bucket names (one per line)")
    parser.add_argument(
        "--executor",
        choices=["cli", "sdk", "auto"],
        default="auto",
        help="Execution mode: cli (hcloud OBS ls), sdk (huaweicloudsdkobs), auto (cli first, sdk fallback)",
    )
    args = parser.parse_args()

    prefix = args.prefix.strip("/") if args.prefix else None

    if args.bucket is None:
        # Bucket list mode
        def _buckets():
            if args.executor in ("cli", "auto"):
                try:
                    return list_buckets_cli()
                except RuntimeError as e:
                    if args.executor == "cli" or _translate_cli_error(str(e)):
                        raise
            client = _build_sdk_client(args.region)
            return list_buckets_sdk(client)

        try:
            with quality_context(
                skill_name="huawei-cloud-obs-list-folders",
                skill_version="1.0.0",
                trigger_type="agent",
                timeout_threshold_ms=120000,
            ) as q:
                q.input = {"region": args.region, "buckets_only": args.buckets_only}
                names = _buckets()
                for n in names:
                    print(n if args.buckets_only else "obs://" + n)
                q.output = {"bucket_count": len(names)}
            return
        except QualityError as qe:
            sys.stderr.write(str(qe) + "\n")
            sys.exit(1)
        except Exception as exc:
            hint = _translate_sdk_error(exc)
            if hint:
                sys.stderr.write(hint + "\n")
            else:
                sys.stderr.write("错误：执行失败（%s: %s），请检查凭证、网络与参数后重试。\n" % (type(exc).__name__, exc))
            sys.exit(1)
    else:
        # Folder list mode
        def _folders():
            if args.executor in ("cli", "auto"):
                try:
                    return list_folders_cli(args.bucket, prefix)
                except RuntimeError as e:
                    if args.executor == "cli" or _translate_cli_error(str(e)):
                        raise
            client = _build_sdk_client(args.region)
            return list_folders_sdk(client, args.bucket, prefix)

        try:
            with quality_context(
                skill_name="huawei-cloud-obs-list-folders",
                skill_version="1.0.0",
                trigger_type="agent",
                timeout_threshold_ms=120000,
            ) as q:
                q.input = {
                    "region": args.region,
                    "bucket": args.bucket,
                    "prefix": prefix,
                    "folders_only": args.folders_only,
                }
                folders = _folders()
                for f in folders:
                    print(f)
                q.output = {"folder_count": len(folders)}
            return
        except QualityError as qe:
            sys.stderr.write(str(qe) + "\n")
            sys.exit(1)
        except Exception as exc:
            hint = _translate_sdk_error(exc)
            if hint:
                sys.stderr.write(hint + "\n")
            else:
                sys.stderr.write("错误：执行失败（%s: %s），请检查凭证、网络与参数后重试。\n" % (type(exc).__name__, exc))
            sys.exit(1)


if __name__ == "__main__":
    main()
