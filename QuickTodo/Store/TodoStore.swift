//
//  TodoStore.swift
//  QuickTodo
//

import Foundation
import Combine
import SwiftUI

class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = []

    private let key = "todo_items"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else { return }
        items = decoded.sorted { $0.order < $1.order }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func add(title: String) {
        let nextOrder = (items.map(\.order).max() ?? -1) + 1
        items.append(TodoItem(title: title, order: nextOrder))
        save()
    }

    func delete(at offsets: IndexSet) {
        offsets.sorted().reversed().forEach { items.remove(at: $0) }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        let moved = source.sorted().map { items[$0] }
        var result = items.enumerated().filter { !source.contains($0.offset) }.map(\.element)
        let insertAt = min(destination - source.filter { $0 < destination }.count, result.count)
        result.insert(contentsOf: moved, at: insertAt)
        for i in result.indices { result[i].order = i }
        items = result
        save()
    }

    func toggle(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isCompleted.toggle()
        save()
    }

    func update(_ item: TodoItem, title: String) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].title = title
        save()
    }
}
