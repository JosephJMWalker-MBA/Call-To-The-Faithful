import Foundation
import SwiftUI

/// Wraps AppStorage-backed persistence for a `ParishSchedule` using JSON encoding.
struct ParishScheduleStorage: DynamicProperty {
    @AppStorage("parishScheduleData") private var storedData: Data = Data()

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    /// Loads a persisted schedule if one exists.
    func load() -> ParishSchedule? {
        guard !storedData.isEmpty else { return nil }
        return try? decoder.decode(ParishSchedule.self, from: storedData)
    }

    /// Persists the provided schedule using JSON.
    func save(_ schedule: ParishSchedule) {
        guard let encoded = try? encoder.encode(schedule) else { return }
        storedData = encoded
    }

    /// Removes any persisted schedule from storage.
    func clear() {
        storedData = Data()
    }

    mutating func update() {}
}

/// Observable store that keeps the in-memory schedule synchronized with AppStorage.
@MainActor
final class ParishScheduleStore: ObservableObject {
    @Published var schedule: ParishSchedule {
        didSet { storage.save(schedule) }
    }

    private var storage: ParishScheduleStorage

    init(defaultSchedule: ParishSchedule = .empty, storage: ParishScheduleStorage = ParishScheduleStorage()) {
        var workingStorage = storage
        if let persisted = workingStorage.load() {
            schedule = persisted
        } else {
            schedule = defaultSchedule
            workingStorage.save(defaultSchedule)
        }
        self.storage = workingStorage
    }

    /// Replace the stored schedule with a new value and persist it immediately.
    func reset(to schedule: ParishSchedule) {
        self.schedule = schedule
    }

    /// Clears the persisted schedule and resets the in-memory copy to an empty value.
    func clear() {
        storage.clear()
        schedule = .empty
    }
}
