//
//  PopoverView.swift
//  QuickTodo
//

import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: TodoStore
    let onOpenStickyNote: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("待办事项")
                    .font(.headline)
                Spacer()
                Text("\(store.items.filter { !$0.isCompleted }.count) 项未完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // 待办列表
            if store.items.isEmpty {
                Spacer()
                Text("暂无待办事项")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            TodoRowView(item: item) {
                                store.toggle(item)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // 底部按钮
            HStack {
                Button(action: onOpenStickyNote) {
                    Label("编辑", systemImage: "square.and.pencil")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.callout)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 280, height: 360)
        .background(.ultraThinMaterial)
    }
}
