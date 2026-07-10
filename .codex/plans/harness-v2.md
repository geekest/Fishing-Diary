# Harness v2 协作规则核查与升级

## 1. 任务目标

再次核查 `Fishing Diary` 个人仓库中 Codex 与 GitHub 协作相关的规则文件，并将 v1 harness 升级为 v2：让后续 Agent 在分支、PR、Review、验证和风险说明上遵循清晰、稳定、可审查的个人仓库流程。

完成后的外部表现：

- 仓库级 `AGENTS.md` 明确个人仓库 GitHub 工作流，不再只写宽泛规则。
- PR 模板与 AGENTS 规则保持一致，使用中文结构。
- `PLANS.md` 与全局 ExecPlan 规则不冲突，能指导中大型任务。
- 当前任务的发现、风险和验证结果有记录。

## 2. 当前状态

相关文件：

- `AGENTS.md`：已覆盖项目定位、技术栈、模块、开发原则、代码规范、构建验证、Git 工作流、高风险变更和完成标准。
- `PLANS.md`：当前只有 `Goal`、`Current State`、`Constraints`、`Plan`、`Risks`、`Validation` 六个简化章节。
- `.github/pull_request_template.md`：中文 PR 模板，包含背景、修改内容、测试验证、风险说明。
- `.codex/plans/`：已有历史任务计划文件。

已知问题：

- `AGENTS.md` 的 Git 工作流没有固定 `feat/xxx`、`fix/xxx`、`refactor/xxx`、`docs/xxx`、`chore/xxx` 分支命名规范。
- `AGENTS.md` 没有明确“大功能默认 Draft PR”、“Review 修复后再转正式 PR”、“合并后删除 feature branch”。
- 用户口述 PR 第 6 点中的“凤翔”应落地为“风险和回滚”，避免模板出现错字或含糊表述。
- 当前分支 `codex/harness-v2` 不符合用户提出的 `docs/xxx` 风格，但它不是 `main`，且工作区当前干净。
- `README.md` 的 iOS 16.0+ 与 `project.yml` 的 iOS 18.0 仍是待确认产品/工程约束，本次不擅自修改。

## 3. 目标状态

- `AGENTS.md` 明确个人仓库工作流：
  - `main` 只存放稳定版本。
  - 大功能、重构、修复一组问题从 `main` 新建任务分支。
  - 分支命名使用 `feat/xxx`、`fix/xxx`、`refactor/xxx`、`docs/xxx`、`chore/xxx`。
  - Codex 只能在当前任务分支上修改，不直接改 `main`。
  - 大功能默认开 Draft PR。
  - Review 问题修完后再转 Ready PR。
  - 合并后删除任务分支。
- PR 描述要求包含：背景、修改内容、测试验证、风险说明，并在风险说明中覆盖风险和回滚。
- `.github/pull_request_template.md` 与 AGENTS 中的 PR 结构一致。
- `PLANS.md` 如需升级，应对齐全局 `~/.codex/PLANS.md` 的任务级 ExecPlan 思路，不制造第二套冲突触发规则。

## 4. 范围边界

### 本次包括

- 核查仓库内协作规则文件与 GitHub 流程配置。
- 修改 `AGENTS.md` 中 Git 工作流与完成标准相关规则。
- 修改 `.github/pull_request_template.md` 的风险说明提示，补充回滚。
- 如有必要，补强仓库内 `PLANS.md` 的定位，避免与全局 ExecPlan 规则冲突。
- 运行文档级验证：文件存在性、关键词检查、Git diff 自查。

### 本次不包括

- 不修改 Swift 业务代码。
- 不修改 iOS 最低版本、WeatherKit、StoreKit 2、CloudKit/iCloud 等产品或签名配置。
- 不新增依赖。
- 按用户确认要求，完成后创建 commit、推送分支并创建中文版 PR。
- 不擅自修改 `main`；本次文档类修改落在 `docs/harness-v2` 分支。

## 5. 影响文件

- `AGENTS.md`：沉淀 v2 GitHub 协作流程。
- `.github/pull_request_template.md`：让模板与 v2 PR 要求一致。
- `PLANS.md`：只在发现明显冲突或表达不足时微调。
- `.codex/plans/harness-v2.md`：记录本任务执行计划、进度和复盘。

## 6. 执行里程碑

### Milestone 1：完成只读核查

要做：

- 检查当前分支、工作区状态和远端。
- 阅读 `AGENTS.md`、`PLANS.md`、`.github/pull_request_template.md`。
- 对比用户提出的 v2 GitHub 流程。

验证：

- 能列出当前规则缺口与不修改范围。

完成标准：

- 当前状态和已知问题已记录在本计划。

### Milestone 2：更新协作规则

要做：

- 修改 `AGENTS.md` 的 Git 工作流段落。
- 修改 PR 模板中的风险提示，明确风险与回滚。
- 必要时调整 `PLANS.md` 的描述，让它定位为仓库级计划格式补充。

验证：

- `rg` 检查关键规则均可检索。
- `git diff --check` 无空白错误。

完成标准：

- 规则覆盖用户提出的 8 点流程，不引入无关内容。

### Milestone 3：自查与交付

要做：

- 审查 diff，确认只改文档和计划文件。
- 提交 commit，推送分支并创建中文版 PR。
- 说明变更文件、行为变化、验证结果、未验证项和风险。

验证：

- `git diff -- AGENTS.md PLANS.md .github/pull_request_template.md .codex/plans/harness-v2.md` 可审查。

完成标准：

- 最终回复包含已完成内容、修改文件、验证结果、未验证内容、风险，以及是否建议继续沉淀到 AGENTS.md。

## 7. 进度记录

- [x] 阅读仓库规则与当前 Git 状态。
- [x] 创建任务级 ExecPlan。
- [x] 等待用户确认是否执行规则文件修改。
- [x] 更新 `AGENTS.md` / PR 模板 / 必要的 `PLANS.md`。
- [x] 运行文档级验证并审查 diff。
- [x] 提交 commit、推送分支并创建中文 PR。
- [x] 补充最终结果与复盘。

## 8. 新发现与意外情况

- 发现：当前分支为 `codex/harness-v2`，不符合用户提出的 `docs/xxx` 分支命名。
- 影响：不阻塞文档改动，但如果严格执行 v2 流程，建议后续改用 `docs/harness-v2` 或在下一任务开始时从 `main` 新建规范分支。
- 处理方式：本计划默认不擅自重命名分支，等待用户确认。
- 发现：用户确认继续执行并要求提交 commit 与创建中文版 PR。
- 影响：本次需要把文档类修改落在符合 v2 规则的任务分支上。
- 处理方式：已从 `codex/harness-v2` 切到 `docs/harness-v2` 后继续修改。

## 9. 决策记录

### Decision：先计划后修改

选择：

先创建 `.codex/plans/harness-v2.md`，确认后再修改规则文件。

原因：

本任务属于仓库协作流程治理，影响后续 Agent 行为，且包含分支和 PR 工作流决策，符合 ExecPlan 触发条件。

备选方案：

直接修改文档。风险是可能把用户口述流程落成过硬规则，且未先明确当前分支不符合新规范的问题。

影响：

用户确认后进入文档修改阶段。

### Decision：使用 `docs/harness-v2` 分支

选择：

将本次文档规则升级落在 `docs/harness-v2` 分支上。

原因：

这次修改属于文档和协作规则治理，符合用户提出的 `docs/xxx` 分支命名规范。

备选方案：

继续使用 `codex/harness-v2`。风险是本次 PR 自身不符合新沉淀的工作流。

影响：

本次 PR 从 `docs/harness-v2` 发起，后续合并后可删除该任务分支。

## 10. 验证计划

- `rg -n "feat/|fix/|refactor/|docs/|chore/|Draft PR|风险|回滚|main" AGENTS.md .github/pull_request_template.md PLANS.md .codex/plans/harness-v2.md`
- `git diff --check`
- `git diff -- AGENTS.md PLANS.md .github/pull_request_template.md .codex/plans/harness-v2.md`

## 11. 风险与回滚

风险较低，因为本次预计只改文档和任务计划文件，不触碰业务代码、配置、签名、依赖或数据模型。

主要风险：

- 新的分支命名规则可能与 Codex app 默认 `codex/` 分支前缀存在差异；本次按用户个人仓库规则优先。
- 如果把 `PLANS.md` 写得过重，可能与全局 `~/.codex/PLANS.md` 重复；本次仅把它定位为最小模板补充。

回滚方式：

- revert 本次文档 commit；不需要数据迁移或工程再生成。

## 12. 最终结果与复盘

已完成内容：

- `AGENTS.md` 已固化 v2 个人仓库 GitHub 工作流，包括 `main` 稳定分支、任务分支类型、Draft PR、Review 后转正式 PR、合并后删除任务分支。
- `.github/pull_request_template.md` 已补充风险和回滚提示。
- `PLANS.md` 已明确作为仓库级最小 ExecPlan 模板，并服从全局 `~/.codex/PLANS.md`。
- 本任务计划记录了从 `codex/harness-v2` 切到 `docs/harness-v2` 的决策。

验证结果：

- 已运行关键词检查，确认 `feat/`、`fix/`、`refactor/`、`docs/`、`chore/`、`Draft PR`、`Code Review`、`回滚`、`main` 等规则可检索。
- 已运行 `git diff --check`，无空白错误。
- 已审查 diff，确认只包含文档和计划文件改动。

未验证内容：

- 未运行 Xcode build/test，因为本次没有修改 Swift 业务代码或工程配置。

后续：

- 已提交 commit、推送 `docs/harness-v2` 并创建中文版 PR：`https://github.com/geekest/Fishing-Diary/pull/9`。
