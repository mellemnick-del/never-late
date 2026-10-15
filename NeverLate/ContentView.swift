import SwiftUI

struct ContentView: View {
    @State private var game = GameModel()
    @State private var touching = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // Touch-down anywhere counts as a tap; this fires faster than onTapGesture.
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !touching else { return }
                            touching = true
                            game.tap()
                        }
                        .onEnded { _ in touching = false }
                )

            VStack(spacing: 10) {
                hud.allowsHitTesting(false)
                ZStack {
                    DialView(game: game)
                        .aspectRatio(1, contentMode: .fit)
                    if game.showCard {
                        MenuCard(game: game)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.2), value: game.showCard)
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear {
            game.startLoop()
            GameCenter.authenticate()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { game.startLoop() } else { game.stopLoop() }
        }
    }

    private var hud: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Caption("BEST")
                Text("\(game.best)")
                    .font(Theme.display(28))
                    .monospacedDigit()
                    .foregroundStyle(Theme.lume)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Caption("PHASE")
                Text(game.phase.title)
                    .font(Theme.displayMedium(16))
                    .foregroundStyle(Theme.gilt)
            }
        }
    }

    private var bottomBar: some View {
        let menu = game.state != .playing
        return HStack {
            IconButton(system: game.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill",
                       label: game.soundOn ? "Mute sound" : "Turn sound on") {
                game.soundOn.toggle()
            }
            Spacer()
            Caption(menu ? "TAP ANYWHERE" : "").allowsHitTesting(false)
            Spacer()
            IconButton(system: "trophy.fill", label: "Leaderboard") {
                GameCenter.showLeaderboard()
            }
        }
        .opacity(menu ? 1 : 0)
        .disabled(!menu)
        .allowsHitTesting(menu)
        .frame(height: 44)
    }
}

private struct MenuCard: View {
    let game: GameModel

    var body: some View {
        VStack(spacing: 10) {
            switch game.state {
            case .over:
                Caption(game.isNewBest ? "NEW PERSONAL BEST" : "BEST \(game.best)", color: Theme.gilt)
                Text("LATE").font(Theme.display(44)).tracking(3).foregroundStyle(Theme.red)
                Text("\(game.score)").font(Theme.display(60)).monospacedDigit().foregroundStyle(Theme.lume)
                Blurb("\(game.hits) clean hits · reached phase \(game.phase.rawValue)")
                Pill("TAP TO GO AGAIN")
            case .paused:
                Caption("ZERO DAY WATCHES", color: Theme.gilt)
                Text("PAUSED").font(Theme.display(40)).tracking(3).foregroundStyle(Theme.lume)
                Blurb("Score \(game.score). The hand picks up right where you left it.")
                Pill("TAP TO RESUME")
            default:
                Caption("ZERO DAY WATCHES", color: Theme.gilt)
                Text("NEVER LATE").font(Theme.display(40)).tracking(3).foregroundStyle(Theme.lume)
                Blurb("Tap when the seconds hand is inside the lume marker. Dead center scores double. Let it slip past and the run ends.")
                Pill("TAP TO START")
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Theme.bg.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.navy, lineWidth: 1))
        .padding(.horizontal, 28)
    }
}

private struct Caption: View {
    let text: String
    var color: Color = Theme.steel
    init(_ text: String, color: Color = Theme.steel) { self.text = text; self.color = color }
    var body: some View {
        Text(text).font(Theme.mono(10, weight: .semibold)).tracking(2).foregroundStyle(color)
    }
}

private struct Blurb: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(Theme.mono(12)).foregroundStyle(Theme.steel).lineSpacing(3).frame(maxWidth: 260)
    }
}

private struct Pill: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(Theme.mono(13, weight: .semibold)).tracking(2)
            .foregroundStyle(Theme.bg)
            .padding(.horizontal, 22).padding(.vertical, 11)
            .background(Theme.lume, in: Capsule())
            .padding(.top, 4)
    }
}

private struct IconButton: View {
    let system: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.steel)
                .frame(width: 44, height: 44)
                .background(Theme.navy.opacity(0.6), in: Circle())
        }
        .accessibilityLabel(label)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
