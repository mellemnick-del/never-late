import SwiftUI

/// Snapshot of what the dial needs for one frame. Reading these in `body`
/// lets Observation redraw the canvas whenever any of them changes.
struct DialState {
    var angle: Double
    var targetAngle: Double
    var halfWidth: Double
    var direction: Double
    var score: Int
    var showTarget: Bool
    var missed: Bool
    var flash: Double
    var flashText: String
    var flashPerfect: Bool
    var shake: Double
}

struct DialView: View {
    let game: GameModel

    var body: some View {
        let s = DialState(
            angle: game.angle,
            targetAngle: game.targetAngle,
            halfWidth: game.halfWidth,
            direction: game.direction,
            score: game.score,
            showTarget: game.state != .ready,
            missed: game.state == .over,
            flash: game.flash,
            flashText: game.flashText,
            flashPerfect: game.flashPerfect,
            shake: game.shake
        )
        Canvas { context, size in
            DialRenderer.draw(in: context, size: size, state: s)
        }
        .accessibilityLabel("Watch dial. Score \(game.score).")
    }
}

private enum DialRenderer {
    static let tau = Double.pi * 2

    /// Point on a circle for a dial angle (0 at 12 o'clock, clockwise).
    static func point(_ angle: Double, _ radius: Double) -> CGPoint {
        CGPoint(x: radius * sin(angle), y: -radius * cos(angle))
    }

    static func arc(radius: Double, from: Double, to: Double) -> Path {
        var path = Path()
        let steps = max(8, Int(abs(to - from) * 40))
        for i in 0...steps {
            let p = point(from + (to - from) * Double(i) / Double(steps), radius)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }

    static func circle(_ radius: Double) -> Path {
        Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
    }

    static func draw(in base: GraphicsContext, size: CGSize, state s: DialState) {
        var ctx = base
        let side = min(size.width, size.height)
        let R = side / 2 * 0.95
        var shakeX = 0.0, shakeY = 0.0
        if s.shake > 0 {
            shakeX = Double.random(in: -6...6) * s.shake
            shakeY = Double.random(in: -6...6) * s.shake
        }
        ctx.translateBy(x: size.width / 2 + shakeX, y: size.height / 2 + shakeY)

        let bezOut = R, bezIn = R * 0.8
        let bezMid = (bezOut + bezIn) / 2, bezW = bezOut - bezIn

        // Bezel
        ctx.fill(circle(bezOut), with: .color(Theme.bezel))
        ctx.stroke(circle(bezOut), with: .color(Theme.green), lineWidth: 1.5)

        // 60 minute dive bezel graduations
        for i in 0..<60 {
            var r = ctx
            r.rotate(by: .radians(Double(i) / 60 * tau))
            if i == 0 {
                var tri = Path()
                tri.move(to: CGPoint(x: 0, y: -bezIn - bezW * 0.2))
                tri.addLine(to: CGPoint(x: -bezW * 0.26, y: -bezOut + bezW * 0.2))
                tri.addLine(to: CGPoint(x: bezW * 0.26, y: -bezOut + bezW * 0.2))
                tri.closeSubpath()
                r.fill(tri, with: .color(Theme.lume))
            } else if i % 10 == 0 {
                r.draw(Text("\(i)").font(Theme.display(bezW * 0.42)).foregroundStyle(Theme.steel),
                       at: CGPoint(x: 0, y: -bezMid))
            } else if i % 5 == 0 {
                r.fill(Path(CGRect(x: -1.5, y: -bezMid - bezW * 0.18, width: 3, height: bezW * 0.36)),
                       with: .color(Theme.steel))
            } else if i < 15 {
                r.fill(Path(CGRect(x: -0.75, y: -bezMid - bezW * 0.12, width: 1.5, height: bezW * 0.24)),
                       with: .color(Theme.steel))
            }
        }

        // Target marker on the bezel
        if s.showTarget {
            let color = s.missed ? Theme.red : Theme.lume
            var glow = ctx
            glow.addFilter(.shadow(color: color.opacity(0.9), radius: 7))
            let band = StrokeStyle(lineWidth: bezW * 0.82, lineCap: .butt)
            var outer = glow
            outer.opacity = 0.55
            outer.stroke(arc(radius: bezMid, from: s.targetAngle - s.halfWidth, to: s.targetAngle + s.halfWidth),
                         with: .color(color), style: band)
            let core = s.halfWidth * GameModel.perfectFraction
            glow.stroke(arc(radius: bezMid, from: s.targetAngle - core, to: s.targetAngle + core),
                        with: .color(color), style: band)
        }

        // Dial
        let dR = R * 0.78
        ctx.fill(circle(dR), with: .radialGradient(
            Gradient(colors: [Theme.dialHighlight, Theme.dial]),
            center: CGPoint(x: 0, y: -dR * 0.3), startRadius: dR * 0.1, endRadius: dR))

        // Minute track
        for i in 0..<60 where i % 5 != 0 {
            var r = ctx
            r.rotate(by: .radians(Double(i) / 60 * tau))
            r.fill(Path(CGRect(x: -0.6, y: -dR * 0.97, width: 1.2, height: dR * 0.05)), with: .color(Theme.steel))
        }

        // Crosshair (brand mark)
        var cross = ctx
        cross.opacity = 0.7
        var lines = Path()
        lines.move(to: CGPoint(x: -dR * 0.86, y: 0)); lines.addLine(to: CGPoint(x: dR * 0.86, y: 0))
        lines.move(to: CGPoint(x: 0, y: -dR * 0.86)); lines.addLine(to: CGPoint(x: 0, y: dR * 0.86))
        cross.stroke(lines, with: .color(Theme.green), lineWidth: 1)
        cross.stroke(circle(dR * 0.42), with: .color(Theme.green), lineWidth: 1)

        // Lume hour plots (3 o'clock is the date window)
        var lume = ctx
        lume.addFilter(.shadow(color: Theme.lume.opacity(0.6), radius: 3))
        for h in 0..<12 where h != 3 {
            var r = lume
            r.rotate(by: .radians(Double(h) / 12 * tau))
            if h == 0 {
                var tri = Path()
                tri.move(to: CGPoint(x: 0, y: -dR * 0.72))
                tri.addLine(to: CGPoint(x: -dR * 0.07, y: -dR * 0.9))
                tri.addLine(to: CGPoint(x: dR * 0.07, y: -dR * 0.9))
                tri.closeSubpath()
                r.fill(tri, with: .color(Theme.lume))
            } else if h % 3 == 0 {
                r.fill(Path(CGRect(x: -dR * 0.03, y: -dR * 0.91, width: dR * 0.06, height: dR * 0.18)),
                       with: .color(Theme.lume))
            } else {
                r.fill(circle(dR * 0.045).offsetBy(dx: 0, dy: -dR * 0.84), with: .color(Theme.lume))
            }
        }

        // Date window shows the score
        let ww = dR * 0.3, wh = dR * 0.2, wx = dR * 0.66
        let window = Path(CGRect(x: wx - ww / 2, y: -wh / 2, width: ww, height: wh))
        ctx.fill(window, with: .color(Theme.paper))
        ctx.stroke(window, with: .color(Theme.steel), lineWidth: 1.5)
        ctx.draw(Text("\(s.score)").font(Theme.display(wh * 0.78)).foregroundStyle(Theme.ink),
                 at: CGPoint(x: wx, y: 1))

        // Dial text
        ctx.draw(Text("ZERO DAY").font(Theme.display(dR * 0.085)).foregroundStyle(Theme.lume),
                 at: CGPoint(x: 0, y: -dR * 0.5))
        ctx.draw(Text("NEVER OFF · NEVER LATE").font(Theme.mono(dR * 0.05)).foregroundStyle(Theme.steel),
                 at: CGPoint(x: 0, y: dR * 0.52))
        ctx.draw(Text(s.direction > 0 ? "CW" : "CCW").font(Theme.mono(dR * 0.05)).foregroundStyle(Theme.green),
                 at: CGPoint(x: 0, y: dR * 0.62))

        // Seconds hand
        var hand = ctx
        hand.rotate(by: .radians(s.angle))
        var stem = Path()
        stem.move(to: CGPoint(x: 0, y: dR * 0.2))
        stem.addLine(to: CGPoint(x: 0, y: -dR * 0.98))
        hand.stroke(stem, with: .color(s.missed ? Theme.red : Theme.paper),
                    style: StrokeStyle(lineWidth: max(2, dR * 0.018), lineCap: .round))
        var pip = hand
        pip.addFilter(.shadow(color: Theme.lume.opacity(0.9), radius: 5))
        pip.fill(circle(dR * 0.05).offsetBy(dx: 0, dy: -dR * 0.7), with: .color(Theme.lume))
        ctx.fill(circle(dR * 0.045), with: .color(Theme.paper))
        ctx.fill(circle(dR * 0.018), with: .color(Theme.dial))

        // Hit flash
        if s.flash > 0 {
            var f = ctx
            f.opacity = s.flash
            f.draw(Text(s.flashText).font(Theme.display(dR * 0.13))
                    .foregroundStyle(s.flashPerfect ? Theme.lume : Theme.steel),
                   at: CGPoint(x: 0, y: dR * 0.28 - (1 - s.flash) * dR * 0.12))
        }
    }
}
