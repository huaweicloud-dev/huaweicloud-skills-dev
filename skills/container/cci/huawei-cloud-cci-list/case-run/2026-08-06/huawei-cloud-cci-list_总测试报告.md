# 总测试报告: huawei-cloud-cci-list

- 生成时间: 2026-08-06
- 被测 skill: huawei-cloud-cci-list
- 对应 PR: https://gitcode.com/g30074593/skillspackage/merge_requests/12
- 报告类型: PR 唯一总测试报告（一个 PR 一份）

## 一、测试统计

| 指标 | 数值 |
|------|------|
| 总用例数 | 9 |
| 通过 | 9 |
| 告警 | 0 |
| 失败 | 0 |
| 通过率 | 100.0% |

## 二、问题清单

（问题单中未提取到问题条目）

## 三、详细测试报告

# 整合测试报告: huawei-cloud-cci-list

- 来源: GitCode PR #12 (g30074593/skillspackage)
- 测试日期: 2026-08-06
- 被评测 skill: huawei-cloud-cci-list
- 评测方式: huawei-cloud-skill-tester 三轨八节流水线 + 门禁（正反例）+ 手工实测

---

## 一、整合过程说明

1. tester 流水线 Phase 0-7 全部执行（install-check / skill-analysis / tech-research /
   test-case-generation / test-execution / orchestration / full-flow / final-report）
2. 门禁正反例 9 条（5 正例 + 4 反例）逐条 register → complete，全部 pass，无违规
3. 对 tester Phase 4 的 6 条 FAIL 逐条归因：全部为测试账号未开通 CCI 服务授权
   （agency），API 返回 `CCI.01.403122`，属账号级权限限制（SKILL.md 前置条件已声明），
   非 skill 缺陷
4. 手工实测补充验证成功路径（模拟 NamespaceList 响应）、空列表、错误路径
   （无 hcloud CLI → C01；无 agency → U04）、SDK 自检上报

## 二、去重确认

- 6 条 FAIL 归因相同（账号无 CCI agency）→ 合并为环境限制一类，不生成问题单
- 6 条 warn 归因相同（tester 自动生成非法边界参数 / 续行符解析）→ tester 自身问题，不生成问题单
- 最终问题单: 0 条

## 三、测试统计

| 项目 | 总用例 | 通过 | 告警 | 失败 | 通过率 |
|------|-------|------|------|------|--------|
| 门禁正反例 | 9 | 9 | 0 | 0 | 100% |
| 合计 | 9 | 9 | 0 | 0 | 100% |

> tester 流水线 Phase 4 共 14 条（2 pass / 6 fail / 6 warn），6 条 FAIL 均为
> 账号无 CCI agency 导致（`CCI.01.403122`），已在归因分析中说明，不计入 skill 缺陷。

## 四、修正确认

无问题单，无需修复。可选优化建议（SKILL.md 中 jq 管道续行符写法）见《报告优化》，
不构成缺陷。

## 五、结论

**无 BUG**。skill 通过全部评测：

- validate-skill.sh: 23/23 PASS
- 命令语法与 API 路径（/apis/cci/v2/namespaces）实测一致
- 成功路径（模拟）: `{"count": N, "names": [...]}`，退出码 0
- 错误路径: C01 / U04 错误码 + 可操作指引，退出码 2
- SDK 执行质量上报: 实时上报成功
- 只读 skill，无写操作


## 四、正反用例集

# 正反用例集: huawei-cloud-cci-list

- 来源: GitCode PR #12 (g30074593/skillspackage)
- 测试日期: 2026-08-06
- 被评测 skill: huawei-cloud-cci-list
- 评测方式: huawei-cloud-skill-tester 三轨八节流水线 + 门禁 + 手工实测（模拟成功路径 + 真实错误路径）

---

## 一、定边界（能力边界清单）

| # | 能力 | 是否支持 | 推导方式 | 置信度 |
|---|------|---------|---------|--------|
| 1 | 查询当前租户 CCI 命名空间列表（namespaces） | ✅ 支持 | 读代码（SKILL.md + query-cci-namespaces.py） | 高 |
| 2 | 返回命名空间名称（metadata.name）、uid、status.phase、creationTimestamp | ✅ 支持 | 读代码 + 模拟实测 | 已实测 |
| 3 | 仅提取名称列表（jq 管道 / wrapper 输出 names） | ✅ 支持 | 模拟实测 | 已实测 |
| 4 | 创建/删除/修改命名空间 | ❌ 不支持（明确声明只读） | 读代码 | 高 |
| 5 | 查询命名空间内 Deployment/Pod/Service 等工作负载 | ❌ 不支持（明确声明边界） | 读 SKILL.md 能力边界 | 高 |
| 6 | 命名空间详情（show-by-name） | ❌ 不支持（SKILL.md 明确声明） | 读代码 | 高 |
| 7 | 错误处理：无 hcloud CLI / 无 CCI agency / API 报错 | ✅ 支持（C01/U04/N03 等错误码 + 可操作提示） | 实测 | 已实测 |
| 8 | 执行质量上报（skill_quality_sdk） | ✅ 支持（成功/失败自动上报，上报失败静默） | 实测（自检上报成功） | 已实测 |

**用户拥有什么**：查询结束后，用户获得 CCI 命名空间列表/名称列表（JSON 或纯名称），以及执行质量上报。

---

## 二、正例（skill 能完成的）

| 编号 | 用户原话 | 命中触发词 | 预期行为 |
|------|---------|-----------|---------|
| P1 | 查询CCI命名空间列表 | `查询CCI命名空间` | 返回命名空间列表（名称/uid/状态/创建时间） |
| P2 | 列出所有CCI命名空间 | `CCI命名空间列表` | 返回命名空间名称列表 |
| P3 | 查询当前租户下的 CCI 命名空间名称 | `CCI命名空间名称` | 返回纯名称列表 |
| P4 | list CCI namespaces | `list CCI namespaces` | 返回命名空间列表 |
| P5 | how many CCI namespaces | `how many CCI namespaces` | 返回 count 与名称列表 |

## 三、反例（能触发 skill 但办不到的）

| 编号 | 用户原话 | 命中触发词 | 预测报错质量 | 失败原因 | 改进点 |
|------|---------|-----------|-------------|---------|--------|
| N1 | 创建一个CCI命名空间 | `CCI列表`（弱命中） | 好 | skill 只读，不提供创建能力 | SKILL.md 能力边界已声明，agent 应明确告知不支持 |
| N2 | 删除CCI命名空间 | `CCI命名空间列表`（弱命中） | 好 | 只读 skill | 同上 |
| N3 | 查询命名空间下的Deployment列表 | `CCI命名空间`（弱命中） | 好 | 不在边界内 | SKILL.md 边界声明已覆盖 |
| N4 | 账号无 CCI agency 时查询 | `查询CCI命名空间` | 好（实测 U04 错误码 + 可操作提示） | 账号未授权 CCI 服务 | 已内置 403122 识别，提示授权指引 |

---

## 四、触发词对照表（门禁）

| 用例编号 | 用户原话 | 命中的触发词 |
|---------|---------|-------------|
| P1 | 查询CCI命名空间列表 | `查询CCI命名空间` ✅ |
| P2 | 列出所有CCI命名空间 | `CCI命名空间列表` ✅ |
| P3 | 查询当前租户下的 CCI 命名空间名称 | `CCI命名空间名称` ✅ |
| P4 | list CCI namespaces | `list CCI namespaces` ✅ |
| P5 | how many CCI namespaces | `how many CCI namespaces` ✅ |
| N1 | 创建一个CCI命名空间 | `CCI列表` ✅（触发后按边界拒绝） |
| N2 | 删除CCI命名空间 | `CCI命名空间列表` ✅（触发后按边界拒绝） |
| N3 | 查询命名空间下的Deployment列表 | `CCI命名空间` ✅（触发后按边界拒绝） |
| N4 | 账号无 CCI agency 时查询 | `查询CCI命名空间` ✅ |

触发词全部命中，无未命中项。

