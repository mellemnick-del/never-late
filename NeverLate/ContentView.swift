import SwiftUI

struct ContentView: View {
    @State private var game = GameModel()
    @State private var touching = false
    @State private var shareImage: Image?
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
        .onChange(of: game.state) { _, state in
            shareImage = state == .over
                ? ShareCard.image(score: game.score, title: shareTitle, subtitle: shareSubtitle)
                : nil
        }
    }

    private var shareTitle: String {
        game.lastRunMode == .daily ? "DAILY #\(game.dailyNumber)" : "NEVER LATE"
    }

    private var shareSubtitle: String {
        if game.lastRunMode == .daily {
            return game.dailyStreak > 1 ? "\(game.dailyStreak) DAY STREAK" : "SAME RUN FOR EVERYONE TODAY"
        }
        return "REACHED PHASE \(game.phase.rawValue) · \(game.phase.title.dropFirst(4))"
    }

    private var shareMessage: String {
        if game.lastRunMode == .daily {
            return "Never Late Daily #\(game.dailyNumber): \(game.score). Same run for everyone today. Can you beat it?"
        }
        return "I scored \(game.score) on Never Late. Can you beat it?"
    }

    private var hud: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                if game.mode == .daily {
                    Caption(game.dailyStreak > 0 ? "DAILY #\(game.dailyNumber) · STREAK \(game.dailyStreak)"
                                                  : "DAILY #\(game.dailyNumber)")
                    Text(game.dailyScore.map { "\($0)" } ?? "--")
                        .font(Theme.display(28))
                        .monospacedDigit()
                        .foregroundStyle(Theme.lume)
                } else {
                    Caption("BEST")
                    Text("\(game.best)")
                        .font(Theme.display(28))
                        .monospacedDigit()
                        .foregroundStyle(Theme.lume)
                }
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
            ModePicker(mode: Binding(get: { game.mode }, set: { game.mode = $0 }))
                .disabled(game.state == .paused)
                .opacity(game.state == .paused ? 0.4 : 1)
            Spacer()
            HStack(spacing: 10) {
                if let shareImage, game.state == .over {
                    ShareLink(item: shareImage,
                              message: Text(shareMessage),
                              preview: SharePreview("Never Late", image: shareImage)) {
                        IconLabel(system: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share score")
                }
                IconButton(system: "trophy.fill", label: "Leaderboards and achievements") {
                    GameCenter.showLeaderboards()
                }
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
                Caption(overCaption, color: Theme.gilt)
                Text("LATE").font(Theme.display(44)).tracking(3).foregroundStyle(Theme.red)
                Text("\(game.score)").font(Theme.display(60)).monospacedDigit().foregroundStyle(Theme.lume)
                Blurb("\(game.hits) clean hits · reached phase \(game.phase.rawValue)")
                Pill("TAP TO GO AGAIN")
            case .paused:
                Text("PAUSED").font(Theme.display(40)).tracking(3).foregroundStyle(Theme.lume)
                Blurb("Score \(game.score). The hand picks up right where you left it.")
                Pill("TAP TO RESUME")
            default:
                if game.mode == .daily {
                    Caption("DAILY CHALLENGE #\(game.dailyNumber)", color: Theme.gilt)
                    Text("NEVER LATE").font(Theme.display(40)).tracking(3).foregroundStyle(Theme.lume)
                    if let today = game.dailyScore {
                        Blurb("Today's score: \(today). Replays are practice. A new run unlocks at midnight.")
                        Pill("PRACTICE")
                    } else {
                        Blurb("Same run for everyone today. Only your first try counts, so make it good.")
                        Pill("TAP TO START")
                    }
                } else {
                    Text("NEVER LATE").font(Theme.display(40)).tracking(3).foregroundStyle(Theme.lume)
                    Blurb("Tap when the seconds hand is inside the lume marker. Dead center scores double. Let it slip past and the run ends.")
                    Pill("TAP TO START")
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Theme.bg.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.navy, lineWidth: 1))
        .padding(.horizontal, 28)
    }

    private var overCaption: String {
        switch (game.lastRunMode, game.lastRunScored) {
        case (.daily, true):
            game.dailyStreak > 1 ? "DAILY #\(game.dailyNumber) · \(game.dailyStreak) DAY STREAK" : "DAILY #\(game.dailyNumber)"
        case (.daily, false):
            "PRACTICE · TODAY'S SCORE \(game.dailyScore ?? 0)"
        default:
            game.isNewBest ? "NEW PERSONAL BEST" : "BEST \(game.best)"
        }
    }
}

private struct ModePicker: View {
    @Binding var mode: GameModel.Mode

    var body: some View {
        HStack(spacing: 2) {
            segment("CLASSIC", .classic)
            segment("DAILY", .daily)
        }
        .padding(3)
        .background(Theme.navy.opacity(0.6), in: Capsule())
    }

    private func segment(_ title: String, _ value: GameModel.Mode) -> some View {
        Button {
            mode = value
        } label: {
            Text(title)
                .font(Theme.mono(11, weight: .semibold)).tracking(1.5)
                .foregroundStyle(mode == value ? Theme.bg : Theme.steel)
                .padding(.horizontal, 12).frame(height: 32)
                .background(mode == value ? Theme.lume : Color.clear, in: Capsule())
        }
        .accessibilityAddTraits(mode == value ? .isSelected : [])
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
            IconLabel(system: system)
        }
        .accessibilityLabel(label)
    }
}

private struct IconLabel: View {
    let system: String
    var body: some View {
        Image(systemName: system)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.steel)
            .frame(width: 44, height: 44)
            .background(Theme.navy.opacity(0.6), in: Circle())
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
