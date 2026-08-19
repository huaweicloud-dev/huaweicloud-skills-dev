# Acceptance Criteria

| ID | Criteria | Verification Method |
|----|----------|-------------------|
| AC-01 | Skill can list IAM users | `ListUsersV5` returns non-empty user list |
| AC-02 | Skill can detach policy from user | `DetachUserPolicyV5` returns HTTP 204 |
| AC-03 | Skill can detach policy from group | `DetachGroupPolicyV5` returns HTTP 204 |
| AC-04 | Skill can remove user from group | `RemoveUserFromGroupV5` returns HTTP 204 |
| AC-05 | Skill can revoke role from user on EP | `RevokeRoleFromUserOnEnterpriseProject` returns success |
| AC-06 | Skill can delete login profile | `DeleteLoginProfileV5` returns HTTP 204 |
| AC-07 | Skill can delete access key | `DeleteAccessKeyV5` returns HTTP 204 |
| AC-08 | Skill can delete MFA device | `DeleteVirtualMfaDeviceV5` returns HTTP 204 |
| AC-09 | Skill can delete group | `DeleteGroupV5` returns HTTP 204 |
| AC-10 | Skill can delete IAM user | `DeleteUserV5` returns HTTP 204 |
| AC-11 | All hcloud commands include `--cli-region` parameter | Manual inspection |
| AC-12 | All IAM operations use correct PascalCase operation names | Manual inspection |
| AC-13 | SKILL.md contains all required sections | validate-skill.sh passes |
| AC-14 | IAM policies document follows least-privilege principle | Manual review |