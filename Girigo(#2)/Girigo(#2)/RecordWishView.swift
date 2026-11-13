import SwiftUI
import AVFoundation

struct RecordWishView: View {

    @Environment(\.dismiss) var dismiss

    @State private var isRecording = false
    @State private var isPulsing = false
    @State private var navigateToCountdown = false
    @State private var permissionDenied = false
    @State private var secondsRecorded = 0
    @State private var timer: Timer?
    @State private var showConfirmation = false

    @State private var recorder = VideoRecorder()

    var body: some View {
        ZStack {

            // Camera feed — full screen
            CameraPreview(recorder: recorder)
                .ignoresSafeArea()

            // Dark overlay
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Top fade
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                Spacer()
            }
            .ignoresSafeArea()

            // Bottom fade
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
            }
            .ignoresSafeArea()

            // Main UI
            VStack {

                Spacer()

                // Timer
                Text(isRecording ? timeString(secondsRecorded) : " ")
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(6)
                    .monospacedDigit()

                Spacer().frame(height: 28)

                // Record button
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                        )
                        .overlay(
                            Group {
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.red)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 28, height: 28)
                                }
                            }
                        )
                        .onTapGesture {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }
                }

                Spacer().frame(height: 50)

                Button {
                    dismiss()
                } label: {
                    Text("돌아가기")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.white.opacity(0.2))
                        .tracking(4)
                }

                Spacer().frame(height: 44)
            }

            // Permission denied
            if permissionDenied {
                VStack {
                    Spacer()
                    Text("카메라 및 마이크 접근 권한이 필요합니다")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.red.opacity(0.7))
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 120)
                }
            }

            // Confirmation overlay
            if showConfirmation {
                ZStack {
                    // Blurred dark backdrop
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VStack(spacing: 0) {

                        // Praying hands
                        Image("PrayingHands")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 75)
                            .padding(.bottom, 24)

                        // Title
                        Text("소원을 바치시겠습니까?")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 12)

                        // Subtitle
                        Text("한번 바치면\n되돌릴 수 없습니다")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.45))
                            .tracking(2)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Spacer().frame(height: 40)

                        // Confirm button
                        Button(action: {
                            showConfirmation = false
                            scheduleWishNotification()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                                navigateToCountdown = true
                            }
                        }) {
                            Text("바칩니다")
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(4)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.red.opacity(0.85))
                                )
                        }

                        Spacer().frame(height: 12)

                        // Cancel — re-record
                        Button {
                            showConfirmation = false
                            // Delete the last recording so they can re-record
                            recorder.deleteLastRecording()
                        } label: {
                            Text("다시 말하기")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(4)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 44)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showConfirmation)
            }
        }
        .onAppear {
            isPulsing = true
            recorder.setupSession { granted in
                if !granted { permissionDenied = true }
            }
        }
        .onDisappear {
            recorder.stopSession()
        }
        .fullScreenCover(isPresented: $navigateToCountdown) {
            CountdownView()
        }
    }

    // MARK: - Actions

    func startRecording() {
        recorder.startRecording()
        isRecording = true
        secondsRecorded = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            secondsRecorded += 1
        }
    }

    func stopRecording() {
        recorder.stopRecording()
        timer?.invalidate()
        isRecording = false
        // Show confirmation instead of going straight to countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showConfirmation = true
        }
    }
    func scheduleWishNotification() {
        let content = UNMutableNotificationContent()
        content.title = "기리고"
        content.body = "소원이 접수되었습니다"
        content.sound = .default

        // 5 second spooky delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "wishGranted", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let recorder: VideoRecorder

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        view.recorder = recorder
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.recorder = recorder
    }
}

class PreviewUIView: UIView {
    var recorder: VideoRecorder? {
        didSet { setupPreview() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update preview layer frame whenever layout changes
        recorder?.previewLayer?.frame = bounds
    }

    func setupPreview() {
        guard let previewLayer = recorder?.previewLayer else { return }
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.insertSublayer(previewLayer, at: 0)
    }
}

// MARK: - Video Recorder

class VideoRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {

    var session: AVCaptureSession?
    var movieOutput = AVCaptureMovieFileOutput()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var lastRecordingURL: URL?
    
    func setupSession(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { videoGranted in
            guard videoGranted else { completion(false); return }

            AVAudioApplication.requestRecordPermission { audioGranted in
                guard audioGranted else { completion(false); return }

                DispatchQueue.main.async {
                    self.configureSession()
                    completion(true)
                }
            }
        }
    }

    func configureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)

        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              session.canAddInput(audioInput) else { return }
        session.addInput(audioInput)

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        // Create preview layer and attach session
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.previewLayer = previewLayer
        self.session = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            Thread.sleep(forTimeInterval: 0.3)
            DispatchQueue.main.async {
                print("Session is running: \(session.isRunning)")
            }
        }
    }

    func startRecording() {
        guard let session = session, session.isRunning else { return }
        guard !movieOutput.isRecording else { return }

        let filename = getDocumentsDirectory()
            .appendingPathComponent("wish_\(Date().timeIntervalSince1970).mov")
        lastRecordingURL = filename

        DispatchQueue.global(qos: .userInitiated).async {
            self.movieOutput.startRecording(to: filename, recordingDelegate: self)
        }
    }

    func stopRecording() {
        movieOutput.stopRecording()
    }

    func stopSession() {
        session?.stopRunning()
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
        } else {
            print("Saved to: \(outputFileURL)")
        }
    }
    func deleteLastRecording() {
        guard let url = lastRecordingURL else { return }
        try? FileManager.default.removeItem(at: url)
        lastRecordingURL = nil
    }
    
    
}
#Preview {
    RecordWishView()
}
