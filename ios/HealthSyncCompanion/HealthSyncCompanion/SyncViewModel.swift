import Foundation

@MainActor
final class SyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var status = "Ready"
    @Published var latestFetchedSummary = "No HealthKit fetch yet"
    @Published var lastSuccessfulSync: Date?

    private let healthService = HealthKitSyncService()
    private let client = HealthSyncClient()
    private let lastSyncKey = "lastSuccessfulHealthSync"

    init() {
        lastSuccessfulSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    func requestPermissions() {
        Task {
            do {
                try await healthService.requestAuthorization()
                try await healthService.enableBackgroundDelivery()
                status = "Health permission ready"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    func syncNow() {
        Task {
            await sync(daysBack: lastSuccessfulSync == nil ? 30 : 7)
        }
    }

    func sync(daysBack: Int) async {
        guard !isSyncing else { return }

        isSyncing = true
        status = "Syncing..."
        defer { isSyncing = false }

        do {
            try await healthService.requestAuthorization()
            try await healthService.enableBackgroundDelivery()
            let days = try await healthService.fetchDailySummaries(daysBack: daysBack)
            latestFetchedSummary = Self.summary(for: days)
            let rows = try await client.upload(days: days, timezone: TimeZone.current.identifier)
            let now = Date()
            UserDefaults.standard.set(now, forKey: lastSyncKey)
            lastSuccessfulSync = now
            status = Self.status(rows: rows, days: days)
        } catch {
            status = error.localizedDescription
        }
    }

    private static func status(rows: Int, days: [HealthDay]) -> String {
        if rows > 0, days.contains(where: { $0.hasNutrition }) == false {
            return "Synced steps only. No nutrition samples found in Health."
        }

        return "Synced \(rows) day\(rows == 1 ? "" : "s")"
    }

    private static func summary(for days: [HealthDay]) -> String {
        guard let latest = days.last else {
            return "No HealthKit days found"
        }

        return "\(latest.date): \(latest.steps) steps, \(Int(latest.dietaryEnergyKcal.rounded())) kcal, \(Int(latest.proteinG.rounded()))g protein"
    }
}

enum BackgroundHealthSyncRunner {
    private static let minimumForegroundSyncInterval: TimeInterval = 5 * 60

    static func sync(daysBack: Int) async throws {
        let healthService = HealthKitSyncService()
        try await healthService.requestAuthorization()
        try await healthService.enableBackgroundDelivery()
        let days = try await healthService.fetchDailySummaries(daysBack: daysBack)
        let rows = try await HealthSyncClient().upload(days: days, timezone: TimeZone.current.identifier)
        UserDefaults.standard.set(Date(), forKey: "lastSuccessfulHealthSync")
        UserDefaults.standard.set(rows, forKey: "lastBackgroundHealthSyncRowCount")
    }

    static func syncIfStale(daysBack: Int) async throws {
        let lastSync = UserDefaults.standard.object(forKey: "lastSuccessfulHealthSync") as? Date
        if let lastSync, Date().timeIntervalSince(lastSync) < minimumForegroundSyncInterval {
            return
        }

        try await sync(daysBack: daysBack)
    }
}
