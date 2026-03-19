//
//  StickyNoteView.swift
//  QuickTodo
//

import SwiftUI

struct StickyNoteView: View {
    @ObservedObject var store: TodoStore
    @State private var newTitle: String = ""
    @State private var editingId: UUID? = nil
    @State private var editingText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题（拖动区域由 NSPanel 标题栏承担）
            HStack {
                Text("QuickTodo")
                    .font(.headline)
                    .foregroundColor(.primary.opacity(0.7))
                Spacer()
                Text("\(store.items.filter { !$0.isCompleted }.count) 未完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Divider()

            // 待办列表
            List {
                ForEach(store.items) { item in
                    stickyRow(item)
                }
                .onDelete { store.delete(at: $0) }
                .onMove { store.move(from: $0, to: $1) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            Divider()

            // 新增输入框
            HStack(spacing: 8) {
                TextField("添加待办...", text: $newTitle)
                    .textFieldStyle(.plain)
                    .onSubmit { addItem() }
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(newTitle.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newTitle.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(NSColor(red: 1.0, green: 0.97, blue: 0.75, alpha: 1.0)))
        .frame(minWidth: 240, minHeight: 300)
    }

    @ViewBuilder
    private func stickyRow(_ item: TodoItem) -> some View {
        HStack(spacing: 8) {
            Button(action: { store.toggle(item) }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if editingId == item.id {
                TextField("", text: $editingText)
                    .textFieldStyle(.plain)
                    .onSubmit { commitEdit(item) }
                    .onExitCommand { editingId = nil }
            } else {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture(count: 2) {
                        editingId = item.id
                        editingText = item.title
                    }
            }
        }
        .padding(.vertical, 2)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func addItem() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.add(title: trimmed)
        newTitle = ""
    }

    private func commitEdit(_ item: TodoItem) {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            store.update(item, title: trimmed)
        }
        editingId = nil
    }
}
