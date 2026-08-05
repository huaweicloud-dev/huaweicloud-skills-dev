#!/usr/bin/env python3
# count_gaussdb_instances.py — Count Huawei Cloud GaussDB instances and report
# their total storage size via the SDK.
#
# Usage:
#   python3 count_gaussdb_instances.py [--region cn-north-4] [--limit 100]
#
# Requires HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY (or HUAWEICLOUD_SDK_AK/SK)
# environment variables. Read-only — never creates, modifies or deletes resources.
import argparse
import os
import sys


def get_credentials():
    ak = os.getenv("HUAWEI_ACCESS_KEY") or os.getenv("HUAWEICLOUD_SDK_AK")
    sk = os.getenv("HUAWEI_SECRET_KEY") or os.getenv("HUAWEICLOUD_SDK_SK")
    if not ak or not sk:
        print("ERROR: HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY not set", file=sys.stderr)
        sys.exit(2)
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    return BasicCredentials(ak, sk)


def _to_gb(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _volume_size_gb(instance):
    volume = getattr(instance, "volume", None)
    return _to_gb(getattr(volume, "size", None)) if volume else 0.0


def _fail(msg):
    print("ERROR: {}".format(msg), file=sys.stderr)
    sys.exit(1)


def opengauss_stats(credentials, region, limit):
    try:
        from huaweicloudsdkgaussdbforopengauss.v3.region.gaussdbforopengauss_region import (
            GaussDBforopenGaussRegion,
        )
        from huaweicloudsdkgaussdbforopengauss.v3 import (
            GaussDBforopenGaussClient,
            ListInstancesRequest,
        )
    except ImportError:
        _fail("huaweicloudsdkgaussdbforopengauss not installed; run: pip install huaweicloudsdkgaussdbforopengauss")
    from huaweicloudsdkcore.exceptions.exceptions import ClientRequestException, SdkException
    try:
        client = GaussDBforopenGaussClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(GaussDBforopenGaussRegion.value_of(region)) \
            .build()
        response = client.list_instances(ListInstancesRequest(limit=limit))
    except ClientRequestException as e:
        _fail("GaussDB for openGauss query failed (error_code={}): {}. Check the AK/SK credentials, region, and IAM permissions (gaussdb read-only).".format(e.error_code, e.error_msg))
    except SdkException as e:
        _fail("GaussDB for openGauss query failed: {}. Check the AK/SK credentials and network connectivity.".format(e))
    instances = response.instances or []
    total_size = sum(_volume_size_gb(i) for i in instances)
    return response.total_count or 0, total_size


def mysql_stats(credentials, region, limit):
    try:
        from huaweicloudsdkgaussdb.v3.region.gaussdb_region import GaussDBRegion
        from huaweicloudsdkgaussdb.v3 import GaussDBClient, ListGaussMySqlInstancesRequest
    except ImportError:
        _fail("huaweicloudsdkgaussdb not installed; run: pip install huaweicloudsdkgaussdb")
    from huaweicloudsdkcore.exceptions.exceptions import ClientRequestException, SdkException
    try:
        client = GaussDBClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(GaussDBRegion.value_of(region)) \
            .build()
        response = client.list_gauss_my_sql_instances(ListGaussMySqlInstancesRequest(limit=limit))
    except ClientRequestException as e:
        _fail("GaussDB (MySQL) query failed (error_code={}): {}. Check the AK/SK credentials, region, and IAM permissions (gaussdb read-only).".format(e.error_code, e.error_msg))
    except SdkException as e:
        _fail("GaussDB (MySQL) query failed: {}. Check the AK/SK credentials and network connectivity.".format(e))
    instances = response.instances or []
    total_size = sum(_volume_size_gb(i) for i in instances)
    return response.total_count or 0, total_size


def main():
    parser = argparse.ArgumentParser(
        description="Count GaussDB instances and report total storage size (SDK fallback)")
    parser.add_argument("--region", default="cn-north-4", help="Huawei Cloud region")
    parser.add_argument("--limit", type=int, default=100, help="Max records per page (1-100)")
    args = parser.parse_args()

    credentials = get_credentials()
    opengauss_count, opengauss_size = opengauss_stats(credentials, args.region, args.limit)
    mysql_count, mysql_size = mysql_stats(credentials, args.region, args.limit)
    total_count = opengauss_count + mysql_count
    total_size = opengauss_size + mysql_size
    print("GaussDB for openGauss count: {}".format(opengauss_count))
    print("GaussDB for openGauss total size: {:.1f} GB".format(opengauss_size))
    print("GaussDB (MySQL) count: {}".format(mysql_count))
    print("GaussDB (MySQL) total size: {:.1f} GB".format(mysql_size))
    print("Total GaussDB instances: {}".format(total_count))
    print("Total GaussDB storage size: {:.1f} GB".format(total_size))


if __name__ == "__main__":
    main()
