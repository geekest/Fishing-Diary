# 分享卡模板解锁与扩展

## 1. 任务目标

当前「选尺寸 · 风格」页里只有「极简数据卡」可用，其他模板显示为空或锁定；用户希望默认视为已付费用户，可以随意选择任意模板并用于最终分享导出。完成后，现有模板都能选择、预览和导出；如果时间允许，新增一组更贴近主流社交分享卡的模板，作为产品卖点。

## 2. 当前状态

- `ShareStyleView.CardStyle` 已列出 `minimal`、`tech`、`sticker`、`film`，但 `isFree` 只允许 `minimal`。
- `ShareStyleView` 的模板缩略图有占位 UI，但非 `minimal` 没有正式卡片实现。
- `ShareElementsView` 接收 `style`，但跳转 `PreviewExportView` 时没有继续传递。
- `PreviewExportView` 和 `ImageRenderService.renderCard` 只渲染 `MinimalCardView`。
- `PurchaseService` 仍按 `isPurchased` 控制水印、分享按钮和付费墙。
- 当前验证方式是 iPhone 17 模拟器 Debug 构建；暂无自动化 UI 测试。

## 3. 目标状态

- 默认把当前用户视为已付费用户，模板选择和导出不再被付费状态阻塞。
- `selectedStyle` 从选择页贯穿到元素配置页、出图预览页和导出渲染服务。
- 现有 `tech`、`sticker`、`film` 至少拥有可预览、可导出的正式模板，而不是灰色空壳。
- 新增若干主流分享卡模板，例如杂志封面、社交海报、标本档案等。
- 所有模板支持 3:4、1:1、9:16 画幅。

## 4. 范围边界

### 本次包括

- 解除当前模板选择限制。
- 默认购买状态为已解锁。
- 将模板风格参数接入预览与导出链路。
- 在现有 Swift 文件中补充模板实现，避免额外 XcodeGen 工程再生成成本。
- 分两次提交：一次修复权限和现有模板，一次新增模板。

### 本次不包括

- 不接入真实 StoreKit。
- 不修改持久化模型或 SwiftData schema。
- 不新增生产依赖。
- 不处理相册权限、支付回调或 PR 转正式。

## 5. 影响文件

- `FishingDiary/Views/Share/ShareStyleView.swift`：模板枚举、选择状态、缩略图、共享预览组件。
- `FishingDiary/Views/Share/ShareElementsView.swift`：继续传递所选模板。
- `FishingDiary/Views/Share/PreviewExportView.swift`：根据模板预览和导出。
- `FishingDiary/Services/ImageRenderService.swift`：根据模板渲染图片。
- `FishingDiary/Services/PurchaseService.swift`：默认付费状态。
- `FishingDiary/Views/Share/Templates/MinimalCardView.swift`：复用现有模板及追加其他模板实现。

## 6. 执行里程碑

### Milestone 1：打通现有模板和权限

要做：

- 让所有现有模板可点击选择。
- 让默认用户视为已付费。
- 把 `style` 传到 `PreviewExportView` 和 `ImageRenderService`。
- 为 `tech`、`sticker`、`film` 提供正式卡片视图。

验证：

- iPhone 17 模拟器 Debug 构建通过。
- 静态检查调用链中不再丢失 `selectedStyle`。

完成标准：

- 第一条提交完成，现有模板不再是空壳。

### Milestone 2：新增模板卖点

要做：

- 扩展 `CardStyle`，新增若干主流分享模板。
- 为新增模板提供缩略图和正式导出视图。

验证：

- iPhone 17 模拟器 Debug 构建通过。
- `git diff --check` 通过。

完成标准：

- 第二条提交完成并推送到 Draft PR。

## 7. 进度记录

- [x] 阅读计划规范和 SwiftUI skill
- [x] 确认当前模板调用链
- [x] 完成 Milestone 1
- [x] 运行 Milestone 1 构建验证
- [ ] 提交 Milestone 1
- [ ] 完成 Milestone 2
- [ ] 运行最终验证
- [ ] 提交并推送 Milestone 2
- [ ] 补充复盘

## 8. 新发现与意外情况

- 发现：当前 `.xcodeproj` 不会自动纳入新 Swift 文件。
- 影响：模板实现暂时集中在现有 `MinimalCardView.swift` 内，避免重新生成工程导致无关 diff。
- 处理方式：后续模板稳定后再考虑拆分文件并运行 XcodeGen。

## 9. 决策记录

### Decision：把模板实现保留在现有 target 文件中

选择：在 `MinimalCardView.swift` 内补充模板渲染入口和模板视图。

原因：当前 `.xcodeproj` 不会自动纳入新 Swift 文件，新增文件需要重新生成工程，容易扩大 diff。

备选方案：新增独立模板文件并运行 `xcodegen generate`。

影响：单文件会变长，但本次范围更小，后续模板稳定后可以再拆分。

## 10. 验证计划

- `git diff --check`：预期无空白错误。
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project FishingDiary.xcodeproj -scheme FishingDiary -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' build`：预期构建通过。
- 手动验证路径：日记详情或保存页进入「生成分享图」→ 选择各模板 → 下一步 → 出图预览。

## 11. 风险与回滚

- 风险：新增模板视觉质量需要实机继续调优。
- 风险：模板视图集中在一个文件内，后续可维护性一般。
- 回滚：回滚本任务新增的两个提交即可恢复到现有 PR 状态。

## 12. 最终结果与复盘

待完成后补充。
