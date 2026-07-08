import Foundation

actor HealthSyncClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func upload(days: [HealthDay], timezone: String) async throws -> Int {
        guard !days.isEmpty else { return 0 }

        let payload = HealthSyncPayload(
            source: AppConfig.source,
            timezone: timezone,
            days: days
        )

        var request = URLRequest(url: try AppConfig.healthSyncURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(try AppConfig.healthSyncToken, forHTTPHeaderField: "x-health-sync-token")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthSyncClientError.invalidResponse
        }

        let decoded = try? JSONDecoder().decode(HealthSyncResponse.self, from: data)
        guard (200..<300).contains(httpResponse.statusCode), decoded?.ok == true else {
            throw HealthSyncClientError.server(decoded?.error ?? "Sync failed with HTTP \(httpResponse.statusCode).")
        }

        return decoded?.rows ?? days.count
    }
}

enum HealthSyncClientError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The sync endpoint returned an invalid response."
        case .server(let message):
            return message
        }
    }
}
