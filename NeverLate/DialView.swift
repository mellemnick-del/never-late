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
    var now: Date
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
            shake: game.shake,
            now: Date()
        )
        Canvas { context, size in
            DialRenderer.draw(in: context, size: size, state: s)
        }
        .accessibilityLabel("Watch dial. Score \(game.score).")
    }
}

enum DialRenderer {
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

    /// Closed band between two radii, from one dial angle to another.
    static func band(_ r0: Double, _ r1: Double, from: Double, to: Double) -> Path {
        var path = arc(radius: r1, from: from, to: to)
        let inner = arc(radius: r0, from: to, to: from)
        inner.forEach { element in
            switch element {
            case .move(to: let p), .line(to: let p): path.addLine(to: p)
            default: break
            }
        }
        path.closeSubpath()
        return path
    }

    /// A shape laid along a hand: x runs out from the center, y is the half-width.
    static func handShape(_ points: [(Double, Double)]) -> Path {
        var path = Path()
        for (i, p) in points.enumerated() {
            let pt = CGPoint(x: p.1, y: -p.0)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }

    static func rect(_ r0: Double, _ r1: Double, _ halfWidth: Double) -> Path {
        handShape([(r0, -halfWidth), (r1, -halfWidth), (r1, halfWidth), (r0, halfWidth)])
    }

    static func draw(in base: GraphicsContext, size: CGSize, state s: DialState) {
        var ctx = base
        let side = min(size.width, size.height)
        let R = side / 2 * 0.97
        var shakeX = 0.0, shakeY = 0.0
        if s.shake > 0 {
            shakeX = Double.random(in: -6...6) * s.shake
            shakeY = Double.random(in: -6...6) * s.shake
        }
        ctx.translateBy(x: size.width / 2 + shakeX, y: size.height / 2 + shakeY)

        // Steel case edge with knurling
        ctx.fill(circle(R), with: .color(Theme.metalDark))
        var knurl = Path()
        for i in 0..<120 {
            let a = Double(i) / 120 * tau
            knurl.move(to: point(a, R * 0.965)); knurl.addLine(to: point(a, R))
        }
        ctx.stroke(knurl, with: .color(Theme.metal), lineWidth: 1.6)
        ctx.fill(circle(R * 0.965), with: .color(Theme.metal))

        // Pepsi insert: burgundy across the top (18 to 6 via 24), navy across the bottom
        let bezOut = R * 0.95, bezIn = R * 0.76
        let bezMid = (bezOut + bezIn) / 2, bezW = bezOut - bezIn
        ctx.fill(band(bezIn, bezOut, from: -.pi / 2, to: .pi / 2), with: .color(Theme.burgundy))
        ctx.fill(band(bezIn, bezOut, from: .pi / 2, to: .pi * 1.5), with: .color(Theme.navy))

        // 24 hour scale in gilt
        for h in 0..<24 {
            let a = Double(h) / 24 * tau
            var r = ctx
            r.rotate(by: .radians(a))
            if h == 0 {
                var tri = Path()
                tri.move(to: CGPoint(x: 0, y: -bezIn - bezW * 0.18))
                tri.addLine(to: CGPoint(x: -bezW * 0.3, y: -bezOut + bezW * 0.16))
                tri.addLine(to: CGPoint(x: bezW * 0.3, y: -bezOut + bezW * 0.16))
                tri.closeSubpath()
                r.fill(tri, with: .color(Theme.gilt))
            } else if h % 2 == 0 {
                r.translateBy(x: 0, y: -bezMid)
                // Keep numerals on the lower half readable
                if a >= .pi / 2 - 0.001 && a < .pi * 1.5 - 0.001 { r.rotate(by: .radians(.pi)) }
                r.draw(Text("\(h)").font(Theme.display(bezW * 0.46)).foregroundStyle(Theme.gilt), at: .zero)
            } else {
                r.fill(circle(bezW * 0.07).offsetBy(dx: 0, dy: -bezMid), with: .color(Theme.gilt))
            }
        }

        // Target marker on the bezel
        if s.showTarget {
            let color = s.missed ? Theme.red : Theme.lume
            let core = s.halfWidth * GameModel.perfectFraction
            let r0 = bezIn + bezW * 0.06, r1 = bezOut - bezW * 0.06
            var glow = ctx
            glow.addFilter(.shadow(color: (s.missed ? Theme.red : Theme.lumeHot).opacity(0.9), radius: 9))
            var outer = glow
            outer.opacity = 0.75
            outer.fill(band(r0, r1, from: s.targetAngle - s.halfWidth, to: s.targetAngle + s.halfWidth),
                       with: .color(color))
            glow.fill(band(r0, r1, from: s.targetAngle - core, to: s.targetAngle + core),
                      with: .color(s.missed ? Theme.red : Theme.lumeHot))
        }

        // Black dial with a soft dome highlight
        ctx.fill(circle(bezIn), with: .color(Color(hex: 0x1E1E20)))
        let dR = bezIn * 0.97
        ctx.fill(circle(dR), with: .color(Theme.dial))
        ctx.fill(circle(dR), with: .radialGradient(
            Gradient(colors: [Theme.dialHighlight.opacity(0.9), Theme.dial.opacity(0)]),
            center: CGPoint(x: -dR * 0.15, y: -dR * 0.5), startRadius: 0, endRadius: dR * 0.8))

        // Minute track
        for i in 0..<60 {
            var r = ctx
            r.rotate(by: .radians(Double(i) / 60 * tau))
            let major = i % 5 == 0
            let len = dR * (major ? 0.06 : 0.035)
            r.fill(Path(CGRect(x: major ? -1.1 : -0.6, y: -dR * 0.985, width: major ? 2.2 : 1.2, height: len)),
                   with: .color(major ? Theme.lume : Theme.paper.opacity(0.8)))
        }

        // Lume plots with gilt surrounds (3 o'clock is the date window)
        func plot(_ h: Int, grow: Double) -> Path {
            if h == 0 {
                var tri = Path()
                tri.move(to: CGPoint(x: 0, y: -dR * 0.66 + grow))
                tri.addLine(to: CGPoint(x: -dR * 0.095 - grow, y: -dR * 0.89 - grow))
                tri.addLine(to: CGPoint(x: dR * 0.095 + grow, y: -dR * 0.89 - grow))
                tri.closeSubpath()
                return tri
            } else if h % 3 == 0 {
                let w = dR * 0.042 + grow
                return Path(CGRect(x: -w, y: -dR * 0.89 - grow, width: w * 2, height: dR * 0.21 + grow * 2))
            } else {
                return circle(dR * 0.065 + grow).offsetBy(dx: 0, dy: -dR * 0.8)
            }
        }
        var lume = ctx
        lume.addFilter(.shadow(color: Theme.lume.opacity(0.35), radius: 4))
        for h in 0..<12 where h != 3 {
            var r = lume
            r.rotate(by: .radians(Double(h) / 12 * tau))
            r.fill(plot(h, grow: dR * 0.012), with: .color(Theme.gilt))
            r.fill(plot(h, grow: 0), with: .color(Theme.lume))
        }

        // Date window at 3 shows the score
        let ww = dR * 0.24, wh = dR * 0.17, wx = dR * 0.74
        let window = Path(roundedRect: CGRect(x: wx - ww / 2, y: -wh / 2, width: ww, height: wh), cornerRadius: 2)
        ctx.fill(window, with: .color(Theme.paper))
        ctx.stroke(window, with: .color(Theme.gilt), lineWidth: 2)
        ctx.draw(Text("\(s.score)").font(Theme.display(wh * 0.74)).foregroundStyle(Theme.ink),
                 at: CGPoint(x: wx, y: 1))

        // Dial print
        ctx.draw(Text("NEVER LATE").font(Theme.display(dR * 0.085)).tracking(dR * 0.008).foregroundStyle(Theme.paper),
                 at: CGPoint(x: 0, y: -dR * 0.44))
        ctx.draw(Text("GMT").font(Theme.display(dR * 0.07)).tracking(dR * 0.01).foregroundStyle(Theme.red),
                 at: CGPoint(x: 0, y: -dR * 0.33))
        ctx.draw(Text(s.direction > 0 ? "CW" : "CCW").font(Theme.mono(dR * 0.05)).foregroundStyle(Theme.gilt),
                 at: CGPoint(x: 0, y: dR * 0.45))

        // Real time hands: hour, minute and a 24 hour GMT hand that reads on the bezel
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute, .second], from: s.now)
        let hours = Double(now.hour ?? 0), minutes = Double(now.minute ?? 0) + Double(now.second ?? 0) / 60
        let hourAngle = (hours.truncatingRemainder(dividingBy: 12) + minutes / 60) / 12 * tau
        let minuteAngle = minutes / 60 * tau
        let gmtAngle = (hours + minutes / 60) / 24 * tau

        var gmt = ctx
        gmt.rotate(by: .radians(gmtAngle))
        gmt.fill(rect(-dR * 0.1, dR * 0.78, dR * 0.011), with: .color(Theme.burgundy))
        gmt.fill(handShape([(dR * 0.74, -dR * 0.07), (dR * 0.92, 0), (dR * 0.74, dR * 0.07)]), with: .color(Theme.burgundy))
        gmt.fill(handShape([(dR * 0.765, -dR * 0.04), (dR * 0.87, 0), (dR * 0.765, dR * 0.04)]), with: .color(Theme.lume))

        var hourHand = ctx
        hourHand.rotate(by: .radians(hourAngle))
        hourHand.fill(rect(-dR * 0.12, dR * 0.36, dR * 0.03), with: .color(Theme.metal))
        hourHand.fill(rect(dR * 0.36, dR * 0.52, dR * 0.08), with: .color(Theme.metal))
        hourHand.fill(rect(dR * 0.375, dR * 0.505, dR * 0.062), with: .color(Theme.lume))
        hourHand.fill(handShape([(dR * 0.52, -dR * 0.03), (dR * 0.6, 0), (dR * 0.52, dR * 0.03)]), with: .color(Theme.metal))

        var minuteHand = ctx
        minuteHand.rotate(by: .radians(minuteAngle))
        minuteHand.fill(handShape([(-dR * 0.14, -dR * 0.026), (dR * 0.8, -dR * 0.026), (dR * 0.88, 0),
                                   (dR * 0.8, dR * 0.026), (-dR * 0.14, dR * 0.026)]), with: .color(Theme.metal))
        minuteHand.fill(handShape([(dR * 0.3, -dR * 0.014), (dR * 0.78, -dR * 0.014), (dR * 0.83, 0),
                                   (dR * 0.78, dR * 0.014), (dR * 0.3, dR * 0.014)]), with: .color(Theme.lume))

        // Game hand: the seconds hand, with a lume box like a snowflake seconds hand
        var hand = ctx
        hand.rotate(by: .radians(s.angle))
        let handColor = s.missed ? Theme.red : Theme.paper
        hand.fill(rect(-dR * 0.22, dR * 0.99, dR * 0.009), with: .color(handColor))
        var pip = hand
        pip.addFilter(.shadow(color: Theme.lumeHot.opacity(0.8), radius: 6))
        pip.fill(rect(dR * 0.62, dR * 0.74, dR * 0.05), with: .color(handColor))
        pip.fill(rect(dR * 0.632, dR * 0.728, dR * 0.038), with: .color(Theme.lume))
        ctx.fill(circle(dR * 0.05), with: .color(Theme.metal))
        ctx.fill(circle(dR * 0.02), with: .color(Theme.metalDark))

        // Hit flash
        if s.flash > 0 {
            var f = ctx
            f.opacity = s.flash
            f.draw(Text(s.flashText).font(Theme.display(dR * 0.13))
                    .foregroundStyle(s.flashPerfect ? Theme.lumeHot : Theme.gilt),
                   at: CGPoint(x: 0, y: dR * 0.28 - (1 - s.flash) * dR * 0.12))
        }
    }
}
