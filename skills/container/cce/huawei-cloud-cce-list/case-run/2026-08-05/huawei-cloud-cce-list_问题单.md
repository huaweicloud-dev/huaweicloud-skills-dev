# 问题单: huawei-cloud-cce-list

- 来源: https://gitcode.com/g30074593/skillspackage/merge_requests/3
- 测试日期: 2026-08-05
- 被测 skill: huawei-cloud-cce-list
- 评测方式: huawei-cloud-skill-tester 八阶段流水线 + 真实环境实测
- 问题数量: 1
- 缺陷分类: 文档缺口 1

---

## 问题 1: SKILL.md 通用格式模板段被 tester 提取为伪命令导致误报

| 字段 | 内容 |
|------|------|
| 编号 | HUAWEI-CLOUD-CCE-LIST-ISSUE-001 |
| 严重级别 | LOW |
| 缺陷分类 | 文档缺口 |
| 发现来源 | tester Phase 4 执行（TC-F-13 / TC-F-14） |
| 复现次数 | 稳定复现（框架每次从模板段提取） |

### 触发输入

> （框架自动生成，非用户输入）`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

### 预期行为

测试框架从 SKILL.md 提取的应是 skill 的真实命令（如 `hcloud CCE ListClusters --cli-region={region}`）。

### 实际行为

tester 将 SKILL.md 中"KooCLI Command Format Standard"章节的**通用占位符模板**
`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]` 当作一条可执行命令提取，
生成 TC-F-13/TC-F-14 并执行，得到 `[USE_ERROR]Unsupported service: [--key=value` —— 2 条失败。

### 报错质量

一般（这是 tester 框架的提取误判，不是 skill 运行时报错）。

### 具体问题

SKILL.md 第 141-147 行的"KooCLI Command Format Standard"章节包含形如
`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]` 的通用格式说明模板。
测试框架的 Phase 1 命令提取器将其误识别为 skill 的真实命令（含 `<Service>`/`<Operation>` 未替换占位符），
导致 Phase 4 生成 2 条必然失败的伪命令用例。**skill 自身的真实命令（SKILL.md Core Commands 章节）
全部实测通过**，此问题不影响 skill 功能，但会污染自动化测试报告。

### 影响分析

- 测试报告 Phase 4 出现 2 条"失败"用例，整体 verdict 从 PASS 降为 PARTIAL；
- 后续该 skill 每次自动测试都会稳定复现这 2 条误报，干扰对 skill 真实质量的判断。

### 改进点

1. **治本（推荐，skill 侧）**：将"KooCLI Command Format Standard"章节的通用模板段改写为
   非代码块形式（如表格或说明文字），避免被框架当作可执行命令提取；或去掉占位符模板中的
   `<Service> <Operation>` 字样，改为纯文字描述（如"hcloud 命令格式为：
   服务名 + 操作名 + --cli-region 参数"）。
2. **框架侧（可选）**：tester Phase 1 命令提取器过滤含 `<...>` 未替换占位符的代码块，不生成测试用例。
3. **改后预期**：tester Phase 4 将不再产生伪命令误报，skill 测试报告 verdict 恢复为 PASS。

---

## 汇总

| 编号 | 严重级别 | 缺陷分类 | 问题 | 报错质量 | 状态 |
|------|----------|---------|------|---------|------|
| HUAWEI-CLOUD-CCE-LIST-ISSUE-001 | LOW | 文档缺口 | SKILL.md 通用格式模板被 tester 提取为伪命令导致 2 条误报 | 一般 | 建议修复 |

### 按严重级别统计

- HIGH: 0
- MEDIUM: 0
- LOW: 1

### 按报错质量统计

- 好: 0
- 一般: 1
- 差: 0

---

> 说明：PR 创建人为 g30074593（非 skills_bot），但本问题为 LOW 级文档缺口、不影响 skill 功能，
> 且已在总测试报告中完整呈现。按流程创建 BUG issue 会为单条 LOW 文档建议增加流程噪音，
> 故以 PR 评论形式提交总测试报告（含该问题单），由 PR 创建人决定是否采纳改进建议。
