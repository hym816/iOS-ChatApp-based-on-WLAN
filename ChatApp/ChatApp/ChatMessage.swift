import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let from: String
    /// 文本消息内容（如果为媒体消息，则此值为 nil）
    let text: String?
    /// 媒体类型，如 "photo", "video", "voice"
    let fileType: String?
    /// 媒体文件名称
    let fileName: String?
    /// 媒体数据（解码自 Base64 字符串）
    let fileData: Data?
    let time: Date
}

