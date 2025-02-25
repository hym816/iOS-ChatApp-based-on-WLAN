import Foundation

class WebSocketManager: NSObject {
    static let shared = WebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL = URL(string: "ws://192.168.1.26:3000")!
    
    private override init() {
        super.init()
    }
    
    func connect() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    /// 发送 JSON 格式的消息
    func send(message: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            if let text = String(data: data, encoding: .utf8) {
                webSocketTask?.send(.string(text)) { error in
                    if let error = error {
                        print("发送消息出错: \(error)")
                    }
                }
            }
        } catch {
            print("消息序列化出错: \(error)")
        }
    }
    
    /// 发送媒体消息方法（支持照片、视频、语音）
    func sendMediaMessage(from: String, to: String, fileType: String, fileName: String, fileData: Data) {
        // 定义每块的最大字节数，例如 64KB
        let chunkSize = 10240 * 1024
        let totalSize = fileData.count
        
        // 生成一个全局唯一的 fileId，用于标识整个媒体文件
        let fileId = UUID().uuidString
        
        // 如果数据较小，直接发送
        if totalSize <= chunkSize {
            let base64String = fileData.base64EncodedString(options: [])
            let message: [String: Any] = [
                "event": "mediaMessage",
                "from": from,
                "to": to,
                "fileType": fileType,
                "fileName": fileName,
                "fileData": base64String,
                "time": Date().timeIntervalSince1970,
                "fileId": fileId,
                "chunkIndex": 0,
                "chunkCount": 1,
                "isLastChunk": true
            ]
            send(message: message)
        } else {
            // 分块发送
            let totalChunks = Int(ceil(Double(totalSize) / Double(chunkSize)))
            for chunkIndex in 0..<totalChunks {
                let start = chunkIndex * chunkSize
                let end = min(start + chunkSize, totalSize)
                let chunkData = fileData.subdata(in: start..<end)
                let base64String = chunkData.base64EncodedString(options: [])
                let message: [String: Any] = [
                    "event": "mediaMessage",
                    "from": from,
                    "to": to,
                    "fileType": fileType,
                    "fileName": fileName,
                    "fileData": base64String,
                    "time": Date().timeIntervalSince1970,
                    "fileId": fileId,
                    "chunkIndex": chunkIndex,
                    "chunkCount": totalChunks,
                    "isLastChunk": (chunkIndex == totalChunks - 1)
                ]
                // 发送每个块
                send(message: message)
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("接收消息失败: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleReceived(text: text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleReceived(text: text)
                    }
                @unknown default:
                    break
                }
            }
            self?.receiveMessage()
        }
    }
    
    private func handleReceived(text: String) {
        print("收到消息：\(text)")
        if let data = text.data(using: .utf8),
           let messageDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let event = messageDict["event"] as? String {
            NotificationCenter.default.post(name: Notification.Name(event), object: nil, userInfo: messageDict)
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("WebSocket 连接成功")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("WebSocketConnected"), object: nil)
        }
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("WebSocket 连接关闭")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("WebSocketDisconnected"), object: nil)
        }
    }
}
