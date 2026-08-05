# 问题单: huawei-cloud-gaussdb-count（重测）

- 来源: GitCode PR #139 重测（skills_test 小队）
- 测试日期: 2026-08-05
- 被评测 skill: huawei-cloud-gaussdb-count
- 评测方式: huawei-cloud-skill-tester 流水线 + 真实华为云 CLI/SDK 逐条实测
- 问题数量: 0（首测 1 项 ISSUE-001 已在重测中确认修复）
- 缺陷分类: 无

---

## 首测问题（已修复）

### 问题 1: SDK 回退脚本移除异常处理，错误凭证时抛出完整 traceback（回归 ISSUE-001）

| 字段 | 内容 |
|------|------|
| 编号 | HUAWEI-CLOUD-GAUSSDB-COUNT-ISSUE-001 |
| 严重级别 | MEDIUM |
| 缺陷分类 | 逻辑错误 |
| 发现来源 | 首测阶段六实测（N3 反例）、对比 main 分支 |
| 复现次数 | 首测稳定复现 |
| **状态** | **已修复（重测验证通过）** |

### 触发输入

> 用错误凭证统计GaussDB数量

### 预期行为

SDK 回退脚本 `scripts/count_gaussdb_instances.py` 在凭证错误时捕获 `ClientRequestException`/`SdkException`，输出简洁可操作的错误提示，exit(1)，不输出原始 traceback。

### 实际行为（首测）

PR 首版在移除 size 统计功能时删除了异常处理（`try/except` 与 `_fail`），错误凭证实测输出完整未捕获 traceback。

### 修复提交

`7d51d17 fix: restore exception handling in count_gaussdb_instances.py`——恢复 `_fail`、`try/except ClientRequestException/SdkException`，并补充 region 校验。

### 重测验证（通过）

```
ERROR: GaussDB for openGauss query failed: SdkException - ... Check the AK/SK credentials and network connectivity.
```
stderr + exit(1)，无 traceback；无效区域同样输出简洁 ERROR。报错质量由「差」提升为「好」，与 main 分支一致。

---

## 汇总

| 编号 | 严重级别 | 缺陷分类 | 问题 | 报错质量 | 状态 |
|------|----------|---------|------|---------|------|
| HUAWEI-CLOUD-GAUSSDB-COUNT-ISSUE-001 | MEDIUM | 逻辑错误 | SDK 回退脚本移除异常处理，错误凭证时输出完整 traceback（回归） | 差→好 | **已修复** |

### 按严重级别统计

- MEDIUM: 1（已修复）

### 按报错质量统计

- 好: 1（修复后）
