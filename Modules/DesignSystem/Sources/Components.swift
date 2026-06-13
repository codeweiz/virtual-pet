import SwiftUI

/// A labelled capsule meter for a single 0...1 need.
public struct StatBar: View {
    private let value: Double
    private let tint: Color
    private let systemImage: String

    public init(value: Double, tint: Color, systemImage: String) {
        self.value = value
        self.tint = tint
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 18)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(6, geo.size.width * value))
                }
            }
            .frame(height: 8)
        }
    }
}

/// Animated mesh-gradient backdrop. Caller passes mood-derived colors; the mesh
/// gently drifts via `TimelineView(.animation)`. Available on all platforms
/// (MeshGradient is fine on watchOS 11+).
public struct AuroraGradient: View {
    private let colors: [Color]
    public init(colors: [Color]) { self.colors = colors }

    public var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let wobble = Float(sin(t * 0.4)) * 0.06
            let points: [SIMD2<Float>] = [
                SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
                SIMD2(0, 0.5), SIMD2(0.5 + wobble, 0.5 - wobble), SIMD2(1, 0.5),
                SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1),
            ]
            MeshGradient(width: 3, height: 3, points: points, colors: meshColors)
        }
        .ignoresSafeArea()
    }

    private var meshColors: [Color] {
        let base = colors.isEmpty ? [PetPalette.periwinkle, PetPalette.blush] : colors
        return (0..<9).map { base[$0 % base.count] }
    }
}
