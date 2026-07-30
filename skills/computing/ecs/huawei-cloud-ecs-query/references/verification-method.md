# Verification Method

## Environment Verification

1. Execute the environment check script:
   ```bash
   skill action=exec: bash skill://scripts/check_env.sh
   ```
2. Ensure all checks pass (Python, SDK, credentials, service availability)

## Functional Verification

### Verify Instance List Query

```bash
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_servers_details.py --region=cn-north-4
```
Expected: JSON output with `total` and `items` fields.

### Verify Instance Detail Query

```bash
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/show_server.py --region=cn-north-4 --server_id=<known_id>
```
Expected: JSON output with server details (id, name, status, flavor, image).

### Verify Flavor List Query

```bash
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/list_flavors.py --region=cn-north-4
```
Expected: JSON output with flavor list (id, name, vcpu, ram).

### Verify Keypair List Query

```bash
skill action=exec: skill://.venv/bin/python3 skill://scripts/ecs/nova_list_keypairs.py --region=cn-north-4
```
Expected: JSON output with keypair list (name, type, fingerprint).

## Data Accuracy Verification

1. Compare query results with Huawei Cloud console data
2. Verify `total` count matches console display
3. Spot-check individual resource attributes (name, status, flavor)

## Common Issues

| Issue | Solution |
|-------|----------|
| `AK/SK not configured` | Set HW_ACCESS_KEY and HW_SECRET_KEY environment variables |
| `SDK import error` | Run check_env.sh to install dependencies |
| `Empty results` | Verify region and project_id are correct |
| `Permission denied` | Check IAM policy includes ECS read actions |
