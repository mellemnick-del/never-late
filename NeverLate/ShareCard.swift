import SwiftUI

/// The image people share after a run: the dial with the score in the date window.
struct ShareCard: View {
    let score: Int
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(Theme.display(34)).tracking(3)
                .foregroundStyle(Theme.lume)
            Canvas { context, size in
                DialRenderer.draw(in: context, size: size, state: DialState(
                    angle: .pi * 0.35, targetAngle: .pi * 0.35, halfWidth: 0.2, direction: 1,
                    score: score, showTarget: true, missed: false, flash: 0, flashText: "",
                    flashPerfect: false, shake: 0, now: Date()))
            }
            .frame(width: 520, height: 520)
            Text(subtitle)
                .font(Theme.mono(20, weight: .semibold)).tracking(2)
                .foregroundStyle(Theme.gilt)
            Text("NEVER LATE · APP STORE")
                .font(Theme.mono(14)).tracking(3)
                .foregroundStyle(Theme.steel)
        }
        .padding(44)
        .frame(width: 640)
        .background(Theme.bg)
    }

    /// Renders the card to an image for the share sheet.
    @MainActor
    static func image(score: Int, title: String, subtitle: String) -> Image? {
        let renderer = ImageRenderer(content: ShareCard(score: score, title: title, subtitle: subtitle))
        renderer.scale = 2
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}
