import SwiftUI
import AVFoundation

struct VoiceRecorderView: View {
    @Binding var audioURL: URL?
    @State private var isRecording = false
    @State private var recorder: AVAudioRecorder?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isRecording ? "录音中..." : "未录音")
                .font(.title2)
            Button(action: {
                if isRecording {
                    recorder?.stop()
                    isRecording = false
                } else {
                    startRecording()
                }
            }) {
                Text(isRecording ? "停止录音" : "开始录音")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    func startRecording() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFile = documents.appendingPathComponent("recordedVoice.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            recorder = try AVAudioRecorder(url: audioFile, settings: settings)
            recorder?.record()
            isRecording = true
            audioURL = audioFile
        } catch {
            print("启动录音失败: \(error)")
        }
    }
}
