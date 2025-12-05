/**
 * 会话模型
 */
export class Session {
  id?: number;
  title?: string;
  userId?: number;
  modelName?: string;
  createTime?: string;
  updateTime?: string;

  constructor(data?: Session) {
    if (data) {
      this.id = data.id;
      this.title = data.title;
      this.userId = data.userId;
      this.modelName = data.modelName;
      this.createTime = data.createTime;
      this.updateTime = data.updateTime;
    }
  }
}
