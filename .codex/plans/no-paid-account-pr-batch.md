# 无付费开发者账号下的 PR 拆分计划

## 1. 任务目标

用户当前没有 Apple 付费开发者账号，需要在不依赖 WeatherKit、StoreKit 2、CloudKit、真实 Team ID 或 entitlements 的前提下，继续推进可验收的 Fishing Diary 产品成果。

完成后应产出多个可独立合并到 `main` 的 PR，每个 PR 只覆盖一个大的行动项，便于第二天逐个验收。

## 2. 当前状态

- `main` 最新提交为 `5453246`，已合并记录编辑体验。
- 当前打开的 Draft PR #11 来自 `fix/share-preview-scale`，包含分享卡预览、字号、模板解锁和多模板扩展。
- `project.yml` 已移除 WeatherKit / CloudKit entitlements，`DEVELOPMENT_TEAM` 为空，适合无付费账号的模拟器验证。
- README 仍把 WeatherKit、StoreKit 2、CloudKit 放在近期路线中，且最低系统描述与 `project.yml` 不一致。

## 3. 目标状态

- 近期路线转向本地优先能力：本地导出、手动兜底、离线可演示。
- 付费开发者账号相关能力只作为上架前或后续阶段任务。
- 每个行动项单独分支、提交和 PR，目标分支都是 `main`。

## 4. 范围边界

### 本次包括

- 更新 README 中的当前状态、近期路线和无付费账号约束。
- 实现至少一个本地优先功能 PR。
- 每个 PR 都从 `main` 新建独立分支。

### 本次不包括

- 不接入 WeatherKit、StoreKit 2、CloudKit。
- 不修改 SwiftData schema、entitlements、CI/CD 或生产签名配置。
- 不直接合并 PR。

## 5. 影响文件

- `README.md`：记录阶段策略和路线图。
- 后续功能 PR 会按各自范围修改 Swift 文件。

## 6. 执行里程碑

### Milestone 1：收尾现有分享卡 PR

要做：

- 确认 #11 分支工作区干净。
- 清理本地冲突残留并运行构建。

验证：

- `git diff --check`
- iOS Simulator Debug build

完成标准：

- #11 可干净合并，构建通过。

### Milestone 2：文档路线 PR

要做：

- 从 `main` 创建 `docs/no-paid-roadmap`。
- 更新 README，明确本地优先路线。

验证：

- `git diff --check`
- 文档 diff 自查

完成标准：

- 创建面向 `main` 的 PR。

### Milestone 3：本地优先功能 PR

要做：

- 从 `main` 继续拆分独立分支。
- 优先实现不依赖付费账号的本地导出、手动兜底或离线演示能力。

验证：

- 相关 Swift 编译构建。
- `git diff --check`

完成标准：

- 每个功能拥有独立 commit 和 PR。

## 7. 进度记录

- [x] 阅读仓库规则、计划规范和 GitHub 发布规则。
- [x] 检查 Git 历史、当前分支、打开 PR 和工作区状态。
- [x] 验证现有分享卡 PR。
- [x] 创建文档路线分支。
- [ ] 提交并创建文档路线 PR。
- [ ] 创建后续功能分支、提交和 PR。

## 8. 新发现与意外情况

- 发现：`fix/share-preview-scale` 本地曾出现冲突标记，但清理后工作区与 HEAD 一致。
- 影响：无需为 #11 追加提交。
- 处理方式：用构建验证 #11 当前状态。

## 9. 决策记录

### Decision：近期路线改成本地优先

选择：

将 WeatherKit、StoreKit 2、CloudKit 放入付费开发者账号或上架准备阶段，近期优先做本地数据与分享体验。

原因：

用户明确当前没有 Apple 付费开发者账号，继续围绕付费 capability 做需求会阻塞验收。

备选方案：

继续保留 WeatherKit / StoreKit / CloudKit 作为近期任务。风险是需求不可验收，且会引入签名和账号配置成本。

影响：

后续 PR 应优先选择模拟器和本地数据即可验证的功能。

## 10. 验证计划

- `git diff --check`
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project FishingDiary.xcodeproj -scheme FishingDiary -configuration Debug -destination 'generic/platform=iOS Simulator' build`
- PR 页面确认目标分支为 `main`

## 11. 风险与回滚

本计划本身是文档和任务拆分，风险低。后续功能 PR 需要各自说明行为变化和回滚方式。

回滚方式：revert 对应 PR 的 commit，不涉及数据迁移。

## 12. 最终结果与复盘

待本轮 PR 创建完成后补充。
