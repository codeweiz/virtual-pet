import SwiftUI

extension View {
    /// Apply Liquid Glass to the FUNCTIONAL layer (HUD / controls / panels) with
    /// a graceful material fallback where it isn't available (watchOS, older OS).
    /// Per Apple HIG: never put glass over the pet/content itself.
    @ViewBuilder
    public func petGlass(cornerRadius: CGFloat = PetMetrics.corner) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        #if os(watchOS)
            self.background(.ultraThinMaterial, in: shape)
        #else
            if #available(iOS 26.0, macOS 26.0, *) {
                self.glassEffect(.regular, in: shape)
            } else {
                self.background(.ultraThinMaterial, in: shape)
            }
        #endif
    }
}
