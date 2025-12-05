import { http } from '@kit.NetworkKit';
import { ApiConstants } from '../constants/ApiConstants';
import { StorageUtil } from './StorageUtil';
import { util } from '@kit.ArkTS';

/**
 * HTTP 请求工具类
 */
export class HttpUtil {
  /**
   * 通用请求方法
   */
  private static async request(
    url: string,
    method: http.RequestMethod,
    params?: Object,
    needToken: boolean = true
  ): Promise<http.HttpResponse> {
    const fullUrl = ApiConstants.BASE_URL + url;
    const httpRequest = http.createHttp();

    try {
      // 构建请求头
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      };

      // 添加 Token
      if (needToken) {
        const token = await StorageUtil.getToken();
        if (token) {
          headers['Authorization'] = `Bearer ${token}`;
        }
      }

      // 发送请求
      const response = await httpRequest.request(fullUrl, {
        method: method,
        header: headers,
        extraData: params ? JSON.stringify(params) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      });

      return response;
    } catch (err) {
      console.error('HttpUtil request failed:', JSON.stringify(err));
      throw new Error('Network request failed');
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 解析响应结果（JSON 格式）
   */
  private static parseResponse<T>(response: http.HttpResponse): T {
    if (response.responseCode !== 200) {
      throw new Error(`HTTP Error: ${response.responseCode}`);
    }

    const result = JSON.parse(response.result as string) as Record<string, Object>;

    // 检查业务状态码
    if (result.code !== 200) {
      throw new Error((result.message as string) || '请求失败');
    }

    return result.data as T;
  }

  /**
   * 解析纯文本响应（用于百炼 Agent）
   */
  private static parseTextResponse(response: http.HttpResponse): string {
    if (response.responseCode !== 200) {
      throw new Error(`HTTP Error: ${response.responseCode}`);
    }

    return response.result as string;
  }

  /**
   * 直接解析 JSON 响应（不包装在 Result 中，用于 /api/v2/chat）
   */
  private static parseDirectResponse<T>(response: http.HttpResponse): T {
    if (response.responseCode !== 200) {
      throw new Error(`HTTP Error: ${response.responseCode}`);
    }

    return JSON.parse(response.result as string) as T;
  }

  /**
   * GET 请求（JSON 响应）
   */
  static async get<T>(url: string, params?: Record<string, Object>, needToken: boolean = true): Promise<T> {
    // 将参数拼接到 URL
    let fullUrl = url;
    if (params) {
      const entries = Object.entries(params);
      const queryParts: string[] = [];
      for (let i = 0; i < entries.length; i++) {
        const key = entries[i][0];
        const value = entries[i][1];
        queryParts.push(`${key}=${encodeURIComponent(String(value))}`);
      }
      fullUrl = `${url}?${queryParts.join('&')}`;
    }

    const response = await HttpUtil.request(fullUrl, http.RequestMethod.GET, undefined, needToken);
    return HttpUtil.parseResponse<T>(response);
  }

  /**
   * GET 请求（纯文本响应，用于百炼 Agent）
   */
  static async getText(url: string, params?: Record<string, Object>, needToken: boolean = true): Promise<string> {
    // 将参数拼接到 URL
    let fullUrl = url;
    if (params) {
      const entries = Object.entries(params);
      const queryParts: string[] = [];
      for (let i = 0; i < entries.length; i++) {
        const key = entries[i][0];
        const value = entries[i][1];
        queryParts.push(`${key}=${encodeURIComponent(String(value))}`);
      }
      fullUrl = `${url}?${queryParts.join('&')}`;
    }

    const response = await HttpUtil.request(fullUrl, http.RequestMethod.GET, undefined, needToken);
    return HttpUtil.parseTextResponse(response);
  }

  /**
   * POST 请求
   */
  static async post<T>(url: string, params?: Object, needToken: boolean = true): Promise<T> {
    const response = await HttpUtil.request(url, http.RequestMethod.POST, params, needToken);
    return HttpUtil.parseResponse<T>(response);
  }

  /**
   * POST 请求（直接解析 JSON，不期望 Result 包装）
   */
  static async postDirect<T>(url: string, params?: Object, needToken: boolean = true): Promise<T> {
    const response = await HttpUtil.request(url, http.RequestMethod.POST, params, needToken);
    return HttpUtil.parseDirectResponse<T>(response);
  }

  /**
   * PUT 请求
   */
  static async put<T>(url: string, params?: Object, needToken: boolean = true): Promise<T> {
    const response = await HttpUtil.request(url, http.RequestMethod.PUT, params, needToken);
    return HttpUtil.parseResponse<T>(response);
  }

  /**
   * DELETE 请求
   */
  static async delete<T>(url: string, needToken: boolean = true): Promise<T> {
    const response = await HttpUtil.request(url, http.RequestMethod.DELETE, undefined, needToken);
    return HttpUtil.parseResponse<T>(response);
  }

  /**
   * SSE 流式请求（用于流式聊天）
   */
  static async streamRequest(
    url: string,
    params: Record<string, Object>,
    onMessage: (data: string) => void,
    onComplete: () => void,
    onError: (error: Error) => void
  ): Promise<void> {
    const fullUrl = ApiConstants.BASE_URL + url;
    const httpRequest = http.createHttp();

    try {
      // 构建请求头
      const headers: Record<string, string> = {
        'Accept': 'text/event-stream'
      };

      const token = await StorageUtil.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      // 将参数拼接到 URL（GET 请求）
      const entries = Object.entries(params);
      const queryParts: string[] = [];
      for (let i = 0; i < entries.length; i++) {
        const key = entries[i][0];
        const value = entries[i][1];
        queryParts.push(`${key}=${encodeURIComponent(String(value))}`);
      }
      const requestUrl = `${fullUrl}?${queryParts.join('&')}`;

      // 监听数据接收事件
      httpRequest.on('dataReceive', (data: ArrayBuffer) => {
        try {
          const textDecoder = util.TextDecoder.create('utf-8');
          const text = textDecoder.decodeWithStream(new Uint8Array(data), { stream: false });
          
          // 解析 SSE 格式：data: xxx\n\n
          const lines = text.split('\n');
          for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.startsWith('data: ')) {
              const content = line.substring(6).trim();
              if (content && content !== '[DONE]') {
                onMessage(content);
              }
            }
          }
        } catch (err) {
          console.error('Parse SSE data failed:', JSON.stringify(err));
        }
      });

      // 监听完成事件
      httpRequest.on('dataEnd', () => {
        onComplete();
        httpRequest.destroy();
      });

      // 发送请求
      await httpRequest.request(requestUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 60000,
        readTimeout: 60000
      });

    } catch (err) {
      console.error('HttpUtil streamRequest failed:', JSON.stringify(err));
      onError(new Error('Stream request failed'));
      httpRequest.destroy();
    }
  }
}
