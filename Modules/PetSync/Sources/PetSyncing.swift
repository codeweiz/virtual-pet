import Foundation
import PetKit

/// Cross-device sync seam. The DESIGN (see docs): CloudKit is the source of
/// truth across iPhone/iPad/Mac; WatchConnectivity is an opportunistic
/// real-time channel when phone + watch are reachable. The watch is a thin
/// client and never relies on CloudKit for freshness (watchOS CloudKit sync is
/// unreliable — see research notes).
public protocol PetSyncing: Sendable {
    /// Push the latest snapshot to peers / the cloud.
    func push(_ snapshot: PetSnapshot) async

    /// A stream of snapshots arriving from other devices.
    var inbound: AsyncStream<PetSnapshot> { get }
}

/// No-op implementation so the app runs before CloudKit / App Groups are
/// provisioned. Swap for `CloudKitPetSync` + `WatchConnectivityPetSync` once
/// entitlements exist.
public struct NoopPetSync: PetSyncing {
    public init() {}
    public func push(_ snapshot: PetSnapshot) async {}
    public var inbound: AsyncStream<PetSnapshot> {
        AsyncStream { $0.finish() }
    }
}

#if canImport(WatchConnectivity)
    import WatchConnectivity
// EXTENSION POINT: a `WatchConnectivityPetSync` wraps a `WCSession`, encodes the
// snapshot into `updateApplicationContext` for background delivery and
// `sendMessage` for instant nudges when `isReachable`. Not on macOS.
#endif
