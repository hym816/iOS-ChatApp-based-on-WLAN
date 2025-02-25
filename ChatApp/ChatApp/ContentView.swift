import SwiftUI

struct ContentView: View {
    // 记录服务器连接状态，默认为“未连接”
    @State private var connectionStatus: String = "未连接"
    @State private var username: String = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 显示服务器连接状态
                HStack {
                    Circle()
                        .fill(connectionStatus == "已连接" ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text("服务器连接状态: \(connectionStatus)")
                        .font(.subheadline)
                }
                .padding(.top, 20)
                
                // 当连接状态为“未连接”时显示重新连接按钮
                if connectionStatus == "未连接" {
                    Button(action: {
                        // 重新连接服务器
                        WebSocketManager.shared.connect()
                    }) {
                        Text("重新连接")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }
                
                if isLoggedIn {
                    // 登录后显示真正的在线用户列表
                    UserListView(currentUsername: username)
                } else {
                    // 登录界面
                    Text("欢迎使用聊天应用")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    TextField("请输入用户名", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        // 连接服务器并注册用户名
                        WebSocketManager.shared.connect()
                        let message: [String: Any] = [
                            "event": "register",
                            "username": username
                        ]
                        WebSocketManager.shared.send(message: message)
                        isLoggedIn = true
                    }) {
                        Text("登录")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(username.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(username.isEmpty)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationTitle("聊天应用")
            // 监听 WebSocket 连接成功和断开通知，更新连接状态
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WebSocketConnected"))) { _ in
                connectionStatus = "已连接"
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WebSocketDisconnected"))) { _ in
                connectionStatus = "未连接"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

struct UserListView: View {
    let currentUsername: String
    @ObservedObject var viewModel = OnlineUsersViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("欢迎, \(currentUsername)")
                    .font(.title)
                Spacer()
                Button(action: {
                    // 点击刷新按钮后，发送 refresh 消息给服务器
                    let refreshMessage: [String: Any] = ["event": "refresh"]
                    WebSocketManager.shared.send(message: refreshMessage)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
            .padding()
            
            if viewModel.onlineUsers.isEmpty {
                Text("暂无在线用户")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(viewModel.onlineUsers) { user in
                    NavigationLink(destination: ChatView(currentUsername: currentUsername, targetUser: user.username)) {
                        HStack {
                            Text(user.username)
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("在线用户")
    }
}


import SwiftUI

@main
struct ChatAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
