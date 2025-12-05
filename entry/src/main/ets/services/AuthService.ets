import { HttpUtil } from '../utils/HttpUtil';
import { ApiConstants } from '../constants/ApiConstants';
import { LoginResponse } from '../models/User';

/**
 * 登录请求参数
 */
class LoginByPasswordParams {
  phone: string = '';
  password: string = '';
}

class LoginBySmsParams {
  phone: string = '';
  code: string = '';
}

class SendSmsParams {
  phone: string = '';
}

/**
 * 认证服务
 */
export class AuthService {
  /**
   * 密码登录
   */
  static async loginByPassword(phone: string, password: string): Promise<LoginResponse> {
    const params = new LoginByPasswordParams();
    params.phone = phone;
    params.password = password;
    return await HttpUtil.post<LoginResponse>(ApiConstants.AUTH_LOGIN_PASSWORD, params, false);
  }

  /**
   * 短信验证码登录
   */
  static async loginBySms(phone: string, code: string): Promise<LoginResponse> {
    const params = new LoginBySmsParams();
    params.phone = phone;
    params.code = code;
    return await HttpUtil.post<LoginResponse>(ApiConstants.AUTH_LOGIN_SMS, params, false);
  }

  /**
   * 发送短信验证码
   */
  static async sendSms(phone: string): Promise<void> {
    const params = new SendSmsParams();
    params.phone = phone;
    await HttpUtil.post<void>(ApiConstants.AUTH_SEND_SMS, params, false);
  }

  /**
   * 登出
   */
  static async logout(): Promise<void> {
    await HttpUtil.post<void>(ApiConstants.AUTH_LOGOUT);
  }
}
