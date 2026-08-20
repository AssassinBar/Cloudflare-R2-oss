# 库存通 · InventoryApp

原生 iOS（SwiftUI）进销存框架，Apple 浅色质感 UI，内置 Mock 数据，便于后续对接真实 API。

## 要求

- Xcode 15+
- iOS 17.0+
- Swift 5.9+

## 打开工程

```bash
cd InventoryApp
open InventoryApp.xcodeproj
```

选择模拟器或真机，运行即可。首次打开请在 Signing 中选择你的 Team。

## 功能模块

| Tab / 入口 | 说明 |
| --- | --- |
| 概览 | 今日销售/进货、库存总值、预警、最近动态 |
| 商品 | 列表搜索、详情 |
| 进货 | 采购单列表与明细 |
| 销售 | 销售单列表与明细 |
| 更多 → 库存 | 库存总值与出入库流水 |
| 更多 → 往来 | 供应商 / 客户 |
| 更多 → 设置 | Mock / Remote 环境切换 |

## 架构（方便对接接口）

```
UI (SwiftUI)
  → ViewModels (@Observable)
    → InventoryServicing 协议
      → MockInventoryService   // 默认
      → RemoteInventoryService // 真实后端
        → APIClient
```

切换数据源：

1. App 内「设置」打开「使用远程 API」并填写 Base URL，或
2. 代码中修改 `AppEnvironment.current`（见 `APIClient.swift`）

对接步骤建议：

1. 按后端路径改 `RemoteInventoryService.swift` 里各 `APIRequest` 的 `path` / `queryItems`
2. 字段命名若非 snake_case，调整 `APIClient` 的编解码策略
3. 登录成功后：`await client.setAuthToken(token)`
4. 将 `ServiceFactory.makeInventoryService()` 切到 `.remote`

## 设计说明

- 主色：近白背景 + 纯白卡片 + 系统蓝点缀
- 动效：启动过渡、列表错落入场、按钮按压缩放、Tab 轻触反馈
- 圆角连续曲线、轻阴影，贴近 Apple HIG 浅色产品气质

## 目录

```
InventoryApp/
├── InventoryApp.xcodeproj
└── InventoryApp/
    ├── App/                 # 入口、Tab
    ├── Core/
    │   ├── Design/          # 主题、动画、组件
    │   ├── Models/
    │   ├── Networking/      # APIClient
    │   └── Services/        # 协议 / Mock / Remote / ViewModels
    ├── Features/            # 各业务页面
    └── Resources/
```
