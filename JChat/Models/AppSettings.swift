//
//  AppSettings.swift
//  JChat
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultCharacterID: UUID?
    var defaultModelID: String?
    var modelCacheMaxAge: TimeInterval
    var lastModelFetchDate: Date?

    // Stores the user's Cmd+/- text size override as a DynamicTypeSize key.
    // nil = follow the system preference (Settings > Accessibility > Display > Text Size).
    var dynamicTypeSizeOverride: String?

    // Legacy fields kept for SwiftData schema compatibility — no longer read or written.
    var textPointSize: Double = 15.0
    var didApplyTextSizeDefaultMigration: Bool = false

    init() {
        id = UUID()
        modelCacheMaxAge = 86400 // 24 hours
        dynamicTypeSizeOverride = nil
        textPointSize = 15.0
        didApplyTextSizeDefaultMigration = false
    }

    static func fetchOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
