# CryptoLedger

一款 iOS 原生加密货币盈亏追踪应用，采用 **iOS 26/27 Liquid Glass（液态玻璃）** 设计语言，简约高级，动画丰富。

## 功能特性

### 核心功能
- **现货 & 合约** 交易盈亏记录
- **30+ 主流加密货币** 可选，自带 CoinGecko 官方图标
- **实时盈亏统计**：总盈亏、现货/合约分类、胜率分析
- **盈亏曲线图**：动态绘制累计 P&L 走势
- **持仓管理**：开仓记录、平仓操作、杠杆倍数

### 用户体验
- **Liquid Glass UI**：iOS 26+ 原生 `.glassEffect()` + 向下兼容毛玻璃效果
- **丰富动画**：启动页 3D 旋转、数字滚动、交错入场、弹簧交互、Shimmer 光效
- **浮动 Tab Bar**：液态玻璃底部导航栏
- **简约设计**：深色主题 + 青紫渐变点缀

### 账号 & 通知
- **注册 / 登录**：本地 SHA-256 加密存储
- **推送通知**：平仓盈亏提醒、合约持仓提醒
- **通知中心**：应用内消息列表，未读标记

## 系统要求

- **Xcode 16+**（推荐 Xcode 26 beta 以获得完整 Liquid Glass 效果）
- **iOS 17.0+**（Liquid Glass 原生效果需 iOS 26+）
- macOS 14+

## 快速开始

```bash
# 1. 克隆仓库
git clone <repo-url>
cd CryptoLedger

# 2. 用 Xcode 打开项目
open CryptoLedger.xcodeproj

# 3. 选择模拟器或真机，点击 Run (⌘R)
```

### 首次运行
1. 启动后会显示 Liquid Glass 风格 Splash 动画
2. 注册一个新账号（邮箱 + 密码）
3. 在「添加」页面记录您的第一笔交易
4. 在「概览」查看盈亏统计和曲线

## 项目结构

```
CryptoLedger/
├── CryptoLedgerApp.swift          # 应用入口 & 启动页
├── Theme/
│   ├── LiquidGlassTheme.swift     # 设计系统色彩 & 背景
│   └── GlassModifiers.swift       # Liquid Glass 修饰符
├── Models/
│   ├── User.swift                 # 用户模型
│   ├── TradeRecord.swift          # 交易记录 & P&L 计算
│   └── CryptoAsset.swift          # 30+ 加密货币目录
├── Services/
│   ├── AuthService.swift          # 认证服务
│   ├── TradeStore.swift           # 交易数据持久化
│   └── NotificationManager.swift  # 通知管理
├── Components/
│   ├── GlassCard.swift            # 玻璃卡片 & 通用组件
│   ├── PnLChartView.swift         # 盈亏曲线图
│   └── FloatingTabBar.swift       # 浮动导航栏
└── Views/
    ├── Auth/                      # 登录 & 注册
    ├── Dashboard/                 # 概览面板
    ├── Trades/                    # 交易列表 & 添加
    └── Profile/                   # 个人中心 & 通知
```

## 支持的加密货币

BTC, ETH, BNB, SOL, XRP, ADA, DOGE, DOT, AVAX, MATIC, LINK, LTC, UNI, ATOM, NEAR, APT, ARB, OP, SUI, PEPE, SHIB, TRX, TON, FIL, INJ, WLD, SEI, TIA, FTM, AAVE 等 30 种。

## 设计亮点

| 特性 | 说明 |
|------|------|
| Liquid Glass | iOS 26 `.glassEffect()` 原生液态玻璃，iOS 17-25 自动降级为 Material |
| 动画系统 | Spring 弹簧、Stagger 交错、Shimmer 闪光、3D Rotation |
| 深色主题 | 自适应深色模式，渐变背景动态漂移 |
| 高端图标 | 1024×1024 定制 App Icon，液态玻璃 + 金色质感 |

## 注意事项

- 当前版本使用 **本地存储**（UserDefaults），数据保存在设备上
- 加密货币图标通过 CoinGecko CDN 加载，需要网络连接
- 推送通知需在真机上测试（模拟器支持有限）
- 请在 Xcode 中设置您的 **Development Team** 以部署到真机

## License

MIT
