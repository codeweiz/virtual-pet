import Foundation
import PetKit

/// The persistence seam. Features depend on THIS, never on SwiftData/CloudKit
/// directly, so the storage engine stays swappable (SwiftData → SQLiteData …).
public protocol PetRepository: Sendable {
    func load() async throws -> PetSnapshot?
    func save(_ snapshot: PetSnapshot) async throws
}

/// Volatile store for previews, tests, and first-run before a real engine is
/// wired. Thread-safe via actor isolation.
public actor InMemoryPetRepository: PetRepository {
    private var snapshot: PetSnapshot?

    public init(_ initial: PetSnapshot? = nil) {
        self.snapshot = initial
    }

    public func load() async throws -> PetSnapshot? { snapshot }

    public func save(_ snapshot: PetSnapshot) async throws {
        self.snapshot = snapshot
    }
}
