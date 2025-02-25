import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    let currentUsername: String
    let targetUser: String
    private var cancellables = Set<AnyCancellable>()
    
    init(currentUsername: String, targetUser: String) {
        self.currentUsername = currentUsername
        self.targetUser = targetUser
        // 监听文本消息与媒体消息通知
        NotificationCenter.default.publisher(for: Notification.Name("privateMessage"))
            .merge(with: NotificationCenter.default.publisher(for: Notification.Name("mediaMessage")))
            .sink { [weak self] notification in
                self?.handleMessageNotification(notification)
            }
            .store(in: &cancellables)
    }
    
    func startListening() {
        // 此处可以添加其他初始化监听逻辑
    }
    
    private func handleMessageNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let newMessage = parseMessage(from: userInfo) else { return }
        // 仅添加当前聊天会话相关的消息
        if (newMessage.from == targetUser || newMessage.from == currentUsername) {
            DispatchQueue.main.async {
                self.messages.append(newMessage)
            }
        }
    }
    
    private func parseMessage(from dict: [String: Any]) -> ChatMessage? {
        guard let from = dict["from"] as? String,
              let timestamp = dict["time"] as? TimeInterval else { return nil }
        let time = Date(timeIntervalSince1970: timestamp)
        
        if let fileType = dict["fileType"] as? String,
           let base64String = dict["fileData"] as? String,
           let data = Data(base64Encoded: base64String) {
            let fileName = dict["fileName"] as? String
            return ChatMessage(from: from, text: nil, fileType: fileType, fileName: fileName, fileData: data, time: time)
        } else if let content = dict["content"] as? String {
            return ChatMessage(from: from, text: content, fileType: nil, fileName: nil, fileData: nil, time: time)
        }
        return nil
    }
}
