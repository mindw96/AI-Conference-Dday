import Foundation

public struct ConferenceDataUpdater: @unchecked Sendable {
    public static let maxRemoteDataSize = 5 * 1024 * 1024

    public static let defaultRemoteURL = URL(
        string: "https://raw.githubusercontent.com/mindw96/AI-Conference-Dday/main/data/conferences.json"
    )!

    public let remoteURL: URL

    private let cacheURL: URL
    private let fileManager: FileManager

    public init(
        remoteURL: URL = Self.defaultRemoteURL,
        cacheURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.remoteURL = remoteURL
        self.fileManager = fileManager
        self.cacheURL = cacheURL ?? Self.defaultCacheURL(fileManager: fileManager)
    }

    public func loadPreferred(bundledURL: URL) throws -> ConferenceStore {
        if fileManager.fileExists(atPath: cacheURL.path) {
            do {
                return try ConferenceStore.load(from: cacheURL)
            } catch {
                try? fileManager.removeItem(at: cacheURL)
            }
        }

        return try ConferenceStore.load(from: bundledURL)
    }

    public func fetchAndCacheLatest() async throws -> ConferenceStore {
        var request = URLRequest(url: remoteURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if !(200..<300).contains(httpResponse.statusCode) {
                throw ConferenceDataUpdateError.badStatusCode(httpResponse.statusCode)
            }

            if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let size = Int(contentLength),
               size > Self.maxRemoteDataSize {
                throw ConferenceDataUpdateError.responseTooLarge(size)
            }
        }

        if data.count > Self.maxRemoteDataSize {
            throw ConferenceDataUpdateError.responseTooLarge(data.count)
        }

        let store = try ConferenceStore.load(from: data)
        try fileManager.createDirectory(
            at: cacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: cacheURL, options: .atomic)
        return store
    }

    public func cachedDataModifiedAt() -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: cacheURL.path) else {
            return nil
        }

        return attributes[.modificationDate] as? Date
    }

    private static func defaultCacheURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return baseURL
            .appendingPathComponent("Dday", isDirectory: true)
            .appendingPathComponent("conferences.json")
    }
}

public enum ConferenceDataUpdateError: LocalizedError, Equatable {
    case badStatusCode(Int)
    case responseTooLarge(Int)

    public var errorDescription: String? {
        switch self {
        case .badStatusCode(let statusCode):
            return "Conference data request failed with HTTP \(statusCode)."
        case .responseTooLarge(let size):
            return "Conference data response is too large (\(size) bytes)."
        }
    }
}
