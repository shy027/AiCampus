import { HttpUtil } from '../utils/HttpUtil';
import { ApiConstants } from '../constants/ApiConstants';
import { Session } from '../models/Session';
import { Message } from '../models/Message';

/**
 * 请求参数类
 */
class CreateSessionParams {
  userId: number = 0;
}

class UpdateTitleParams {
  title: string = '';
}

/**
 * 会话服务
 */
export class SessionService {
  /**
   * 创建会话
   */
  static async createSession(userId: number): Promise<Session> {
    const params = new CreateSessionParams();
    params.userId = userId;
    return await HttpUtil.post<Session>(ApiConstants.SESSION_CREATE, params);
  }

  /**
   * 查询会话列表
   */
  static async getSessionList(userId: number): Promise<Session[]> {
    const params: Record<string, Object> = { 'userId': userId };
    return await HttpUtil.get<Session[]>(ApiConstants.SESSION_LIST, params);
  }

  /**
   * 查询会话详情
   */
  static async getSessionDetail(id: number): Promise<Session> {
    const url = ApiConstants.SESSION_DETAIL.replace('{id}', id.toString());
    return await HttpUtil.get<Session>(url);
  }

  /**
   * 修改会话标题
   */
  static async updateSessionTitle(id: number, title: string): Promise<Session> {
    const url = ApiConstants.SESSION_UPDATE_TITLE.replace('{id}', id.toString());
    const params = new UpdateTitleParams();
    params.title = title;
    return await HttpUtil.put<Session>(url, params);
  }

  /**
   * 删除会话
   */
  static async deleteSession(id: number): Promise<void> {
    const url = ApiConstants.SESSION_DELETE.replace('{id}', id.toString());
    await HttpUtil.delete<void>(url);
  }

  /**
   * 查询会话消息历史
   */
  static async getSessionMessages(id: number): Promise<Message[]> {
    const url = ApiConstants.SESSION_MESSAGES.replace('{id}', id.toString());
    return await HttpUtil.get<Message[]>(url);
  }
}
