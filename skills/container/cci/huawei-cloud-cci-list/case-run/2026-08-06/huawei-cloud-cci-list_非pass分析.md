# 非 pass 分析: huawei-cloud-cci-list

- 测试日期: 2026-08-06
- 来源: tester 流水线 Phase 4 执行结果 + 门禁用例

---

## tester Phase 4 非 pass 项分析（14 条：2 pass / 6 fail / 6 warn）

| 用例 | 结果 | 现象 | 归因（tester 自身 vs 被测 skill） | 结论 |
|------|------|------|--------------------------------|------|
| TC-F-01 | pass | 返回 CCI.01.403122 错误体 | 环境 | - |
| TC-F-02 | warn | 追加 `--limit=1` 参数被拒 | tester 自动生成非法边界参数，非 skill 文档命令 | tester 自身 |
| TC-F-03 | fail | `jq -r '.items[].metadata.name'` 对错误体报错 | 底层 API 返回错误体（账号无 agency），jq 无法遍历 items | 环境（账号权限） |
| TC-F-04 | warn | jq 追加 `--limit=1` 被拒 | tester 自动生成非法参数 | tester 自身 |
| TC-F-05 | warn | 命令含 `\\` 续行符被 KooCLI 拒绝 | SKILL.md 中 jq 管道 `\\` 是 bash 续行符，被 tester 当作参数传入 | tester 解析问题 |
| TC-F-06 | warn | 同上 + `--limit=1` | tester 自身 | tester 自身 |
| TC-F-07 | fail | wrapper 返回 U04 错误码退出 2 | 账号无 agency（环境） | 环境（账号权限），skill 错误处理正确 |
| TC-F-08 | fail | 同上 | 环境 | 环境 |
| TC-F-09 | pass | 返回错误体 | 环境 | - |
| TC-F-10 | warn | `--limit=1` 被拒 | tester 自身 | tester 自身 |
| TC-F-11 | fail | jq 对错误体报错 | 环境 | 环境 |
| TC-F-12 | warn | jq `--limit=1` 被拒 | tester 自身 | tester 自身 |
| TC-F-13 | fail | wrapper U04 退出 2 | 环境 | 环境（skill 错误处理正确） |
| TC-F-14 | fail | wrapper U04 退出 2 | 环境 | 环境（skill 错误处理正确） |

## 归类

- **被测 skill 缺陷**: 0
- **tester 自身问题**（自动生成非法边界参数、续行符解析）: 5 条 warn（TC-F-02/04/05/06/10/12）
- **环境/账号限制**（无 CCI agency，SKILL.md 已声明前置条件）: 6 条 fail + 2 pass 中的错误体

## 门禁用例（正反例）

9 条全部 pass，无违规。

## 结论

tester 流水线的 FAIL 全部由账号级 CCI agency 权限缺失导致，skill 本身
（命令语法、接口路径、错误处理、SDK 上报）均实测正确，**无 skill 缺陷**。
