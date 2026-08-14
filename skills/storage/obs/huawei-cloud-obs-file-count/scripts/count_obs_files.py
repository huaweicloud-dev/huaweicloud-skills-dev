#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Count the number of files (objects) in a Huawei Cloud OBS bucket.

Prints ONLY the count (a single integer) — nothing else.

Primary executor : KooCLI obsutil-backed `hcloud OBS ls <cloud_url> -limit=0`
                   (obsutil reports "File number: N" for the listing; -limit=0
                   disables the default 1000-object page cap so the count is
                   not truncated).
Fallback executor: huaweicloudsdkobs Python SDK
                   (paginated ListObjects; a file = an object whose key does
                   NOT end with '/', i.e. zero-byte folder markers are
                   excluded).

Usage:
  python3 count_obs_files.py --bucket <bucket> [--prefix <prefix>]
      [--region <region>] [--executor cli|sdk|auto]

Examples:
  python3 count_obs_files.py --bucket my-bucket
  python3 count_obs_files.py --bucket my-bucket --prefix photos
  python3 count_obs_files.py --bucket my-bucket --prefix photos/ --executor sdk
"""

import argparse
import os
import re
import subprocess
import sys


CONFIG_GUIDANCE = (
    "请先在您的终端完成以下配置后重试：\n"
    "  1) 安装 KooCLI(hcloud) 并配置 obsutil 凭证：\n"
    "     hcloud obs config -i=<YourAK> -k=<YourSK> -e=obs.<Region>.myhuaweicloud.com\n"
    "     示例(cn-north-4)：hcloud obs config -i=<YourAK> -k=<YourSK> -e=obs.cn-north-4.myhuaweicloud.com\n"
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
            "请检查 obsutil 配置中的 AK/SK 是否正确：hcloud obs config -i=<YourAK> -k=<YourSK> -e=obs.<Region>.myhuaweicloud.com"
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


def _parse_file_number(text):
    """Parse 'File number: N' from an `hcloud OBS ls` output."""
    m = re.search(r"File number:\s*(\d+)", text)
    return int(m.group(1)) if m else None


def count_cli(bucket, prefix):
    """Count files via `hcloud OBS ls <url> -limit=0` and parse 'File number'."""
    url = "obs://%s" % bucket
    if prefix:
        url += "/" + prefix.strip("/")
    url += "/"
    try:
        # -limit=0 disables obsutil's default 1000-object page cap so the file
        # count is not truncated for buckets with more than 1000 objects.
        proc = subprocess.run(
            ["hcloud", "OBS", "ls", url, "-limit=0"],
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
    n = _parse_file_number(proc.stdout)
    if n is None:
        raise RuntimeError("Could not parse 'File number' from hcloud output")
    return n


def count_sdk(client, bucket, prefix):
    """Count files via paginated SDK ListObjects.

    A file is an object whose key does NOT end with '/'. Zero-byte
    folder-marker keys (e.g. "photos/") are directory markers, not files.
    """
    from huaweicloudsdkobs.v1.model import ListObjectsRequest

    count = 0
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
            if not c.get("key", "").endswith("/"):
                count += 1
        marker = d.get("next_marker")
        if not d.get("is_truncated") or not marker:
            break
    return count


def main():
    parser = argparse.ArgumentParser(description="Count files in a Huawei Cloud OBS bucket")
    parser.add_argument("--bucket", required=True, help="OBS bucket name")
    parser.add_argument("--prefix", default=None, help="Count files under this prefix (folder)")
    parser.add_argument("--region", default="cn-north-4", help="OBS region (default: cn-north-4)")
    parser.add_argument(
        "--executor",
        choices=["cli", "sdk", "auto"],
        default="auto",
        help="Execution mode: cli (hcloud OBS ls), sdk (huaweicloudsdkobs), auto (cli first, sdk fallback)",
    )
    args = parser.parse_args()

    prefix = args.prefix.strip("/") if args.prefix else None

    if args.executor in ("cli", "auto"):
        try:
            print(count_cli(args.bucket, prefix))
            return
        except RuntimeError as e:
            if args.executor == "cli":
                sys.stderr.write(str(e) + "\n")
                sys.exit(1)
            if _translate_cli_error(str(e)):
                # A definitive service error (NoSuchBucket / AccessDenied /
                # InvalidAccessKeyId / missing obsutil credentials): the CLI
                # already gave the user a clear, actionable answer. Re-raising
                # avoids an ugly raw SDK traceback on the fallback path.
                sys.stderr.write(str(e) + "\n")
                sys.exit(1)
            # auto: fall through to SDK for infra errors (hcloud missing, timeout)

    try:
        client = _build_sdk_client(args.region)
        print(count_sdk(client, args.bucket, prefix))
    except Exception as exc:
        hint = _translate_sdk_error(exc)
        if hint:
            sys.stderr.write(hint + "\n")
        else:
            sys.stderr.write(str(exc) + "\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
