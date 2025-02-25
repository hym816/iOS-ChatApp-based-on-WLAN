// server-purews.js

const WebSocket = require('ws');
const fs = require('fs');

const PORT = 3000;

// 创建纯 WebSocket 服务器，监听所有网络接口
const wss = new WebSocket.Server({ port: PORT, host: '0.0.0.0' }, () => {
  console.log(`纯 WebSocket 服务器已启动，正在监听端口 ${PORT}`);
});

// 用 Map 管理在线用户，key 为 ws 对象，value 为 { username: string }
const onlineUsers = new Map();

// 用于缓存媒体消息块，key 为 fileId，value 为 { chunks: Array, received: number, total: number, baseMessage: Object }
const mediaChunks = {};

// 定义聊天记录文件路径
const CHAT_RECORDS_FILE = 'chatRecords.json';
if (!fs.existsSync(CHAT_RECORDS_FILE)) {
  fs.writeFileSync(CHAT_RECORDS_FILE, JSON.stringify([]));
}

/**
 * 保存聊天记录到文件中
 */
function saveChatRecord(record) {
  fs.readFile(CHAT_RECORDS_FILE, (err, data) => {
    if (err) {
      console.error('读取聊天记录文件出错:', err);
      return;
    }
    let records = [];
    try {
      records = JSON.parse(data);
    } catch (e) {
      console.error('解析聊天记录文件出错:', e);
    }
    records.push(record);
    fs.writeFile(CHAT_RECORDS_FILE, JSON.stringify(records, null, 2), (err) => {
      if (err) {
        console.error('写入聊天记录文件出错:', err);
      }
    });
  });
}

/**
 * 广播在线用户列表
 */
function broadcastOnlineUsers() {
  const userList = Array.from(onlineUsers.values()).map(user => ({ username: user.username }));
  const message = JSON.stringify({ event: 'onlineUsers', data: userList });
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// 处理接收到的媒体消息（重组分块）
function handleMediaMessage(msg, ws) {
  // 如果没有分块字段，则直接处理
  if (!msg.chunkCount || msg.chunkCount <= 1) {
    processCompleteMediaMessage(msg, ws);
    return;
  }
  
  const fileId = msg.fileId;
  if (!mediaChunks[fileId]) {
    // 初始化缓存
    mediaChunks[fileId] = {
      chunks: [],
      received: 0,
      total: msg.chunkCount,
      baseMessage: msg  // 其他通用字段，如 from、to、fileType、fileName、time
    };
  }
  // 存储当前块（确保按 chunkIndex 存储）
  mediaChunks[fileId].chunks[msg.chunkIndex] = msg.fileData;
  mediaChunks[fileId].received++;

  // 检查是否接收到所有块
  if (mediaChunks[fileId].received === msg.chunkCount) {
    // 将所有块拼接成完整的 Base64 字符串
    const fullBase64 = mediaChunks[fileId].chunks.join('');
    // 更新消息
    const completeMsg = Object.assign({}, mediaChunks[fileId].baseMessage, { fileData: fullBase64 });
    // 删除缓存
    delete mediaChunks[fileId];
    // 处理完整的媒体消息
    processCompleteMediaMessage(completeMsg, ws);
  }
}

// 处理完整媒体消息：保存记录并转发给目标用户
function processCompleteMediaMessage(msg, ws) {
  // 保存聊天记录
  saveChatRecord(msg);
  // 转发给目标用户
  onlineUsers.forEach((user, client) => {
    if (user.username === msg.to && client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(msg));
    }
  });
  // 返回给发送方
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

wss.on('connection', (ws) => {
  console.log('新客户端已连接');

  ws.on('message', (message) => {
    console.log('收到消息:', message);
    let msg;
    try {
      msg = JSON.parse(message);
    } catch (e) {
      console.error('消息格式错误:', e);
      return;
    }
    
    if (!msg.event) {
      console.error('消息缺少 event 字段');
      return;
    }

    switch (msg.event) {
      case 'register':
        if (msg.username) {
          onlineUsers.set(ws, { username: msg.username });
          console.log(`用户 ${msg.username} 已注册`);
          broadcastOnlineUsers();
        }
        break;
      
      case 'privateMessage':
        saveChatRecord(msg);
        onlineUsers.forEach((user, client) => {
          if (user.username === msg.to && client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(msg));
          }
        });
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(msg));
        }
        break;
      
      case 'mediaMessage':
        // 根据是否有分块信息判断是否需要重组
        if (msg.chunkCount && msg.chunkCount > 1) {
          handleMediaMessage(msg, ws);
        } else {
          processCompleteMediaMessage(msg, ws);
        }
        break;
      
      case 'loadHistory':
        fs.readFile(CHAT_RECORDS_FILE, (err, fileData) => {
          if (err) {
            console.error('读取聊天记录文件出错:', err);
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(JSON.stringify({ event: 'history', data: [] }));
            }
            return;
          }
          let records = [];
          try {
            records = JSON.parse(fileData);
          } catch (e) {
            console.error('解析聊天记录文件出错:', e);
          }
          const currentUser = onlineUsers.get(ws) ? onlineUsers.get(ws).username : null;
          const history = records.filter(record =>
            ((record.from === msg.withUser || record.to === msg.withUser) &&
             (record.from === currentUser || record.to === currentUser))
          );
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ event: 'history', data: history }));
          }
        });
        break;
      
      case 'refresh':
        broadcastOnlineUsers();
        break;
      
      default:
        console.error('未知的事件类型:', msg.event);
        break;
    }
  });
  
  ws.on('close', () => {
    console.log('客户端断开连接');
    onlineUsers.delete(ws);
    broadcastOnlineUsers();
  });
  
  ws.on('error', (err) => {
    console.error('连接错误:', err);
  });
});
