import argparse
import json
import os
import ssl
import sys
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from skill_quality_sdk import QualityError, quality_context  # noqa: E402

# DNS API 版本查询是公开接口（GET /），无需 project_id；
# 先尝试匿名访问，若该区域要求认证则回退到 SDK 认证调用（仍无需 project_id）。
DEFAULT_REGION = "cn-north-4"


def parse_args():
    parser = argparse.ArgumentParser(description="查询 DNS 服务 API 版本列表（公开接口，无需 project_id）")
    parser.add_argument("--region", type=str, default=os.getenv("HW_REGION_NAME", DEFAULT_REGION),
                        help="区域，默认 cn-north-4")
    return parser.parse_args()


def render(items):
    if not items:
        print("没有找到API版本信息")
        return
    header = "id\tstatus"
    output = header + "\n"
    for v in items:
        vid = v.get("id", "") if isinstance(v, dict) else getattr(v, "id", "")
        status = v.get("status", "") if isinstance(v, dict) else getattr(v, "status", "")
        output += f"{vid}\t{status}\n"
    print(output)


def fetch_anonymous(region):
    """匿名访问公开版本端点，返回版本条目列表；失败抛异常"""
    ctx = ssl._create_unverified_context()
    url = f"https://dns.{region}.myhuaweicloud.com/"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    versions = data.get("versions", []) if isinstance(data, dict) else []
    if isinstance(versions, dict):
        return versions.get("values", [])
    return versions


def query_versions(region):
    """查询 API 版本：先匿名访问公开端点，失败时回退到 SDK 认证调用（无需 project_id）"""
    try:
        return fetch_anonymous(region)
    except Exception:
        ak = os.getenv("HW_ACCESS_KEY", "")
        sk = os.getenv("HW_SECRET_KEY", "")
        if not ak or not sk:
            print("DNS API 版本接口在当前区域需要认证，请设置环境变量 HW_ACCESS_KEY 和 HW_SECRET_KEY 后重试（版本查询无需 project_id）")
            raise SystemExit(1)
        from config import build_http_config
        from huaweicloudsdkcore.auth.credentials import BasicCredentials
        from huaweicloudsdkdns.v2 import DnsClient
        from huaweicloudsdkdns.v2.model import ListApiVersionsRequest
        from huaweicloudsdkdns.v2.region.dns_region import DnsRegion

        security_token = os.getenv("HW_SECURITY_TOKEN", "")
        http_config = build_http_config()
        credentials = BasicCredentials(ak, sk) if not security_token \
            else BasicCredentials(ak, sk).with_security_token(security_token)
        client = DnsClient.new_builder() \
            .with_http_config(http_config) \
            .with_credentials(credentials) \
            .with_region(DnsRegion.value_of(region)) \
            .build()
        response = client.list_api_versions(ListApiVersionsRequest())
        values = getattr(response, 'versions', None)
        return getattr(values, 'values', []) if values else []


def main():
    args = parse_args()
    region = args.region
    with quality_context(skill_name="huawei-cloud-network-query", skill_version="1.0.0", trigger_type="agent") as q:
        q.input = {"region": region, "api": "dns.list_api_versions"}
        items = query_versions(region)
        if not items:
            print("没有找到API版本信息")
            q.output = {"version_count": 0}
            return
        render(items)
        q.output = {"version_count": len(items)}


if __name__ == "__main__":
    try:
        main()
    except QualityError as qe:
        sys.stderr.write(str(qe) + "\n")
        sys.exit(1)
    except SystemExit:
        raise
    except Exception as exc:
        sys.stderr.write(f"执行失败: {exc}\n")
        sys.exit(1)
