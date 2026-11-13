
import SwiftUI
import AVFoundation

struct CountdownView: View {

    @Environment(\.dismiss) var dismiss
    @State private var tickPlayer: AVAudioPlayer?
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isPulsing = false
    @State private var vignetteBreathing = false
    @State private var isExpired = false

    let countdownDuration: TimeInterval = 24 * 60 * 60 // 24 hours

    var body: some View {
        ZStack {

            Color.black.ignoresSafeArea()

            // Breathing vignette
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        Color.red.opacity(vignetteBreathing ? 0.25 : 0.07),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: vignetteBreathing ? 540 : 380
                )
                .frame(height: vignetteBreathing ? 500 : 360)
                .animation(
                    .easeInOut(duration: 3.5)
                    .repeatForever(autoreverses: true),
                    value: vignetteBreathing
                )
            }
            .ignoresSafeArea()

            // Scanlines
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ForEach(0..<Int(geo.size.height / 4), id: \.self) { _ in
                        Color.black.opacity(0.13)
                            .frame(height: 1)
                        Color.clear
                            .frame(height: 3)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {

                Spacer().frame(height: 80)

                // Praying hands
                Image("PrayingHands")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 110)
                    .scaleEffect(isPulsing ? 1.04 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Spacer().frame(height: 30)

                // Top label
                Text(isExpired ? "소원이 이루어졌습니다" : "소원이 처리되고 있습니다")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(4)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 60)

                if isExpired {
                    // Expired state
                    Text("✓")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(.red.opacity(0.8))

                    Spacer().frame(height: 20)

                    Text("완료")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(6)

                } else {
                    // Countdown timer
                    Text(timeString(timeRemaining))
                        .font(.system(size: 58, weight: .thin))
                        .foregroundColor(.white)
                        .tracking(8)
                        .monospacedDigit()

                    Spacer().frame(height: 16)

                    Text("남은 시간")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(6)
                }

                Spacer().frame(height: 50)

                // Warning
                Text(isExpired ? "결과는 되돌릴 수 없습니다" : "시간이 다 되기 전에 도망칠 수 없습니다")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.red.opacity(vignetteBreathing ? 0.75 : 0.35))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .animation(
                        .easeInOut(duration: 3.5)
                        .repeatForever(autoreverses: true),
                        value: vignetteBreathing
                    )

                Spacer()

                // Back to home
                Button {
                    dismiss()
                } label: {
                    Text("집으로")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.2))
                        .tracking(4)
                }

                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            isPulsing = true
            vignetteBreathing = true
            startTickingSound()
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Countdown logic

    func startCountdown() {
        let key = "wishDeadline"

        // If no deadline saved yet, save one
        if UserDefaults.standard.object(forKey: key) == nil {
            let deadline = Date().addingTimeInterval(countdownDuration)
            UserDefaults.standard.set(deadline, forKey: key)
        }

        // Calculate remaining time
        updateTimeRemaining()

        // Tick every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }

    func updateTimeRemaining() {
        let key = "wishDeadline"
        guard let deadline = UserDefaults.standard.object(forKey: key) as? Date else { return }

        let remaining = deadline.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            isExpired = true
            timer?.invalidate()
        } else {
            timeRemaining = remaining
        }
    }

    func timeString(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    func startTickingSound() {
        guard let url = Bundle.main.url(forResource: "tick", withExtension: "mp3") else {
            print("Tick sound not found")
            return
        }
        do {
            tickPlayer = try AVAudioPlayer(contentsOf: url)
            tickPlayer?.numberOfLoops = -1
            tickPlayer?.volume = 0.4
            tickPlayer?.play()
        } catch {
            print("Tick playback failed: \(error)")
        }
    }
}

#Preview {
    CountdownView()
}
