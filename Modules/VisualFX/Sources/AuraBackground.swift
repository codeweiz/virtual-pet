import SwiftUI

/// GPU shader backdrop driven by `TimelineView(.animation)`. Loads the
/// `petAura` Metal function from the MAIN app bundle via `ShaderLibrary.default`
/// — the host app must include `PetAura.metal`.
///
/// iPhone / iPad / Mac only: watchOS has no Metal, so this module isn't linked
/// into the watch target (the watch uses Canvas/SF-Symbol fallbacks instead).
public struct AuraBackground: View {
    public init() {}

    public var body: some View {
        TimelineView(.animation) { ctx in
            // Keep the time value bounded so float precision stays stable.
            let t = Float(
                ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6000))
            GeometryReader { geo in
                Rectangle()
                    .colorEffect(
                        ShaderLibrary.default.petAura(
                            .float(t),
                            .float2(geo.size)
                        )
                    )
            }
        }
        .ignoresSafeArea()
    }
}
