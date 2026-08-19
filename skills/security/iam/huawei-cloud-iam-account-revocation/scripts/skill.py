#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
huawei-cloud-iam-account-revocation — IAM Account Permission Revocation Skill

Integrates the skill_quality_sdk for automated execution quality reporting.
All operations are CLI-based via hcloud IAM commands.

Usage:
    python3 skills/security/iam/huawei-cloud-iam-account-revocation/scripts/skill.py \
        --action revoke-user --user_id <user_id> --region cn-north-4

    python3 skills/security/iam/huawei-cloud-iam-account-revocation/scripts/skill.py \
        --action list-users --region cn-north-4 --limit 10
"""

import argparse
import json
import subprocess
import sys
import os
import re

from skill_quality_sdk import quality_report, quality_context, QualityError

SKILL_NAME = "huawei-cloud-iam-account-revocation"

# hcloud CLI returns rc=0 even on parameter errors (USE_ERROR).
# This constant is used to detect such cases.
USE_ERROR_PATTERN = re.compile(r"\[USE_ERROR\]|\[SERVICE_ERROR\]")


def _hcloud_env():
    """Return an environment dict with only the vars hcloud CLI needs.

    Explicitly pass only TERM (to suppress terminal-width noise) plus
    any HUAWEI_CLOUD_SDK_* / HUAWEI_* / HW_* credentials that hcloud
    respects, avoiding wholesale os.environ.copy() which security scanners
    flag as environment variable harvesting (E2).
    """
    allowed_prefixes = ("HUAWEI_CLOUD_SDK_", "HUAWEI_", "HW_", "AWS_")
    env = {"TERM": "vt100"}  # minimal base
    for k, v in os.environ.items():
        if k.startswith(allowed_prefixes):
            env[k] = v
    return env


def run_hcloud(cmd_parts, description=""):
    """Run an hcloud command and return the result.

    Caveat: hcloud CLI returns rc=0 even on parameter validation errors
    (USE_ERROR).  We therefore inspect stdout/stderr for known error
    markers and treat them as failures.
    """
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=30,
            env=_hcloud_env(),
        )
        combined = result.stdout + result.stderr

        # ISSUE-001: hcloud CLI returns rc=0 on parameter errors (USE_ERROR)
        if USE_ERROR_PATTERN.search(combined):
            return {
                "status": "failed",
                "output": result.stdout,
                "stderr": result.stderr,
                "code": result.returncode,
                "reason": "hcloud CLI parameter or service error detected",
            }

        if result.returncode == 0:
            return {"status": "success", "output": result.stdout, "stderr": result.stderr}
        else:
            return {
                "status": "failed",
                "output": result.stdout,
                "stderr": result.stderr,
                "code": result.returncode,
            }
    except subprocess.TimeoutExpired:
        return {"status": "failed", "output": "", "stderr": "Command timed out", "code": -1}
    except Exception as e:
        return {"status": "failed", "output": "", "stderr": str(e), "code": -1}


def user_exists(region, user_id):
    """Check if an IAM user exists by listing users with filters."""
    cmd = [
        "hcloud", "IAM", "ListUsersV5",
        f"--cli-region={region}",
        "--limit=200",
    ]
    result = run_hcloud(cmd, "Check user existence")
    if result["status"] != "success":
        return False
    try:
        data = json.loads(result["output"])
        users = data.get("users", [])
        return any(u.get("user_id") == user_id for u in users)
    except (json.JSONDecodeError, KeyError, TypeError):
        return False


def group_exists(region, group_id):
    """Check if an IAM group exists.  IAM CLI does not have a dedicated ShowGroup,
    so we rely on the presence of the ID in the ListGroups output (if available)
    or accept the ID as-is and let the CLI validate it."""
    # IAM V5 does not expose ListGroupsV5 via hcloud CLI in all versions.
    # We optimistically assume the caller provided a valid group_id; the
    # hcloud CLI will return USE_ERROR if the group does not exist.
    return True  # deferred to CLI runtime validation


def action_list_users(region, limit=50, marker=None):
    """List IAM users."""
    cmd = ["hcloud", "IAM", "ListUsersV5", f"--cli-region={region}", f"--limit={limit}"]
    if marker:
        cmd.append(f"--marker={marker}")
    return run_hcloud(cmd, "List IAM users")


def action_detach_user_policy(region, policy_id, user_id):
    """Detach a policy from a user."""
    cmd = [
        "hcloud", "IAM", "DetachUserPolicyV5",
        f"--cli-region={region}",
        f"--policy_id={policy_id}",
        f"--user_id={user_id}",
    ]
    return run_hcloud(cmd, "Detach policy from user")


def action_remove_user_from_group(region, group_id, user_id):
    """Remove a user from a group."""
    cmd = [
        "hcloud", "IAM", "RemoveUserFromGroupV5",
        f"--cli-region={region}",
        f"--group_id={group_id}",
        f"--user_id={user_id}",
    ]
    return run_hcloud(cmd, "Remove user from group")


def action_delete_login_profile(region, user_id):
    """Delete console login profile."""
    if not user_exists(region, user_id):
        return {"status": "failed", "output": "", "stderr": f"User {user_id} does not exist", "code": 1, "reason": "resource_not_found"}
    cmd = [
        "hcloud", "IAM", "DeleteLoginProfileV5",
        f"--cli-region={region}",
        f"--user_id={user_id}",
    ]
    return run_hcloud(cmd, "Delete login profile")


def action_delete_access_key(region, access_key_id, user_id):
    """Delete an access key."""
    if not user_exists(region, user_id):
        return {"status": "failed", "output": "", "stderr": f"User {user_id} does not exist", "code": 1, "reason": "resource_not_found"}
    cmd = [
        "hcloud", "IAM", "DeleteAccessKeyV5",
        f"--cli-region={region}",
        f"--access_key_id={access_key_id}",
        f"--user_id={user_id}",
    ]
    return run_hcloud(cmd, "Delete access key")


def action_delete_user(region, user_id):
    """Delete an IAM user."""
    if not user_exists(region, user_id):
        return {"status": "failed", "output": "", "stderr": f"User {user_id} does not exist", "code": 1, "reason": "resource_not_found"}
    cmd = [
        "hcloud", "IAM", "DeleteUserV5",
        f"--cli-region={region}",
        f"--user_id={user_id}",
    ]
    return run_hcloud(cmd, "Delete IAM user")


def action_delete_group(region, group_id):
    """Delete a group."""
    cmd = [
        "hcloud", "IAM", "DeleteGroupV5",
        f"--cli-region={region}",
        f"--group_id={group_id}",
    ]
    return run_hcloud(cmd, "Delete group")


ACTIONS = {
    "list-users": action_list_users,
    "detach-user-policy": action_detach_user_policy,
    "remove-user-from-group": action_remove_user_from_group,
    "delete-login-profile": action_delete_login_profile,
    "delete-access-key": action_delete_access_key,
    "delete-user": action_delete_user,
    "delete-group": action_delete_group,
}


@quality_report(skill_name=SKILL_NAME)
def main():
    parser = argparse.ArgumentParser(description=f"{SKILL_NAME} — IAM Account Revocation")
    parser.add_argument("--action", required=True, choices=list(ACTIONS.keys()),
                        help="Action to perform")
    parser.add_argument("--region", default="cn-north-4",
                        help="Huawei Cloud region (default: cn-north-4)")
    parser.add_argument("--user-id", help="IAM user ID")
    parser.add_argument("--group-id", help="IAM group ID")
    parser.add_argument("--policy-id", help="IAM policy ID")
    parser.add_argument("--access-key-id", help="IAM access key ID")
    parser.add_argument("--limit", type=int, default=50, help="Page limit for list operations")
    parser.add_argument("--marker", help="Pagination marker for list operations")
    parser.add_argument("--output", choices=["json", "text"], default="json",
                        help="Output format (default: json)")

    args = parser.parse_args()

    action_func = ACTIONS[args.action]

    kwargs = {"region": args.region}

    if args.action == "list-users":
        kwargs["limit"] = args.limit
        if args.marker:
            kwargs["marker"] = args.marker
    elif args.action == "detach-user-policy":
        if not args.policy_id or not args.user_id:
            raise QualityError("U01", "Missing required args: --policy-id and --user-id required")
        kwargs["policy_id"] = args.policy_id
        kwargs["user_id"] = args.user_id
    elif args.action == "remove-user-from-group":
        if not args.group_id or not args.user_id:
            raise QualityError("U01", "Missing required args: --group-id and --user-id required")
        kwargs["group_id"] = args.group_id
        kwargs["user_id"] = args.user_id
    elif args.action in ("delete-login-profile", "delete-user"):
        if not args.user_id:
            raise QualityError("U01", "Missing required arg: --user-id required")
        kwargs["user_id"] = args.user_id
    elif args.action == "delete-access-key":
        if not args.access_key_id or not args.user_id:
            raise QualityError("U01", "Missing required args: --access-key-id and --user-id required")
        kwargs["access_key_id"] = args.access_key_id
        kwargs["user_id"] = args.user_id
    elif args.action == "delete-group":
        if not args.group_id:
            raise QualityError("U01", "Missing required arg: --group-id required")
        kwargs["group_id"] = args.group_id

    result = action_func(**kwargs)

    if result["status"] == "success":
        output_data = {"status": "success", "action": args.action, "data": result["output"]}
    else:
        error_detail = result.get("reason", "command_failed")
        output_data = {
            "status": "failed",
            "action": args.action,
            "error": result["stderr"],
            "code": result.get("code", -1),
            "reason": error_detail,
        }
        error_map = {
            "resource_not_found": ("U03", f"Resource not found: {result['stderr']}"),
            "hcloud CLI parameter or service error detected": ("U02", f"CLI parameter/service error: {result['stderr']}"),
        }
        code, msg = error_map.get(error_detail, ("N01", f"Command failed: {result['stderr']}"))
        raise QualityError(code, msg)

    if args.output == "json":
        print(json.dumps(output_data, indent=2, ensure_ascii=False))
    else:
        print(f"Action: {args.action}")
        print(f"Status: {result['status']}")
        print(f"Output: {result['output']}")

    return output_data


if __name__ == "__main__":
    main()