import SwiftUI
import AVFoundation


struct ContentView: View {

    @State private var isPulsing = false
    @State private var isFlickering = false
    @State private var handsFlicker = false
    @State private var glowPulse = false
    @State private var vignetteBreathing = false
    @State private var lilySwaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isMuted = false
    @State private var showMuteLabel = false
    @State private var navigateToRecord = false
    var body: some View {
        ZStack {

            // Base background
            Color.black
                .ignoresSafeArea()

            // Breathing red vignette
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        Color.red.opacity(vignetteBreathing ? 0.18 : 0.06),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: vignetteBreathing ? 520 : 380
                )
                .frame(height: vignetteBreathing ? 500 : 360)
                .animation(
                    .easeInOut(duration: 3.5)
                    .repeatForever(autoreverses: true),
                    value: vignetteBreathing
                )
            }
            .ignoresSafeArea()

            // Scanlines overlay
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

            // Spider lily — independent from VStack, anchored to top
            VStack {
                Image("SpiderLily")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 600)
                    .rotationEffect(.degrees(180))
                    .offset(y: lilySwaying ? -4 : 8)
                    .animation(
                        .easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true),
                        value: lilySwaying
                    )
                    .padding(.top, 40)
                    .overlay(
                        Text(isMuted ? "🔇" : "🔊")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(showMuteLabel ? 0.6 : 0))
                            .padding(.bottom, 12)
                            .animation(.easeInOut(duration: 0.3), value: showMuteLabel),
                        alignment: .bottom
                    )
                    .gesture(
                        LongPressGesture(minimumDuration: 0.6)
                            .onEnded { _ in
                                isMuted.toggle()
                                audioPlayer?.volume = isMuted ? 0.0 : 0.4

                                // show label briefly then hide
                                showMuteLabel = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showMuteLabel = false
                                }
                            }
                    )
                Spacer()
            }
            .ignoresSafeArea()

            // Main content — unaffected by lily size
            VStack(spacing: 0) {

                Spacer().frame(height: 200)

                // Title
                Text("기리고")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.white)
                    .tracking(6)
                    .opacity(isFlickering ? 0.85 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.1)
                        .repeatForever(autoreverses: true),
                        value: isFlickering
                    )

                Spacer().frame(height: 28)

                // Praying hands
                Image("PrayingHands")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 175)
                    .opacity(handsFlicker ? 0.9 : 1.0)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 6.0)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .animation(
                        .easeInOut(duration: 0.15)
                        .repeatForever(autoreverses: true)
                        .delay(0.4),
                        value: handsFlicker
                    )
                    .animation(
                        .easeInOut(duration: 10.5)
                        .repeatForever(autoreverses: true),
                        value: vignetteBreathing
                    )

                Spacer().frame(height: 20)

                // Subtitle
                Text("소원 빌기")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(8)

                Spacer()

                // Warning text
                Text("한번 말하면, 되돌릴 수 없습니다")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.red.opacity(vignetteBreathing ? 0.85 : 0.4))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .animation(
                        .easeInOut(duration: 3.5)
                        .repeatForever(autoreverses: true),
                        value: vignetteBreathing
                    )

                Spacer().frame(height: 16)

                // Button
                Button {
                    navigateToRecord = true// navigate to record screen
                } label: {
                    Text("소원 말하기")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(4)
                        .foregroundColor(.white)
                        .frame(maxWidth: 240)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.85))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: glowPulse ? 4 : 0)
                                .blur(radius: glowPulse ? 1 : 0)
                        )
                }
                .padding(.horizontal, 50)

                Spacer().frame(height: 12)

                // Bottom disclaimer
                Text("앱을 사용함으로써 모든 결과에 동의합니다")
                    . font(.system(size: 9, weight: .light))
                    .foregroundColor(.white.opacity(0.2))
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
            
        }
        .fullScreenCover(isPresented: $navigateToRecord) {
            RecordWishView()
        }
        .onAppear {
            isPulsing = true
            isFlickering = true
            handsFlicker = true
            glowPulse = true
            vignetteBreathing = true
            lilySwaying = true
            playAmbientSound()
        }
    }
    func playAmbientSound() {
            guard let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") else {
                print("Audio file not found")
                return
            }
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = 1  // loop once
                audioPlayer?.volume = 0.3
                // subtle, not overpowering
                audioPlayer?.play()
            } catch {
                print("Audio playback failed: \(error)")
            }
        }
}

#Preview {
    ContentView()
}
