//
//  TodoRowView.swift
//  QuickTodo
//

import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .secondary)
                    .font(.system(size: 16))
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }
}
