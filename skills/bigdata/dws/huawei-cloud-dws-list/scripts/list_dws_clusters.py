#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
list_dws_clusters.py — 查询华为云租户下 DWS 集群列表，只返回集群名称

通过 hcloud CLI (KooCLI) 调用 DWS ListClusters 接口，用 jq 提取集群名称列表。
集成 skill_quality_sdk 自动上报执行质量（success/biz_fail/sys_fail + 错误码）。

用法:
  python3 list_dws_clusters.py --region cn-north-4 [--enterprise_project_id all_granted_eps]

环境变量:
  HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY  (或 HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK)
  SKILL_QUALITY_DISABLE=1 可禁用质量上报（本地调试）
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skill_quality_sdk import QualityError, quality_context  # noqa: E402

DEFAULT_REGION = "cn-north-4"


HCLOUD_ERROR_MARKERS = (
    "Failed to obtain project ID",
    "Unauthorized",
    "error_code",
    "[USE_ERROR]",
    "[OPENAPI_ERROR]",
)


def _run_hcloud(region, enterprise_project_id=None):
    """执行 hcloud DWS ListClusters，返回原始 JSON 字符串。

    hcloud 对参数/认证类错误（无效 region、凭证失败等）会输出非 JSON 错误文本
    到 stdout 且退出码为 0，因此不能只依赖 returncode：必须同时检测输出中的
    错误标记，否则真实原因会被 JSON 解析兜底掩蔽。
    """
    cmd = ["hcloud", "DWS", "ListClusters", f"--cli-region={region}"]
    if enterprise_project_id:
        cmd.append(f"--enterprise_project_id={enterprise_project_id}")
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    output = proc.stdout or ""
    err_text = proc.stderr or ""
    # 1) 错误标记检测（无论退出码）：hcloud 参数/认证错误走 stdout 且 exit 0
    for marker in HCLOUD_ERROR_MARKERS:
        if marker in output or marker in err_text:
            hint = _translate_hcloud_error(output + err_text)
            raise RuntimeError(
                f"hcloud DWS ListClusters 调用失败（{marker}）: "
                f"{hint}\n原始输出: {(output + err_text).strip()[:500]}"
            )
    # 2) 非零退出码兜底
    if proc.returncode != 0:
        raise RuntimeError(
            f"hcloud DWS ListClusters 执行失败 (exit {proc.returncode}): "
            f"{(err_text or output).strip()[:500]}"
        )
    return output


def _translate_hcloud_error(raw):
    """把 hcloud 常见错误文本翻译为带修复指引的中文提示（按特异性优先匹配）。"""
    lower = raw.lower()
    if "failed to obtain project id" in lower:
        return (
            "获取 project_id 失败：通常是凭证无效或 region 与账号开通区域不一致。"
            "请检查 AK/SK 是否正确有效（通过 hcloud configure list 查看），"
            "或显式配置 cli-project-id。"
        )
    if "unauthorized" in lower or "incorrect iam" in lower or "authentication" in lower:
        return (
            "凭证认证失败：请检查 AK/SK 是否正确有效（hcloud configure list 查看），"
            "或 IAM 权限是否包含 dws:cluster:list。"
        )
    if "cli-region is not supported" in lower:
        return (
            "region 无效：请使用 hcloud 支持的区域（如 cn-north-4），"
            "完整支持区域列表见原始输出；可用 `hcloud DWS ListClusters --help` 确认。"
        )
    if "use_error" in lower or "openapi_error" in lower:
        return "hcloud 调用错误，详见原始输出；请核对 region / enterprise_project_id 参数。"
    return "hcloud 返回错误，详见原始输出。"


def list_clusters(region, enterprise_project_id=None):
    """查询 DWS 集群列表，返回 [{"name": ...}, ...] 与 count。"""
    raw = _run_hcloud(region, enterprise_project_id)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise RuntimeError(
            f"hcloud 返回非 JSON 输出: {e}；"
            f"原始输出: {raw.strip()[:300]}"
        ) from e
    clusters = data.get("clusters") or []
    return clusters, data.get("count", len(clusters))


def main():
    ap = argparse.ArgumentParser(description="查询华为云租户下 DWS 集群列表（只返回名称）")
    ap.add_argument("--region", default=os.environ.get("HUAWEICLOUD_SDK_REGION", DEFAULT_REGION),
                    help="华为云区域，默认 cn-north-4")
    ap.add_argument("--enterprise_project_id", default=None,
                    help="企业项目ID；传 all_granted_eps 查询所有授权企业项目下的集群")
    args = ap.parse_args()

    with quality_context("huawei-cloud-dws-list", skill_version="1.0.0",
                         trigger_type="agent", timeout_threshold_ms=60000) as q:
        q.input = {"region": args.region,
                   "enterprise_project_id": args.enterprise_project_id}
        try:
            clusters, count = list_clusters(args.region, args.enterprise_project_id)
        except Exception as e:
            msg = str(e)
            code = "B01"
            if "region 无效" in msg or "cli-region is not supported" in msg:
                code = "U02"
            elif "凭证认证失败" in msg or "Unauthorized" in msg or "认证" in msg:
                code = "U04"
            elif "timeout" in msg.lower() or "网络" in msg or "Connection" in msg:
                code = "N01"
            q.fail(code, f"查询 DWS 集群列表失败: {msg}")
            print(f"错误：查询 DWS 集群列表失败：{msg}", file=sys.stderr)
            return 1
        names = [c.get("name") for c in clusters if c.get("name")]
        q.output = {"count": count, "names": names}
        if not names:
            print(f"No DWS clusters found in region {args.region}")
        else:
            print("\n".join(names))
        return 0


if __name__ == "__main__":
    sys.exit(main())
