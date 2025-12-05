/**
 * 用户信息模型
 */
export class User {
  id?: number;
  username?: string;
  email?: string;
  phone?: string;
  avatar?: string;
  status?: number;
  lastLoginTime?: string;
  createTime?: string;
  updateTime?: string;

  constructor(data?: User) {
    if (data) {
      this.id = data.id;
      this.username = data.username;
      this.email = data.email;
      this.phone = data.phone;
      this.avatar = data.avatar;
      this.status = data.status;
      this.lastLoginTime = data.lastLoginTime;
      this.createTime = data.createTime;
      this.updateTime = data.updateTime;
    }
  }
}

/**
 * 登录响应模型
 */
export class LoginResponse {
  token?: string;
  userId?: number;
  username?: string;
  phone?: string;
  avatar?: string;

  constructor(data?: LoginResponse) {
    if (data) {
      this.token = data.token;
      this.userId = data.userId;
      this.username = data.username;
      this.phone = data.phone;
      this.avatar = data.avatar;
    }
  }
}
