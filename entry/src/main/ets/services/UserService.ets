import { HttpUtil } from '../utils/HttpUtil';
import { ApiConstants } from '../constants/ApiConstants';
import { User } from '../models/User';

/**
 * 更新用户信息请求参数
 */
class UpdateUserRequest {
  username?: string;
  email?: string;
  password?: string;
}

/**
 * 用户服务
 */
export class UserService {
  /**
   * 获取用户信息
   */
  static async getUserInfo(userId: number): Promise<User> {
    const url = ApiConstants.USER_BY_ID.replace('{id}', userId.toString());
    return await HttpUtil.get<User>(url);
  }

  /**
   * 更新用户信息
   */
  static async updateUserInfo(username?: string, email?: string, password?: string): Promise<User> {
    const params = new UpdateUserRequest();
    if (username) {
      params.username = username;
    }
    if (email) {
      params.email = email;
    }
    if (password) {
      params.password = password;
    }
    return await HttpUtil.put<User>(ApiConstants.USER_UPDATE, params);
  }
}
