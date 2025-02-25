//import SwiftUI
//struct UserListView: View {
//    let currentUsername: String
//    @ObservedObject var viewModel = OnlineUsersViewModel()
//    
//    var body: some View {
//        VStack {
//            Text("欢迎, \(currentUsername)")
//                .font(.title)
//                .padding()
//            
//            // 使用 List 来显示实时在线的用户列表
//            List(viewModel.onlineUsers) { user in
//                // 如果用户点击某个在线用户，进入聊天界面
//                NavigationLink(destination: ChatView(currentUsername: currentUsername, targetUser: user.username)) {
//                    HStack {
//                        Text(user.username)
//                        Spacer()
//                        // 在线状态指示器（这里简单用绿色圆点表示在线）
//                        Circle()
//                            .fill(Color.green)
//                            .frame(width: 10, height: 10)
//                    }
//                }
//            }
//        }
//        .navigationTitle("在线用户")
//    }
//}
