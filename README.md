# QuickTodo

一款轻量的 macOS 菜单栏待办事项应用，基于 SwiftUI + AppKit 开发。常驻菜单栏，无 Dock 图标，零打扰。

A lightweight macOS menu bar to-do app built with SwiftUI + AppKit. Lives quietly in your menu bar — no Dock icon, no clutter.

---

## 功能特性 / Features

- **菜单栏常驻** — 点击状态栏图标即可查看待办，随开随用
- **完整增删改查** — 新增、编辑、删除、拖拽排序一应俱全
- **内联编辑** — 点击文本直接编辑，按 Return 连续创建下一条
- **撤回删除** — `Cmd+Z` 还原最近一次删除操作
- **窗口置顶** — Pin 按钮让编辑窗口始终浮于所有应用之上
- **自动持久化** — 所有改动即时写入 UserDefaults，无需手动保存
- **极简界面** — 毛玻璃背景，macOS 提醒事项风格列表

---

## 系统要求 / Requirements

| 项目 | 版本 |
|------|------|
| macOS | 26.2+ |
| Xcode | 26.3+ |
| Swift | 6.0 |

---

## 安装 / Installation

### 从源码构建

1. 克隆仓库：
   ```bash
   git clone https://github.com/your-username/QuickTodo.git
   cd QuickTodo
   ```
2. 用 Xcode 打开 `QuickTodo.xcodeproj`
3. 选择目标设备为 **My Mac**
4. 按 `Cmd+R` 构建并运行

应用启动后将出现在菜单栏，不会在 Dock 中显示（`LSUIElement = YES`）。

---

## 使用说明 / Usage

| 操作 | 方式 |
|------|------|
| 查看待办 | 点击菜单栏图标 |
| 打开编辑窗口 | 点击 Popover 中的「编辑」按钮 |
| 新增事项 | 点击工具栏 **+** 按钮 |
| 编辑事项 | 单击任意待办文本 |
| 确认并新建下一条 | 编辑状态下按 `Return` |
| 取消编辑 | 按 `Esc` |
| 拖拽排序 | 拖动行上下移动 |
| 删除单条 | 进入删除模式（垃圾桶图标）→ 点击 **−** |
| 删除全部 | 进入删除模式 → 点击「全部删除」 |
| 撤回删除 | `Cmd+Z` |
| 窗口置顶 | 点击工具栏图钉图标 |
| 退出应用 | 点击 Popover 中的「退出」按钮 |

---

## 架构 / Architecture

```
QuickTodoApp (@main)
└── AppDelegate
        ├── NSStatusItem              ← 菜单栏图标
        ├── NSPopover                 ← 快速查看面板 (280×360)
        │       └── PopoverView
        └── NSPanel                   ← 主编辑窗口（可调整大小）
                └── StickyNoteView
                        └── TodoStore（共享单例，ObservableObject）
                                └── [TodoItem] → UserDefaults
```

**数据流：** `TodoStore` 是唯一数据源。`AppDelegate` 持有同一个 Store 实例并注入到 `PopoverView` 和 `StickyNoteView`，任意视图的修改都会即时持久化。

---

## 项目结构 / Project Structure

```
QuickTodo/
├── QuickTodoApp.swift       # @main 入口，通过 NSApplicationDelegateAdaptor 桥接 AppDelegate
├── AppDelegate.swift        # 核心控制器：状态栏图标、Popover、NSPanel
├── ContentView.swift        # 空文件（Xcode 模板占位）
├── Models/
│   └── TodoItem.swift       # 数据模型：id、title、isCompleted、order
├── Store/
│   └── TodoStore.swift      # ObservableObject，CRUD 操作 + 撤回栈
└── Views/
    ├── PopoverView.swift     # 菜单栏 Popover（快速查看 + 状态切换）
    ├── StickyNoteView.swift  # 主编辑窗口（完整 CRUD、拖拽排序、置顶）
    └── TodoRowView.swift     # Popover 中单行待办组件
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
