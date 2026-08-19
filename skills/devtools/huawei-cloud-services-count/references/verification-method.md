# Verification Method

## Verify the Skill Works

### 1. Check that metadata exists
```bash
ls -l ~/.hcloud/metaRepo/service_en.json
```

### 2. Query service count
```bash
python3 -c "
import json, os
with open(os.path.expanduser('~/.hcloud/metaRepo/service_en.json')) as f:
    data = json.load(f)
items = data.get('items', [])
print(f'Service count: {len(items)}')
"
```

### 3. Expected Output
```
Service count: 150
```

The exact number may vary slightly as new services are added by Huawei Cloud.