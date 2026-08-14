#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""List Huawei Cloud SFS (Scalable File Service / SFS Turbo) file system names.

Primary executor : KooCLI `hcloud SFSTurbo ListShares`
Fallback executor: huaweicloudsdksfsturbo Python SDK
                   (SFSTurboClient.list_shares).

Quality reporting : vendored skill_quality_sdk (scripts/skill_quality_sdk.py)
                   — every run reports trace_id / status (success|biz_fail|
                   sys_fail) / error code / cost to the skillsopr operations
                   console. Reporting is non-blocking and fails silently.

Read-only skill: it only lists file systems, never creates, modifies or
deletes them.

Usage:
  python3 list_sfsturbo_shares.py [--region cn-north-4]
                                  [--limit 10] [--offset 0]
                                  [--names-only] [--executor cli|sdk|auto]

Examples:
  python3 list_sfsturbo_shares.py --names-only
  python3 list_sfsturbo_shares.py --limit 20 --offset 0
  python3 list_sfsturbo_shares.py --executor sdk
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

DEFAULT_REGION = "cn-north-4"

CONFIG_GUIDANCE = (
    "请先在您的终端完成以下配置后重试：\n"
    "  1) 安装 KooCLI(hcloud) 并配置 AK/SK：\n"
    "     hcloud configure set --cli-profile=default --cli-mode=AKSK "
    "--cli-access-key=<your-ak> --cli-secret-key=<your-sk>\n"
    "  2) 或在环境变量中设置 AK/SK：HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY\n"
    "     （或 HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK）\n"
    "  AK/SK 可在华为云控制台『我的凭证』页面获取。请勿在对话中粘贴 AK/SK。"
)


def _translate_cli_error(raw):
    """Map common hcloud CLI error patterns to clear Chinese hints."""
    lower = (raw or "").lower()
    if "unrecognized client" in lower or "access denied" in lower or "401" in lower or "403" in lower:
        return (
            "错误：认证失败或无权限（401/403）。请检查 AK/SK 是否正确，以及 IAM 权限是否包含 "
            "sfsturbo:shares:listShares。"
        )
    if "connection" in lower or "timed out" in lower or "timeout" in lower or "network" in lower:
        return "错误：网络连接失败或超时，请检查网络与区域(region)参数。"
    if "not found" in lower or "does not exist" in lower:
        return "错误：未找到指定资源或区域不支持 SFS，请检查参数与区域。"
    return None


def _to_dicts(items):
    """Normalize SDK model objects (ShareInfo) to dicts.

    The SDK list responses return model objects that have no `.get()` method;
    convert every item via `to_dict()` so downstream code can uniformly use
    dict-style access. CLI (JSON) items are already dicts and pass through.
    """
    out = []
    for it in items or []:
        if hasattr(it, "to_dict"):
            out.append(it.to_dict())
        elif isinstance(it, dict):
            out.append(it)
    return out


def _translate_sdk_error(exc):
    """Map common huaweicloudsdksfsturbo exceptions to clear Chinese hints."""
    msg = str(exc)
    lower = msg.lower()
    try:
        code = getattr(exc, "error_code", None) or ""
        lower = (msg + " " + str(code)).lower()
    except Exception:
        pass
    if "not in the following supported regions" in lower or "region" in lower and ("keyerror" in lower or "supported" in lower):
        return (
            "错误：指定的区域(region)无效或不受支持。请使用有效的华为云区域名，例如 "
            "cn-north-4 / cn-east-3 / ap-southeast-1，或通过 --region 参数指定正确的区域。"
        )
    if "unauthorized" in lower or "access denied" in lower or "401" in lower or "403" in lower:
        return (
            "错误：认证失败或无权限（401/403）。请检查 AK/SK 是否正确，以及 IAM 权限是否包含 "
            "sfsturbo:shares:listShares。"
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


def _build_sdk_client(region, project_id=None):
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdksfsturbo.v1 import SFSTurboClient
    from huaweicloudsdksfsturbo.v1.region.sfsturbo_region import SFSTurboRegion

    cred = _get_ak_sk()
    ak = cred[0]
    sk = cred[1]
    if not ak or not sk:
        raise RuntimeError(
            "错误：未找到 AK/SK 凭证（HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY，"
            "或 HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK）。\n" + CONFIG_GUIDANCE
        )
    credentials = BasicCredentials(ak, sk)
    if project_id:
        credentials = credentials.with_project_id(project_id)
    return SFSTurboClient.new_builder().with_credentials(credentials).with_region(SFSTurboRegion.value_of(region)).build()


def _run_cli(args):
    """Run the hcloud CLI command and return parsed JSON."""
    cmd = ["hcloud", "SFSTurbo", "ListShares"]
    cmd.append("--cli-region=%s" % args.region)
    cmd.append("--cli-output=json")
    if args.limit is not None:
        cmd.append("--limit=%d" % args.limit)
    if args.offset is not None:
        cmd.append("--offset=%d" % args.offset)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except FileNotFoundError:
        raise RuntimeError(
            "错误：未找到 hcloud (KooCLI) 命令。请先安装 KooCLI（见 "
            "references/cli-installation-guide.md），或使用 --executor sdk 走 SDK 路径。"
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("错误：执行 hcloud SFSTurbo ListShares 命令超时，请检查网络后重试。")
    if proc.returncode != 0:
        raw = (proc.stderr or proc.stdout or "").strip()
        hint = _translate_cli_error(raw)
        raise RuntimeError(hint if hint else raw)
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError("错误：无法解析 hcloud 输出（%s）：%s" % (e, proc.stdout[:200]))


def list_shares_cli(args):
    d = _run_cli(args)
    return d.get("shares") or []


def list_shares_sdk(client, args):
    from huaweicloudsdksfsturbo.v1.model import ListSharesRequest

    req = ListSharesRequest(
        limit=args.limit,
        offset=args.offset,
    )
    resp = client.list_shares(req)
    return _to_dicts(resp.shares)


def main():
    parser = argparse.ArgumentParser(description="List Huawei Cloud SFS (SFSTurbo) file systems")
    parser.add_argument("--region", default=DEFAULT_REGION, help="SFS region (default: cn-north-4)")
    parser.add_argument(
        "--project-id",
        default=None,
        help="Project ID for the SDK path. Default: region-resolved project. "
        "Note: the hcloud CLI may resolve a different (e.g. default) project than "
        "the SDK region default — pass --project-id to align them.",
    )
    parser.add_argument("--limit", type=int, default=None, help="Max records (default 1000, max 1000)")
    parser.add_argument("--offset", type=int, default=None, help="Record offset (default 0)")
    parser.add_argument("--names-only", action="store_true", help="Print only SFS names (one per line)")
    parser.add_argument(
        "--executor",
        choices=["cli", "sdk", "auto"],
        default="auto",
        help="Execution mode: cli (hcloud), sdk (huaweicloudsdksfsturbo), auto (cli first, sdk fallback)",
    )
    args = parser.parse_args()

    def _list():
        if args.executor in ("cli", "auto"):
            try:
                return list_shares_cli(args)
            except RuntimeError as e:
                if args.executor == "cli" or _translate_cli_error(str(e)):
                    raise
        client = _build_sdk_client(args.region, args.project_id)
        return list_shares_sdk(client, args)

    try:
        with quality_context(
            skill_name="huawei-cloud-sfsturbo-list",
            skill_version="1.0.0",
            trigger_type="agent",
            timeout_threshold_ms=120000,
        ) as q:
            q.input = {
                "region": args.region,
                "project_id": args.project_id,
                "limit": args.limit,
                "offset": args.offset,
                "names_only": args.names_only,
            }
            items = _list()
            names = [it.get("name") for it in items if it.get("name")]
            if args.names_only:
                for n in names:
                    print(n)
            else:
                for it in items:
                    print(json.dumps(
                        {"name": it.get("name"), "id": it.get("id"),
                         "status": it.get("status"), "size": it.get("size"),
                         "share_proto": it.get("share_proto"), "region": it.get("region")},
                        ensure_ascii=False,
                    ))
            q.output = {"count": len(items)}
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
