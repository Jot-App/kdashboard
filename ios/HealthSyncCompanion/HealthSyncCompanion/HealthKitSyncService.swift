import Foundation
import HealthKit

final class HealthKitSyncService {
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current
    private var observerQueries: [HKObserverQuery] = []

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitSyncError.healthDataUnavailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: Self.readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitSyncError.authorizationDenied)
                }
            }
        }
    }

    func enableBackgroundDelivery() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitSyncError.healthDataUnavailable
        }

        for quantityType in Self.quantityTypes {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate) { success, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: HealthKitSyncError.backgroundDeliveryUnavailable)
                    }
                }
            }
        }
    }

    func startObserverQueries(onChange: @escaping (@escaping () -> Void) -> Void) {
        guard observerQueries.isEmpty, isHealthDataAvailable else { return }

        for quantityType in Self.quantityTypes {
            let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { _, completionHandler, error in
                guard error == nil else {
                    completionHandler()
                    return
                }

                onChange(completionHandler)
            }

            observerQueries.append(query)
            healthStore.execute(query)
        }
    }

    func fetchDailySummaries(daysBack: Int) async throws -> [HealthDay] {
        guard daysBack > 0 else { return [] }

        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        guard let startDate = calendar.date(byAdding: .day, value: -(daysBack - 1), to: calendar.startOfDay(for: Date())) else {
            return []
        }

        async let steps = dailySums(identifier: .stepCount, unit: .count(), startDate: startDate, endDate: endDate)
        async let energy = dailySums(identifier: .dietaryEnergyConsumed, unit: .kilocalorie(), startDate: startDate, endDate: endDate)
        async let protein = dailySums(identifier: .dietaryProtein, unit: .gram(), startDate: startDate, endDate: endDate)
        async let carbs = dailySums(identifier: .dietaryCarbohydrates, unit: .gram(), startDate: startDate, endDate: endDate)
        async let fat = dailySums(identifier: .dietaryFatTotal, unit: .gram(), startDate: startDate, endDate: endDate)

        let values = try await (steps, energy, protein, carbs, fat)
        let formatter = Self.dateFormatter

        return dateRange(from: startDate, to: endDate).map { dayStart in
            let key = formatter.string(from: dayStart)
            return HealthDay(
                date: key,
                steps: Int((values.0[key] ?? 0).rounded()),
                dietaryEnergyKcal: rounded(values.1[key] ?? 0),
                proteinG: rounded(values.2[key] ?? 0),
                carbsG: rounded(values.3[key] ?? 0),
                fatG: rounded(values.4[key] ?? 0)
            )
        }
    }

    private func dailySums(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> [String: Double] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitSyncError.missingQuantityType
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Double], Error>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var sums: [String: Double] = [:]
                result?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let dateKey = Self.dateFormatter.string(from: statistics.startDate)
                    sums[dateKey] = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                }
                continuation.resume(returning: sums)
            }

            healthStore.execute(query)
        }
    }

    private func dateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var current = startDate
        while current < endDate {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let quantityTypes: [HKQuantityType] = [
        HKQuantityType.quantityType(forIdentifier: .stepCount),
        HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
        HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
        HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
        HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)
    ].compactMap { $0 }

    private static var readTypes: Set<HKObjectType> {
        Set(quantityTypes)
    }
}

enum HealthKitSyncError: LocalizedError {
    case authorizationDenied
    case backgroundDeliveryUnavailable
    case healthDataUnavailable
    case missingQuantityType

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Health permission was not granted."
        case .backgroundDeliveryUnavailable:
            return "Health background delivery could not be enabled."
        case .healthDataUnavailable:
            return "Health data is not available on this device."
        case .missingQuantityType:
            return "A requested HealthKit quantity type is unavailable."
        }
    }
}
