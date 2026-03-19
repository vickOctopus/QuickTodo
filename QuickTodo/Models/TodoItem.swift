//
//  TodoItem.swift
//  QuickTodo
//

import Foundation

struct TodoItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var order: Int
}
