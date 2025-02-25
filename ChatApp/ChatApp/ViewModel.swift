import SwiftUI
import Combine

// MARK: - 在线用户模型
import Foundation

struct OnlineUser: Identifiable {
    var id: String { username }  // 使用 username 作为唯一标识符（假设用户名唯一）
    let username: String
}


// MARK: - 在线用户列表 ViewModel
import Foundation
import Combine

class OnlineUsersViewModel: ObservableObject {
    @Published var onlineUsers: [OnlineUser] = []
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleOnlineUsers(notification:)),
                                               name: Notification.Name("onlineUsers"),
                                               object: nil)
    }
    
    @objc func handleOnlineUsers(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        if let usersArray = userInfo["data"] as? [[String: Any]] {
            let users = usersArray.compactMap { dict -> OnlineUser? in
                if let username = dict["username"] as? String {
                    return OnlineUser(username: username)
                }
                return nil
            }
            DispatchQueue.main.async {
                self.onlineUsers = users
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}





// MARK: - 聊天 ViewModel
import Foundation
import Combine

//class ChatViewModel: ObservableObject {
//    @Published var messages: [ChatMessage] = []
//    let currentUsername: String
//    let targetUser: String
//    private var cancellables = Set<AnyCancellable>()
//    
//    init(currentUsername: String, targetUser: String) {
//        self.currentUsername = currentUsername
//        self.targetUser = targetUser
//        // 监听文本消息和媒体消息
//        NotificationCenter.default.publisher(for: Notification.Name("privateMessage"))
//            .merge(with: NotificationCenter.default.publisher(for: Notification.Name("mediaMessage")))
//            .sink { [weak self] notification in
//                self?.handleMessageNotification(notification)
//            }
//            .store(in: &cancellables)
//    }
//    
//    func startListening() {
//        // 如有需要，可在此处启动更多监听逻辑
//    }
//    
//    private func handleMessageNotification(_ notification: Notification) {
//        guard let userInfo = notification.userInfo as? [String: Any],
//              let newMessage = parseMessage(from: userInfo) else {
//            return
//        }
//        // 仅添加与当前聊天相关的消息（发送方或接收方为 targetUser 或 currentUsername）
//        if (newMessage.from == targetUser || newMessage.from == currentUsername) {
//            DispatchQueue.main.async {
//                self.messages.append(newMessage)
//            }
//        }
//    }
//    
//    // 解析 JSON 字典构造 ChatMessage
//    private func parseMessage(from dict: [String: Any]) -> ChatMessage? {
//        guard let from = dict["from"] as? String,
//              let timestamp = dict["time"] as? TimeInterval else {
//            return nil
//        }
//        let time = Date(timeIntervalSince1970: timestamp)
//        
//        // 判断是否为媒体消息
//        if let fileType = dict["fileType"] as? String,
//           let base64String = dict["fileData"] as? String,
//           let data = Data(base64Encoded: base64String) {
//            let fileName = dict["fileName"] as? String
//            return ChatMessage(from: from, text: nil, fileType: fileType, fileName: fileName, fileData: data, time: time)
//        } else if let content = dict["content"] as? String {
//            return ChatMessage(from: from, text: content, fileType: nil, fileName: nil, fileData: nil, time: time)
//        }
//        return nil
//    }
//}

