import SwiftUI
import AVKit

struct ChatView: View {
    let currentUsername: String
    let targetUser: String
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var messageText: String = ""
    
    // 状态变量用于媒体操作
    @State private var showingImagePicker = false
    @State private var showingVideoPicker = false
    @State private var showingVoiceRecorder = false
    @State private var selectedImage: UIImage?
    @State private var selectedVideoURL: URL?
    @State private var recordedAudioURL: URL?
    
    init(currentUsername: String, targetUser: String) {
        self.currentUsername = currentUsername
        self.targetUser = targetUser
        self.chatViewModel = ChatViewModel(currentUsername: currentUsername, targetUser: targetUser)
    }
    
    var body: some View {
        VStack {
            List(chatViewModel.messages) { msg in
                HStack {
                    if msg.from == currentUsername {
                        Spacer()
                        messageBubble(for: msg)
                    } else {
                        messageBubble(for: msg)
                        Spacer()
                    }
                }
            }
            
            // 文本输入区域
            HStack {
                TextField("输入消息...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("发送") { sendTextMessage() }
            }
            .padding()
            
            // 媒体发送按钮
            HStack {
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.title)
                }
                .padding()
                
                Button(action: { showingVideoPicker = true }) {
                    Image(systemName: "video")
                        .font(.title)
                }
                .padding()
                
                Button(action: { showingVoiceRecorder = true }) {
                    Image(systemName: "mic")
                        .font(.title)
                }
                .padding()
            }
        }
        .navigationTitle("与 \(targetUser) 聊天")
        .onAppear { chatViewModel.startListening() }
        // 图片选择器
        .sheet(isPresented: $showingImagePicker, onDismiss: {
            if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                sendMediaMessage(fileType: "photo", fileName: "photo.jpg", data: imageData)
            }
        }) {
            ImagePicker(image: $selectedImage)
        }
        // 视频选择器
        .sheet(isPresented: $showingVideoPicker, onDismiss: {
            if let url = selectedVideoURL, let videoData = try? Data(contentsOf: url) {
                sendMediaMessage(fileType: "video", fileName: "video.mov", data: videoData)
            }
        }) {
            VideoPicker(videoURL: $selectedVideoURL)
        }
        // 语音录制器
        .sheet(isPresented: $showingVoiceRecorder, onDismiss: {
            if let audioURL = recordedAudioURL, let audioData = try? Data(contentsOf: audioURL) {
                sendMediaMessage(fileType: "voice", fileName: "voice.m4a", data: audioData)
            }
        }) {
            VoiceRecorderView(audioURL: $recordedAudioURL)
        }
    }
    
    func messageBubble(for msg: ChatMessage) -> some View {
        VStack(alignment: .leading) {
            if let text = msg.text {
                Text(text)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            } else if let fileType = msg.fileType {
                if fileType == "photo", let data = msg.fileData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .cornerRadius(8)
                } else if fileType == "video", let data = msg.fileData {
                    if let url = saveDataToTemporaryFile(data: data, withExtension: "mov") {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 200)
                    } else {
                        Text("无法播放视频")
                    }
                } else if fileType == "voice", let data = msg.fileData {
                    VoiceMessageView(audioData: data)
                }
            }
            Text(msg.time, style: .time)
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    func saveDataToTemporaryFile(data: Data, withExtension ext: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("保存临时文件出错: \(error)")
            return nil
        }
    }
    
    func sendTextMessage() {
        guard !messageText.isEmpty else { return }
        let msg: [String: Any] = [
            "event": "privateMessage",
            "from": currentUsername,
            "to": targetUser,
            "content": messageText,
            "time": Date().timeIntervalSince1970
        ]
        WebSocketManager.shared.send(message: msg)
        messageText = ""
    }
    
    func sendMediaMessage(fileType: String, fileName: String, data: Data) {
        WebSocketManager.shared.sendMediaMessage(from: currentUsername,
                                                 to: targetUser,
                                                 fileType: fileType,
                                                 fileName: fileName,
                                                 fileData: data)
    }
}

// 播放语音消息的简单视图
struct VoiceMessageView: View {
    let audioData: Data
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            if isPlaying {
                audioPlayer?.stop()
                isPlaying = false
            } else {
                playAudio()
            }
        }) {
            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                .padding()
        }
    }
    
    func playAudio() {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("播放音频失败: \(error)")
        }
    }
}
