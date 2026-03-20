//
//  StickyNoteView.swift
//  QuickTodo
//

import SwiftUI

struct StickyNoteView: View {
    @ObservedObject var store: TodoStore
    var onToggleAlwaysOnTop: (() -> Void)?
    var isAlwaysOnTop: Bool = false

    @State private var editingId: UUID? = nil
    @State private var editingText: String = ""
    @State private var isDeleteMode: Bool = false
    @State private var showDeleteAllConfirm: Bool = false
    @State private var selectedId: UUID? = nil
    @FocusState private var focusedItemId: UUID?
    @State private var hoveredBtn: String? = nil
    @State private var isCreatingNext: Bool = false

    var body: some View {
        List(selection: $selectedId) {
            ForEach(store.items) { item in
                reminderRow(item)
                    .tag(item.id)
            }
            .onMove { store.move(from: $0, to: $1) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .overlay {
            if store.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("暂无待办事项")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                toolbar.frame(height: 28)
                Divider()
            }
            .background(.ultraThinMaterial)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea()
        .frame(minWidth: 260, minHeight: 320)
        .background(.ultraThinMaterial)
        .confirmationDialog(
            "确定删除所有待办事项吗？",
            isPresented: $showDeleteAllConfirm,
            titleVisibility: .visible
        ) {
            Button("全部删除", role: .destructive) {
                store.deleteAll()
                isDeleteMode = false
            }
            Button("取消", role: .cancel) {}
        }
        .onChange(of: focusedItemId) { _, newValue in
            guard !isCreatingNext else { return }
            guard let prevId = editingId, newValue != prevId else { return }
            if let item = store.items.first(where: { $0.id == prevId }) {
                commitEdit(item)
            }
        }
        // Cmd+Z 撤回删除（window 级别，无需焦点）
        .background {
            Button("") { store.undoLastDelete() }
                .keyboardShortcut("z", modifiers: .command)
                .hidden()
        }
    }

    // MARK: - 工具栏

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: 0) {
            // 左侧留出红绿灯空间
            Spacer().frame(width: 72)
            Spacer()

            if isDeleteMode {
                // 删除模式：「全部删除 | 完成」胶囊组
                HStack(spacing: 0) {
                    textPillBtn("deleteAll", title: "全部删除", color: .red) {
                        showDeleteAllConfirm = true
                    }
                    pillDivider
                    textPillBtn("done", title: "完成", color: .accentColor) {
                        isDeleteMode = false
                    }
                }
            } else {
                // 普通模式：「pin | trash | +」图标胶囊组
                HStack(spacing: 0) {
                    iconPillBtn("pin",
                                icon: isAlwaysOnTop ? "pin.fill" : "pin",
                                color: isAlwaysOnTop ? .accentColor : .secondary) {
                        onToggleAlwaysOnTop?()
                    }
                    .help(isAlwaysOnTop ? "取消始终显示在前方" : "始终显示在前方")

                    pillDivider

                    iconPillBtn("trash", icon: "trash") {
                        isDeleteMode = true
                        editingId = nil
                    }
                    .help("删除待办事项")

                    pillDivider

                    iconPillBtn("plus", icon: "plus") {
                        addBlankAndEdit()
                    }
                    .help("新建待办事项")
                }
            }
        }
        .padding(.horizontal, 10)
    }

    // 图标按钮（带 hover 高亮）
    @ViewBuilder
    private func iconPillBtn(_ id: String, icon: String,
                              color: Color = .secondary,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundColor(hoveredBtn == id ? .primary : color)
                .frame(width: 28, height: 22)
                .background(
                    hoveredBtn == id
                        ? Color.primary.opacity(0.1)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
        .onHover { on in
            if on { hoveredBtn = id } else if hoveredBtn == id { hoveredBtn = nil }
        }
    }

    // 文字按钮（带 hover 高亮）
    @ViewBuilder
    private func textPillBtn(_ id: String, title: String,
                              color: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(hoveredBtn == id ? color.opacity(0.75) : color)
                .padding(.horizontal, 10)
                .frame(height: 22)
                .background(
                    hoveredBtn == id
                        ? Color.primary.opacity(0.07)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
        .onHover { on in
            if on { hoveredBtn = id } else if hoveredBtn == id { hoveredBtn = nil }
        }
    }

    // 胶囊内分隔线
    private var pillDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 0.5)
            .padding(.vertical, 5)
    }

    // MARK: - 列表行

    @ViewBuilder
    private func reminderRow(_ item: TodoItem) -> some View {
        HStack(spacing: 10) {
            if isDeleteMode {
                Button(action: {
                    if let idx = store.items.firstIndex(where: { $0.id == item.id }) {
                        store.delete(at: IndexSet(integer: idx))
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { store.toggle(item) }) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(item.isCompleted ? .accentColor : Color(NSColor.tertiaryLabelColor))
                }
                .buttonStyle(.plain)
            }

            if editingId == item.id {
                TextField("", text: $editingText)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)
                    .focused($focusedItemId, equals: item.id)
                    .onSubmit { commitAndCreateNext(item) }
                    .onExitCommand { discardIfBlank(item) }
            } else {
                Text(item.title)
                    .strikethrough(item.isCompleted && !isDeleteMode, color: .secondary)
                    .foregroundColor(item.isCompleted && !isDeleteMode ? .secondary : .primary)
                    .onTapGesture {
                        guard !isDeleteMode else { return }
                        startEditing(item)
                    }
            }
        }
        .padding(.vertical, 3)
        .listRowSeparator(.visible)
        .listRowInsets(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14))
    }

    // MARK: - 操作

    /// 开始编辑某条事项，会先提交当前正在编辑的内容
    private func startEditing(_ item: TodoItem) {
        if let prevId = editingId, prevId != item.id,
           let prevItem = store.items.first(where: { $0.id == prevId }) {
            commitEdit(prevItem)
        }
        editingId = item.id
        editingText = item.title
        DispatchQueue.main.async { focusedItemId = item.id }
    }

    /// 新建空白事项（插在已完成事项之前），并立即进入编辑
    private func addBlankAndEdit() {
        if let prevId = editingId, let prevItem = store.items.first(where: { $0.id == prevId }) {
            commitEdit(prevItem)
        }
        let insertIdx = store.items.firstIndex(where: { $0.isCompleted }) ?? store.items.count
        let blank = TodoItem(title: "", order: 0)
        store.items.insert(blank, at: insertIdx)
        for i in store.items.indices { store.items[i].order = i }
        selectedId = blank.id
        editingId = blank.id
        editingText = ""
        DispatchQueue.main.async { focusedItemId = blank.id }
    }

    /// 回车：提交当前事项，并在其下方创建新事项进入编辑
    private func commitAndCreateNext(_ item: TodoItem) {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            store.items.removeAll { $0.id == item.id }
            store.save()
            editingId = nil
            return
        }
        store.update(item, title: trimmed)
        isCreatingNext = true

        if let blank = store.insertBlank(after: item) {
            selectedId = blank.id
            editingId = blank.id
            editingText = ""
            DispatchQueue.main.async {
                self.focusedItemId = blank.id
                self.isCreatingNext = false
            }
        } else {
            editingId = nil
            isCreatingNext = false
        }
    }

    private func commitEdit(_ item: TodoItem) {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            store.items.removeAll { $0.id == item.id }
        } else {
            store.update(item, title: trimmed)
        }
        store.save()
        editingId = nil
    }

    private func discardIfBlank(_ item: TodoItem) {
        if item.title.isEmpty {
            store.items.removeAll { $0.id == item.id }
            store.save()
        }
        editingId = nil
    }
}
