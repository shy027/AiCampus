/**
 * API 常量配置
 */
export class ApiConstants {
  // 基础地址
  static readonly BASE_URL: string = 'http://10.0.2.2:8080';

  // 认证相关接口
  static readonly AUTH_LOGIN_PASSWORD: string = '/api/auth/login/password';
  static readonly AUTH_LOGIN_SMS: string = '/api/auth/login/sms';
  static readonly AUTH_SEND_SMS: string = '/api/auth/send-sms';
  static readonly AUTH_LOGOUT: string = '/api/auth/logout';

  // 用户相关接口
  static readonly USER_INFO: string = '/api/user';
  static readonly USER_BY_ID: string = '/api/user/{id}';
  static readonly USER_BY_PHONE: string = '/api/user/phone/{phone}';
  static readonly USER_UPDATE: string = '/api/user';
  static readonly USER_AVATAR: string = '/api/user/avatar';

  // 会话相关接口
  static readonly SESSION_CREATE: string = '/api/session';
  static readonly SESSION_LIST: string = '/api/session';
  static readonly SESSION_DETAIL: string = '/api/session/{id}';
  static readonly SESSION_UPDATE_TITLE: string = '/api/session/{id}/title';
  static readonly SESSION_DELETE: string = '/api/session/{id}';
  static readonly SESSION_MESSAGES: string = '/api/session/{id}/messages';

  // AI 对话接口（v2）
  static readonly CHAT_API: string = '/api/v2/chat';
  static readonly CHAT_STREAM_API: string = '/api/v2/chat/stream';

  // 百炼 Agent 接口
  static readonly BAILIAN_AGENT_CALL: string = '/ai/bailian/agent/call';
  static readonly BAILIAN_AGENT_STREAM: string = '/ai/bailian/agent/stream';

  // 本地存储键名
  static readonly STORAGE_TOKEN: string = 'token';
  static readonly STORAGE_USER_ID: string = 'userId';
  static readonly STORAGE_USER_INFO: string = 'userInfo';
}
