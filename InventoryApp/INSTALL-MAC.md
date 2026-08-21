# 把库存通装到这台 Mac

当前失败原因只有一句：

> Signing for 'InventoryApp' requires a development team.

没有选 Apple 开发团队，Xcode 不会把 App 装到 Mac 或 iPhone。

## 一步步点

1. 左侧点蓝色 **InventoryApp** 工程（最上面那个文件夹图标）
2. 中间 **TARGETS** 选 InventoryApp
3. 顶部分页点 **Signing & Capabilities**
4. 勾选 **Automatically manage signing**
5. **Team** 选你的账号  
   - 没有选项：Team 右边 **Add an Account…** → 登录 Apple ID → 回来选 Personal Team
6. 窗口最上面的设备列表：选 **My Mac**  
   不要选 `My Mac (Designed for iPad)`，没 Team 时这个一定失败
7. 点 ▶ 或按 ⌘R

第一次登录 Apple ID 后，Xcode 会自动创建免费证书，然后才能装到本机。
