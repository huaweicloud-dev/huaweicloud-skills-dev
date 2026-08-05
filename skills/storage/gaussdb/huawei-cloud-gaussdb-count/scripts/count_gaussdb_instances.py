#!/usr/bin/env python3
# count_gaussdb_instances.py — Count Huawei Cloud GaussDB instances via SDK.
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


def _fail(msg):
    print("ERROR: {}".format(msg), file=sys.stderr)
    sys.exit(1)


def count_opengauss(credentials, region, limit):
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
        region_obj = GaussDBforopenGaussRegion.value_of(region)
    except (KeyError, ValueError):
        _fail("invalid region '{}': region not found. Use a valid region such as cn-north-4.".format(region))
    try:
        client = GaussDBforopenGaussClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(region_obj) \
            .build()
        response = client.list_instances(ListInstancesRequest(limit=limit))
    except ClientRequestException as e:
        _fail("GaussDB for openGauss query failed (error_code={}): {}. Check the AK/SK credentials, region, and IAM permissions (gaussdb read-only).".format(e.error_code, e.error_msg))
    except SdkException as e:
        _fail("GaussDB for openGauss query failed: {}. Check the AK/SK credentials and network connectivity.".format(e))
    return response.total_count or 0


def count_mysql(credentials, region, limit):
    try:
        from huaweicloudsdkgaussdb.v3.region.gaussdb_region import GaussDBRegion
        from huaweicloudsdkgaussdb.v3 import GaussDBClient, ListGaussMySqlInstancesRequest
    except ImportError:
        _fail("huaweicloudsdkgaussdb not installed; run: pip install huaweicloudsdkgaussdb")
    from huaweicloudsdkcore.exceptions.exceptions import ClientRequestException, SdkException
    try:
        region_obj = GaussDBRegion.value_of(region)
    except (KeyError, ValueError):
        _fail("invalid region '{}': region not found. Use a valid region such as cn-north-4.".format(region))
    try:
        client = GaussDBClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(region_obj) \
            .build()
        response = client.list_gauss_my_sql_instances(ListGaussMySqlInstancesRequest(limit=limit))
    except ClientRequestException as e:
        _fail("GaussDB (MySQL) query failed (error_code={}): {}. Check the AK/SK credentials, region, and IAM permissions (gaussdb read-only).".format(e.error_code, e.error_msg))
    except SdkException as e:
        _fail("GaussDB (MySQL) query failed: {}. Check the AK/SK credentials and network connectivity.".format(e))
    return response.total_count or 0


def main():
    parser = argparse.ArgumentParser(description="Count GaussDB instances (SDK fallback)")
    parser.add_argument("--region", default="cn-north-4", help="Huawei Cloud region")
    parser.add_argument("--limit", type=int, default=100, help="Max records per page (1-100)")
    args = parser.parse_args()

    credentials = get_credentials()
    opengauss = count_opengauss(credentials, args.region, args.limit)
    mysql = count_mysql(credentials, args.region, args.limit)
    total = opengauss + mysql
    print("GaussDB for openGauss count: {}".format(opengauss))
    print("GaussDB (MySQL) count: {}".format(mysql))
    print("Total GaussDB instances: {}".format(total))


if __name__ == "__main__":
    main()
