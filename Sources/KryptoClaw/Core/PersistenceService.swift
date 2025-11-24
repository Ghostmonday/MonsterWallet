import Foundation

public protocol PersistenceServiceProtocol {
    func save(_ object: some Encodable, to filename: String) throws
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T
    func delete(filename: String) throws
}

public class PersistenceService: PersistenceServiceProtocol {
    public static let shared = PersistenceService()

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    private func getDocumentsDirectory() throws -> URL {
        try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    private func getFileURL(for filename: String) throws -> URL {
        let folder = try getDocumentsDirectory()
        return folder.appendingPathComponent(filename)
    }

    public func save(_ object: some Encodable, to filename: String) throws {
        let url = try getFileURL(for: filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url)
    }

    public func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let url = try getFileURL(for: filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    public func delete(filename: String) throws {
        let url = try getFileURL(for: filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    public static let contactsFile = "contacts.json"
    public static let walletsFile = "wallets.json"
}
