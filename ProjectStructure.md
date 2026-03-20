# QuickTodo 项目结构文档

## 项目概述

QuickTodo 是一个 macOS 菜单栏待办事项应用，使用 **SwiftUI + AppKit** 混合架构开发。
用户通过点击菜单栏图标打开 Popover 查看待办，通过「编辑」按钮打开主编辑窗口进行增删改操作。

- **开发环境**：Xcode 26.3，Swift 6.0
- **最低系统要求**：macOS 26.2
- **Bundle ID**：`com.Vick.QuickTodo`
- **特性**：无 Dock 图标（`LSUIElement = YES`），纯菜单栏驻留

---

## 架构总览

```
QuickTodoApp（@main 入口）
    └── AppDelegate（核心控制器）
            ├── NSStatusItem（菜单栏图标）
            ├── NSPopover → PopoverView（快速查看）
            └── NSPanel → StickyNoteView（主编辑窗口）
                    └── TodoStore（共享数据层）
                            └── [TodoItem]（数据模型）
```

数据流向：`TodoStore` 是唯一数据源，通过 `@ObservedObject` 注入到所有 View，View 的操作通过 Store 方法回写并持久化到 `UserDefaults`。

---

## 文件详解

### 入口与生命周期

---

#### `QuickTodoApp.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/QuickTodoApp.swift` |
| **类型** | SwiftUI App 入口结构体 |
| **协议** | `App` |

**作用**

应用的 `@main` 入口点。SwiftUI 要求每个 App 必须有一个符合 `App` 协议的结构体作为启动入口。

**创建原因**

- 使用 `@NSApplicationDelegateAdaptor` 将 `AppDelegate` 桥接进 SwiftUI 生命周期
- `body` 中声明一个空的 `Settings` Scene，目的是抑制 SwiftUI 自动创建默认窗口（该 app 不需要标准窗口，所有 UI 由 AppDelegate 手动管理）

**关键代码**

```swift
@main
struct QuickTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }  // 阻止 SwiftUI 创建默认窗口
    }
}
```

---

#### `AppDelegate.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/AppDelegate.swift` |
| **类型** | NSObject 子类，实现 NSApplicationDelegate + NSWindowDelegate |
| **层级** | 应用核心控制器 |

**作用**

整个应用的"大脑"，负责：
1. 创建并管理菜单栏图标（`NSStatusItem`）
2. 创建并控制 Popover（快速查看面板）
3. 创建并控制主编辑窗口（`NSPanel`）
4. 维护"置顶"状态并同步到 Panel
5. 持久化窗口位置到 `UserDefaults`

**创建原因**

SwiftUI 的 `WindowGroup` 无法满足"菜单栏图标 + 无 Dock 图标 + 自定义浮动面板"的需求，必须借助 `AppKit` 的 `NSStatusItem` 和 `NSPanel` 直接操控系统 UI。

**核心交互逻辑**

```
菜单栏图标点击
    └── togglePopover()
            ├── 显示/关闭 Popover
            └── Popover 内「编辑」按钮
                    └── openStickyNote()  ← 唯一打开主页面的入口
                            └── 创建 NSPanel / makeKeyAndOrderFront
```

**重要配置**

| 配置项 | 值 | 原因 |
|--------|-----|------|
| `hidesOnDeactivate` | `false` | 防止切换 app 时主窗口自动隐藏 |
| `styleMask` | `.fullSizeContentView` | 内容延伸到标题栏，实现沉浸式布局 |
| `titlebarAppearsTransparent` | `true` | 隐藏标题栏背景，与内容融合 |
| `collectionBehavior` | `.managed + .participatesInCycle` | 出现在 Mission Control，支持 Cmd+Tab |
| `windowDidBecomeKey` | 调用 `NSApp.activate()` | LSUIElement app 从 Mission Control 激活时获得焦点 |

---

#### `ContentView.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/ContentView.swift` |
| **类型** | 空文件（占位） |

**作用**

Xcode 新建项目时自动生成的模板文件，内容已清空。

**创建原因**

保留此文件是为了维持项目结构的完整性（Xcode 项目模板默认包含），实际逻辑已全部转移到 `AppDelegate` + 自定义 Views。

---

### 数据层

---

#### `Models/TodoItem.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/Models/TodoItem.swift` |
| **类型** | Swift 值类型结构体 |
| **协议** | `Identifiable`、`Codable` |

**作用**

定义单条待办事项的数据结构，是整个 app 的核心数据模型。

**创建原因**

将数据模型独立为单独文件，与 UI 层解耦，符合 MVC/MVVM 分层原则。`Codable` 协议支持 JSON 序列化以便持久化到 `UserDefaults`，`Identifiable` 支持 SwiftUI `ForEach` 渲染。

**字段说明**

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | `UUID` | 自动生成 | 唯一标识，用于 ForEach 和状态跟踪 |
| `title` | `String` | — | 待办事项文本内容 |
| `isCompleted` | `Bool` | `false` | 完成状态 |
| `order` | `Int` | — | 排序权重，支持拖拽重排 |

---

#### `Store/TodoStore.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/Store/TodoStore.swift` |
| **类型** | ObservableObject 类 |
| **持久化** | `UserDefaults`，key：`"todo_items"` |

**作用**

应用的唯一数据状态中心（Single Source of Truth），负责：
- 持有所有待办事项列表 `@Published var items`
- 提供增删改查、排序的操作方法
- 将变更持久化到 `UserDefaults`
- 维护删除撤回栈（Undo Stack）

**创建原因**

PopoverView 和 StickyNoteView 需要共享同一份数据，且任一视图的修改需要实时反映到另一视图。`ObservableObject` + `@Published` 实现响应式数据绑定，单一 Store 实例由 `AppDelegate` 持有并注入到两个 View。

**方法一览**

| 方法 | 说明 |
|------|------|
| `load()` | 从 UserDefaults 读取并按 order 排序 |
| `save()` | 将当前 items 编码为 JSON 写入 UserDefaults |
| `add(title:)` | 追加新事项，order 自动递增 |
| `delete(at:)` | 删除指定位置，**同时将被删事项压入撤回栈** |
| `deleteAll()` | 清空全部，**将全部事项作为一批压入撤回栈** |
| `undoLastDelete()` | 弹出撤回栈最后一批，合并回列表并按 order 排序还原 |
| `move(from:to:)` | 拖拽重排，重新计算全部 order 值 |
| `toggle(_:)` | 切换完成状态 |
| `update(_:title:)` | 修改事项文本 |

**撤回机制**

```
删除操作 → undoStack.append(batch)
Cmd+Z   → undoStack.popLast() → 还原到 items
```

---

### 视图层

---

#### `Views/PopoverView.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/Views/PopoverView.swift` |
| **类型** | SwiftUI View |
| **尺寸** | 280 × 360 pt（由 NSPopover 固定） |

**作用**

菜单栏图标点击后弹出的快速预览面板，提供：
- 待办列表的只读预览（可切换完成状态）
- 未完成事项计数
- 「编辑」按钮入口（打开主编辑窗口）
- 「退出」按钮

**创建原因**

用户日常使用中查看待办的频率远高于编辑，轻量 Popover 提供快速浏览而无需打开完整窗口，符合菜单栏 app 的交互范式。

**数据流**

```
AppDelegate 创建时注入 store 和 onOpenStickyNote 回调
PopoverView（只读浏览 + toggle）
    └── onOpenStickyNote() → AppDelegate.openStickyNote()
```

---

#### `Views/StickyNoteView.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/Views/StickyNoteView.swift` |
| **类型** | SwiftUI View |
| **最小尺寸** | 260 × 320 pt（可拖拽调整） |

**作用**

主编辑窗口的完整 UI，提供全部 CRUD 功能：
- 待办列表展示（macOS 提醒事项风格）
- 新增：点击 `+` → 自动插入空白行 + 自动聚焦
- 编辑：双击文本 → 进入内联编辑
- 删除：进入删除模式 → 点击 `−` 号逐条删除 / 全部删除
- 拖拽排序
- 置顶（Pin）开关
- Cmd+Z 撤回删除

**创建原因**

PopoverView 空间有限且生命周期短暂，复杂编辑操作需要在独立的持久窗口中进行，`NSPanel` 提供了浮动、可拖拽、跨 Space 等能力。

**关键状态**

| 状态 | 类型 | 说明 |
|------|------|------|
| `editingId` | `UUID?` | 当前正在内联编辑的事项 ID |
| `editingText` | `String` | 编辑中的临时文本 |
| `isDeleteMode` | `Bool` | 是否处于删除模式 |
| `focusedItemId` | `UUID?`（FocusState） | 控制 TextField 焦点，实现自动聚焦和失焦自动保存 |

**工具栏布局**

```
普通模式：[←红绿灯占位→] [Spacer] [ pin | trash | + ]（胶囊容器）
删除模式：[←红绿灯占位→] [Spacer] [ 全部删除 | 完成 ]（胶囊容器）
```

工具栏通过 `.safeAreaInset(edge: .top)` 固定，避免 List 渲染时挤占工具栏空间。

---

#### `Views/TodoRowView.swift`

| 属性 | 说明 |
|------|------|
| **位置** | `QuickTodo/Views/TodoRowView.swift` |
| **类型** | SwiftUI View（轻量组件） |

**作用**

PopoverView 中每一行待办事项的渲染组件，显示：
- 完成状态图标（圆圈 / 勾选）
- 事项标题（完成时显示删除线）
- 点击整行触发状态切换

**创建原因**

将行级 UI 抽离为独立组件，PopoverView 的列表代码更简洁，且此组件逻辑单一（只负责展示和 toggle），便于单独维护。

> **注意**：StickyNoteView 的列表行逻辑更复杂（支持编辑、删除模式），因此没有复用此组件，而是使用了内联的 `reminderRow()` 方法。

---

## 数据持久化

| Key | 类型 | 内容 |
|-----|------|------|
| `"todo_items"` | `Data`（JSON） | `[TodoItem]` 数组 |
| `"panel_frame"` | `String`（NSRect 字符串） | 主窗口位置和尺寸 |

---

## 文件目录树

```
QuickTodo/
├── QuickTodoApp.swift          # @main 入口，桥接 AppDelegate
├── AppDelegate.swift           # 核心控制器，管理菜单栏、Popover、Panel
├── ContentView.swift           # 空文件（模板占位）
├── Models/
│   └── TodoItem.swift          # 数据模型
├── Store/
│   └── TodoStore.swift         # 数据层，ObservableObject，含 Undo 机制
└── Views/
    ├── PopoverView.swift        # 菜单栏 Popover（快速查看）
    ├── StickyNoteView.swift     # 主编辑窗口（完整 CRUD）
    └── TodoRowView.swift        # Popover 中单行待办组件
```
