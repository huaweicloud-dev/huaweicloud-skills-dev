# Data Flow Diagram

```mermaid
flowchart TD
    A[Agent Invocation] --> B[Identify Target User]
    B --> C[Query: ListUsersV5]
    C --> D{User Found?}
    D -->|No| E[Report: User Not Found]
    D -->|Yes| F[Phase 1: Detach Policies]
    
    F --> G[DetachUserPolicyV5]
    G --> H[RemoveUserFromGroupV5]
    H --> I[RevokeRoleFromUserOnEnterpriseProject]
    
    I --> J[Phase 2: Revoke Access]
    J --> K[DeleteLoginProfileV5]
    K --> L[DeleteAccessKeyV5]
    L --> M[DeleteVirtualMfaDeviceV5]
    
    M --> N[Phase 3: Delete User]
    N --> O[DeleteUserV5]
    O --> P{Success?}
    P -->|Yes| Q[Report: User Revoked]
    P -->|No| R[Report: Error Details]
    
    Q --> S[Optional: Clean Up Groups]
    S --> T[DeleteGroupV5]
    T --> U[Done]
```

## Flow Description

1. **Identify** — List all users or users in a specific group
2. **Detach** — Remove all policies and group memberships from the user
3. **Revoke** — Delete console login, access keys, and MFA devices
4. **Delete** — Remove the IAM user account
5. **Clean up** — Optionally delete empty groups