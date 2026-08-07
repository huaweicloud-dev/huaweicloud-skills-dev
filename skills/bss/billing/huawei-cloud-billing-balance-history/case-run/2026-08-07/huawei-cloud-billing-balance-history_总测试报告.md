# 总测试报告: huawei-cloud-billing-balance-history

- 生成时间: 2026-08-07
- 被测 skill: huawei-cloud-billing-balance-history
- 对应 PR: https://gitcode.com/developer-skill/huaweicloud-skills-dev/merge_requests/165
- 报告类型: PR 唯一总测试报告（一个 PR 一份）

## 一、测试统计

| 指标 | 数值 |
|------|------|
| 总用例数 | 13 |
| 通过 | 13 |
| 告警 | 0 |
| 失败 | 0 |
| 通过率 | 100.0% |

## 二、问题清单

（未发现问题单）

## 三、详细测试报告

# 整合测试报告: huawei-cloud-billing-balance-history

- 评测来源: PR #165（developer-skill/huaweicloud-skills-dev）
- 测试日期: 2026-08-07
- 被评测 skill: huawei-cloud-billing-balance-history
- 评测方式: huawei-cloud-skill-basictest 七阶段流程（准备→定边界→出正例→出反例→查重查归类→实测验证→汇总归档），使用真实华为云 BSS AK/SK 实测，执行引擎为 huawei-cloud-skill-tester + run-eval-batch 批量执行
- 用例总数: 13（正例 7 / 反例 6）
- 资源标识: dbq20260807

---

## 一、预期 vs 实际对比

| 能力点 | 预期行为 | 实际行为 | 结论 |
|--------|---------|---------|------|
| 查询当前账户余额（text） | 输出币种/欠费/各账户类型余额，退出码 0 | 输出 Currency/Debt/各账户余额，退出码 0 | ✅ 达标 |
| JSON 格式查询余额 | 输出合法 JSON | 输出含 action/currency/debt_amount/accounts 的合法 JSON | ✅ 达标 |
| 查询时间段余额变动记录 | 输出变动记录总数与明细 | 输出 Total count 与明细/空记录提示 | ✅ 达标 |
| 查询信用账户(CREDIT)变动 | 按 CREDIT 类型查询 | 正常输出，退出码 0 | ✅ 达标 |
| 按 EXPENSE 过滤收支明细 | 按支出过滤 | 正常输出，退出码 0 | ✅ 达标 |
| 查询月度消费汇总 | 输出消费总额/欠费/各服务明细 | 输出 consume_amount/debt_amount/各服务明细（含 78 条分页提示） | ✅ 达标 |
| JSON 格式月度消费 | 输出合法 JSON | 输出含 consume_amount/bill_sums 的合法 JSON | ✅ 达标 |
| 越界操作（充值） | 明确拒绝越界操作 | argparse 拒绝（invalid choice，退出码 2，列出可选 action） | ✅ 达标 |
| 无效账单周期格式 | 明确报错 YYYY-MM | 报错 bill_cycle 须为 YYYY-MM（U02） | ✅ 达标 |
| begin 晚于 end | 明确报错 | 报错 begin 不得晚于 end（U02） | ✅ 达标 |
| 缺少 AK/SK | 明确提示凭证缺失 | 报错 AK/SK not set + 环境变量名（C01） | ✅ 达标 |
| limit 超上限 | 明确报错 | 报错 limit 须在 1-100（U02） | ✅ 达标 |
| 无效日期格式 | 明确报错 | 报错 begin 须为 YYYY-MM-DD（U02） | ✅ 达标 |

## 二、报错质量评估

所有 6 条反例均给出明确、具体、可操作的错误信息（错误码 + 具体原因 + 正确格式/取值范围），报错质量评估为**良好**：

| 用例 | 报错内容 | 质量 |
|------|---------|------|
| N1 越界操作 | `argument --action: invalid choice: 'recharge' (choose from 'balance', 'changes', 'monthly-sum')` | 良好（明确列出可选值） |
| N2 无效周期 | `bill_cycle must be in YYYY-MM format, got: 2026/07 (U02)` | 良好 |
| N3 begin>end | `begin (2026-08-01) must not be later than end (2026-07-01) (U02)` | 良好 |
| N4 缺凭证 | `AK/SK not set ... (HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY or HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK) (C01)` | 良好（含完整环境变量名） |
| N5 limit 超限 | `limit must be between 1 and 100 (BSS API limit) (U02)` | 良好 |
| N6 无效日期 | `begin must be a date in YYYY-MM-DD format, got: 2026-7-1 (U02)` | 良好 |

## 三、测试统计

| 指标 | 数值 |
|------|------|
| 总用例数 | 13 |
| 通过 | 13 |
| 告警 | 0 |
| 失败 | 0 |
| 通过率 | 100.0% |

### 按用例类型统计

| 类型 | 总数 | 通过 | 告警 | 失败 |
|------|------|------|------|------|
| 正例 | 7 | 7 | 0 | 0 |
| 反例 | 6 | 6 | 0 | 0 |
| 合计 | 13 | 13 | 0 | 0 |

## 四、规范校验

- `validate-skill.sh` 校验结果：PASS 30 / FAIL 0 / WARN 2
- WARN 项为 CLI 命令操作名与 `--cli-region` 缺失——因 BSS 服务 KooCLI 不支持，本 skill 以 Python SDK 为唯一执行路径，WARN 属预期，不构成缺陷
- SKILL.md 209 行（≤500），文件 28 个（≤30），体积 1MB（≤40MB），均合规
- 无硬编码密钥（validate-skill.sh 硬编码检测 PASS）

## 五、发现的问题

本次评测**未发现问题**（无 BUG）。所有正例与反例均通过，报错质量良好，规范校验通过。

### 观察项（非缺陷，供改进参考）

1. **质量上报引入额外时延**：`skill_quality_sdk.py` 默认向 `https://skillsop.topxtopx.com/api/quality/report` 同步上报（HTTP 超时 3s）。当上报端点不可达时，每次 skill 执行会额外增加约 3.7s 时延（实测验证）。上报失败静默、不影响查询结果，符合 skill 声明；若对实时性敏感，可考虑异步上报或缩短超时（`SKILL_QUALITY_TIMEOUT` 可配）。

## 六、问题单

本次评测无失败用例、无问题单。

---

## 汇总

无 BUG，无待修复问题。


## 四、正反用例集

# 正反用例集: huawei-cloud-billing-balance-history

- 被测 skill: huawei-cloud-billing-balance-history
- 评测日期: 2026-08-07
- 能力边界: 支持三项只读查询——当前账户余额(balance)、时间段余额变动记录(changes)、月度消费汇总(monthly-sum)。不导出账单明细流水、不查询资源用量、不执行充值/退款/转账/开票等资金操作、不查询代金券/优惠券。KooCLI 不支持 BSS 服务，SDK 为唯一执行路径。

## 正例 (Positive Cases)

### P1: 查询当前账户余额

- 用户原话: 查询我华为云账户当前余额
- 命中触发词: 账户余额、查询余额
- 预期行为: 输出当前账户余额报告（币种、欠费金额、各账户类型余额），命令退出码 0
- 触发方式: 中文/英文

### P2: JSON 格式查询当前余额

- 用户原话: 用 JSON 格式查询账户余额，方便后续处理
- 命中触发词: 查询余额、account balance
- 预期行为: 输出合法 JSON（含 action/currency/debt_amount/accounts 字段），退出码 0
- 触发方式: 中文/英文

### P3: 查询时间段内余额变动记录

- 用户原话: 查询 7 月 1 日到 7 月 31 日的余额变动明细
- 命中触发词: 余额变动、收支明细
- 预期行为: 输出该时间段的余额变动记录（总数 + 明细列表，含交易时间/收付类型/变动金额），退出码 0
- 触发方式: 中文/英文

### P4: 查询信用账户余额变动

- 用户原话: 查一下信用账户的余额变动记录
- 命中触发词: 余额变动、balance change
- 预期行为: 按 CREDIT 账户类型查询变动记录并输出报告，退出码 0
- 触发方式: 中文/英文

### P5: 按支出类型过滤查询收支明细

- 用户原话: 查一下 7 月份的支出明细
- 命中触发词: 收支明细、income expense
- 预期行为: 按 EXPENSE 过滤输出余额变动记录，退出码 0
- 触发方式: 中文/英文

### P6: 查询月度消费汇总

- 用户原话: 查询 2026 年 7 月的月度账单汇总
- 命中触发词: 月度账单、月度消费、monthly bill
- 预期行为: 输出月度消费汇总（消费总额、欠费、各服务消费明细），退出码 0
- 触发方式: 中文/英文

### P7: JSON 格式查询月度消费

- 用户原话: 用 JSON 输出 2026 年 7 月的月度消费汇总
- 命中触发词: 月度消费、monthly consumption
- 预期行为: 输出合法 JSON（含 consume_amount/debt_amount/bill_sums），退出码 0
- 触发方式: 中文/英文

## 反例 (Negative Cases)

### N1: 越界操作（充值）

- 用户原话: 帮我给账户充值 100 元
- 命中触发词: 账户余额（触发 skill）
- 预期行为: 明确拒绝越界操作（充值不在能力边界内），给出清晰错误提示
- 触发方式: 中文/英文

### N2: 无效的账单周期格式

- 用户原话: 查询 2026/07 的月度账单汇总
- 命中触发词: 月度账单
- 预期行为: 明确报错 bill_cycle 格式应为 YYYY-MM（错误码 U02），退出码非 0
- 触发方式: 中文/英文

### N3: 开始日期晚于结束日期

- 用户原话: 查询 8 月 1 日到 7 月 1 日的余额变动
- 命中触发词: 余额变动
- 预期行为: 明确报错 begin 不得晚于 end（错误码 U02），退出码非 0
- 触发方式: 中文/英文

### N4: 缺少凭证

- 用户原话: 没配置密钥的情况下查询账户余额
- 命中触发词: 查询余额
- 预期行为: 明确提示 AK/SK 未配置及需设置的环境变量名（错误码 C01），退出码非 0
- 触发方式: 中文/英文

### N5: limit 超出 BSS 上限

- 用户原话: 一次查 500 条余额变动记录
- 命中触发词: 余额变动
- 预期行为: 明确报错 limit 应在 1-100（错误码 U02），退出码非 0
- 触发方式: 中文/英文

### N6: 无效日期格式

- 用户原话: 查询 2026-7-1 到 2026-07-31 的余额变动
- 命中触发词: 余额变动
- 预期行为: 明确报错 begin 须为 YYYY-MM-DD 格式（错误码 U02），退出码非 0
- 触发方式: 中文/英文

