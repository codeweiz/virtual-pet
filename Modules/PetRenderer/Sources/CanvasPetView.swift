import DesignSystem
import PetKit
import SwiftUI

/// Fully cross-platform (incl. watchOS) pet, drawn with `Canvas` +
/// `TimelineView`. This is the watch tier and the universal fallback; on
/// iPhone/Mac `PetView` swaps in the Rive renderer.
public struct CanvasPetView: View {
    private let mood: Mood
    public init(mood: Mood) { self.mood = mood }

    public var body: some View {
        TimelineView(.animation) { ctx in
            let time = ctx.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                draw(&context, size: size, time: time)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Pet looking \(mood.label)")
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let unit = min(size.width, size.height)
        let cx = size.width / 2

        // Idle bob + breathing squash-and-stretch.
        let bob = sin(time * 1.6) * unit * 0.02
        let breathe = 1 + sin(time * 2.2) * 0.03
        let bodyW = unit * 0.6
        let bodyH = unit * 0.6 * breathe
        let cy = size.height / 2 + bob
        let tint = color(for: mood)

        // Soft glow halo.
        let glowRect = CGRect(
            x: cx - bodyW * 0.7, y: cy - bodyH * 0.7,
            width: bodyW * 1.4, height: bodyH * 1.4
        )
        context.fill(Path(ellipseIn: glowRect), with: .color(tint.opacity(0.18)))

        // Body with a vertical gradient.
        let bodyRect = CGRect(x: cx - bodyW / 2, y: cy - bodyH / 2, width: bodyW, height: bodyH)
        context.fill(
            Path(ellipseIn: bodyRect),
            with: .linearGradient(
                Gradient(colors: [tint.opacity(0.95), tint.opacity(0.7)]),
                startPoint: CGPoint(x: cx, y: cy - bodyH / 2),
                endPoint: CGPoint(x: cx, y: cy + bodyH / 2)
            )
        )

        drawEyes(
            &context, center: CGPoint(x: cx, y: cy), bodyW: bodyW, bodyH: bodyH, unit: unit,
            time: time)
        drawMouth(&context, center: CGPoint(x: cx, y: cy), bodyW: bodyW, bodyH: bodyH, unit: unit)
    }

    private func drawEyes(
        _ context: inout GraphicsContext, center: CGPoint,
        bodyW: CGFloat, bodyH: CGFloat, unit: CGFloat, time: TimeInterval
    ) {
        let blink: CGFloat = sin(time * 0.9) > 0.97 ? 0.1 : 1.0
        let eyeY = center.y - bodyH * 0.05
        let eyeDX = bodyW * 0.18
        let eyeR = unit * 0.045

        for sign in [-1.0, 1.0] {
            let ex = center.x + CGFloat(sign) * eyeDX
            if mood == .sleeping {
                var lid = Path()
                lid.move(to: CGPoint(x: ex - eyeR, y: eyeY))
                lid.addQuadCurve(
                    to: CGPoint(x: ex + eyeR, y: eyeY),
                    control: CGPoint(x: ex, y: eyeY + eyeR)
                )
                context.stroke(lid, with: .color(PetPalette.ink), lineWidth: max(1, unit * 0.012))
            } else {
                let rect = CGRect(
                    x: ex - eyeR, y: eyeY - eyeR * blink,
                    width: eyeR * 2, height: eyeR * 2 * blink
                )
                context.fill(Path(ellipseIn: rect), with: .color(PetPalette.ink))
            }
        }
    }

    private func drawMouth(
        _ context: inout GraphicsContext, center: CGPoint,
        bodyW: CGFloat, bodyH: CGFloat, unit: CGFloat
    ) {
        let mouthY = center.y + bodyH * 0.16
        let mw = bodyW * 0.22
        var mouth = Path()

        switch mood {
        case .happy, .content:
            mouth.move(to: CGPoint(x: center.x - mw, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: center.x + mw, y: mouthY),
                control: CGPoint(x: center.x, y: mouthY + mw * 0.9)
            )
        case .sad, .hungry, .tired, .dirty:
            mouth.move(to: CGPoint(x: center.x - mw, y: mouthY + mw * 0.5))
            mouth.addQuadCurve(
                to: CGPoint(x: center.x + mw, y: mouthY + mw * 0.5),
                control: CGPoint(x: center.x, y: mouthY - mw * 0.3)
            )
        case .sleeping:
            mouth.addEllipse(
                in: CGRect(x: center.x - mw * 0.2, y: mouthY, width: mw * 0.4, height: mw * 0.4))
        }
        context.stroke(mouth, with: .color(PetPalette.ink), lineWidth: max(1, unit * 0.014))
    }

    private func color(for mood: Mood) -> Color {
        switch mood {
        case .happy: PetPalette.mint
        case .content: PetPalette.periwinkle
        case .hungry: PetPalette.butter
        case .tired: PetPalette.periwinkle.opacity(0.8)
        case .dirty: PetPalette.mint.opacity(0.6)
        case .sad: PetPalette.coral
        case .sleeping: PetPalette.periwinkle.opacity(0.7)
        }
    }
}

#Preview {
    CanvasPetView(mood: .happy)
        .frame(width: 240, height: 240)
}
