# Fishing Diary

钓鱼日记是一款面向钓友的 iOS 应用原型，用来记录每一次出钓、整理渔获照片，并快速生成适合社交平台发布的渔获分享卡。

应用当前聚焦在一个完整的 MVP 流程：选择渔获照片、裁剪/抠图、填写鱼种和尺寸、带入环境数据、存入本地日记，并从记录生成分享图片。

## 图标方向

当前推荐方向围绕“钓鱼记录 + 分享图”展开：用记录页、分享卡片和鱼钩线索表达产品核心能力。完整 1024×1024 PNG 文件位于 [`docs/app-icon-concepts`](docs/app-icon-concepts)。

![App 图标方向](docs/app-icon-concepts/icon-concept-v2-record-share.png)

## 功能亮点

- **渔获日记**：按月份展示出钓记录，支持按鱼种筛选。
- **多鱼记录**：一次出钓可以记录多尾鱼，分别保存鱼种、体长、重量、钓法和备注。
- **照片处理**：支持从相册选择最多 9 张图片，并通过裁剪流程生成渔获展示图。
- **环境数据**：记录钓点、天气、风速、气压、紫外线、潮汐、月相等字段；当前为 Mock 数据，预留 WeatherKit 接入。
- **分享卡片**：将渔获、地点和环境数据渲染为 3:4 分享图，适合小红书等平台发布。
- **付费能力预留**：当前购买服务为 Mock 实现，已预留 StoreKit 2 接入位置。

## 应用流程

1. 首次打开完成引导页。
2. 从日记首页点击新增，选择渔获照片。
3. 逐张裁剪/抠图，生成每尾鱼的图片素材。
4. 填写鱼种、体长、重量、钓法和备注。
5. 选择要写入记录的环境数据字段。
6. 保存到本地日记，并可继续生成分享卡片。

## 技术栈

- Swift 5.9
- SwiftUI
- SwiftData
- XcodeGen
- TOCropViewController
- iOS 18.0+

## 项目结构

```text
FishingDiary/
├── App/                 # App 入口与根视图
├── Common/              # 主题、通用组件和卡片视图
├── Models/              # SwiftData 模型与记录流程状态
├── Resources/           # Info.plist、Assets、Entitlements
├── Services/            # 天气、购买、图片渲染服务
└── Views/               # 引导、记录、日记、分享、我的页面
```

## 本地运行

项目使用 XcodeGen 维护工程文件。如果你修改了 `project.yml`，请重新生成 Xcode 工程：

```bash
xcodegen generate
```

然后打开工程并运行：

```bash
open FishingDiary.xcodeproj
```

默认配置：

- Bundle ID：`com.placeholder.FishingDiary`
- App 名称：`钓鱼日记`
- 目标设备：iPhone
- 最低系统：iOS 16.0

> 上架前需要在 `project.yml` 中填入真实 Team ID，并按需恢复 WeatherKit / CloudKit entitlements。

## 当前状态

这是一个可运行的 MVP 原型，核心记录链路和分享卡片渲染已经搭好。以下能力仍处于 Mock 或规划阶段：

- WeatherKit 真实天气数据接入
- StoreKit 2 真实购买与恢复购买
- CloudKit/iCloud 同步
- 更多分享模板与 1:1、9:16 画幅
- 更完整的自动抠图能力

## 路线图

- [ ] 接入真实定位和反地理编码
- [ ] 接入 WeatherKit，替换 Mock 天气服务
- [ ] 接入 StoreKit 2，支持买断和订阅
- [ ] 增加更多分享卡模板
- [ ] 支持分享图高清导出和相册保存权限校验
- [ ] 增加 iCloud 同步与数据备份
- [ ] 补充单元测试和 UI 测试

## 许可证

本项目基于 [MIT License](LICENSE) 开源。
