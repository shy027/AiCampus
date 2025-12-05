/**
 * 消息模型
 */
export class Message {
  id?: number;
  sessionId?: number;
  userId?: number;
  role?: string; // 'user' | 'ai' | 'system'
  content?: string;
  modelName?: string;
  createTime?: string;
  isStreaming?: boolean; // 前端使用：标记是否正在流式输出

  constructor(data?: Message) {
    if (data) {
      this.id = data.id;
      this.sessionId = data.sessionId;
      this.userId = data.userId;
      this.role = data.role;
      this.content = data.content;
      this.modelName = data.modelName;
      this.createTime = data.createTime;
      this.isStreaming = data.isStreaming;
    }
  }
}
