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
    let buffer = '';
    const textDecoder = util.TextDecoder.create('utf-8');

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
   * SSE 流式请求（改为普通请求后模拟流式）
   * 参考 Aiask 项目实现：请求完整响应 -> 前端模拟打字机效果
   * 这种方式在鸿蒙 NEXT 上兼容性最好，避免了 buffering 问题
   */
  /**
   * SSE 流式请求
   * 注意：鸿蒙的HTTP模块会等待请求完成后才返回，无法实现真正的流式接收
   * 因此我们从response.result中获取完整数据，然后模拟流式输出效果
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

    console.info('[SSE] 开始流式请求:', fullUrl);
    console.info('[SSE] 请求参数:', JSON.stringify(params));

    try {
      const headers: Record<string, string> = {
        'Accept': 'text/event-stream',
        'Content-Type': 'application/json'
      };

      const token = await StorageUtil.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      // 发送请求
      console.info('[SSE] 发送HTTP请求');
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(params),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      });

      console.info('[SSE] 请求完成，状态码:', response.responseCode);

      if (response.responseCode === 200) {
        const responseText = response.result as string;
        console.info('[SSE] 收到响应数据，总长度:', responseText.length);
        console.debug('[SSE] 响应内容:', responseText);

        // 解析SSE格式的响应
        const lines = responseText.split('\n');
        let dataChunks: string[] = [];

        for (const line of lines) {
          const trimmedLine = line.trim();
          if (trimmedLine.length === 0) continue;

          console.debug('[SSE] 处理行:', trimmedLine);

          if (trimmedLine.startsWith('data:')) {
            let content = trimmedLine.substring(5);
            // 去除 data: 后可能存在的首个空格
            if (content.startsWith(' ')) {
              content = content.substring(1);
            }

            console.debug('[SSE] 提取内容:', content);

            if (content && content !== '[DONE]') {
              dataChunks.push(content);
            } else if (content === '[DONE]') {
              console.info('[SSE] 收到结束标记 [DONE]');
            }
          }
        }

        console.info('[SSE] 解析完成，共', dataChunks.length, '个数据块');

        // 模拟流式输出效果：逐个发送数据块
        if (dataChunks.length > 0) {
          console.info('[SSE] 准备调用onMessage回调，回调类型:', typeof onMessage);
          for (let i = 0; i < dataChunks.length; i++) {
            const chunk = dataChunks[i];
            console.info('[SSE] 发送数据块', i + 1, '/', dataChunks.length, '长度:', chunk.length);
            console.info('[SSE] 即将调用onMessage，数据:', chunk);
            try {
              onMessage(chunk);
              console.info('[SSE] onMessage调用成功');
            } catch (err) {
              console.error('[SSE] onMessage调用失败:', JSON.stringify(err));
            }
            
            // 添加小延迟模拟流式效果（15ms = 更快的打字速度）
            if (i < dataChunks.length - 1) {
              await new Promise<void>((resolve) => setTimeout(resolve, 50));
            }
          }
        } else {
          console.warn('[SSE] 未找到任何数据块');
        }

        console.info('[SSE] 流式请求成功完成');
        onComplete();
      } else {
        console.error('[SSE] HTTP错误，状态码:', response.responseCode);
        onError(new Error(`HTTP Error: ${response.responseCode}`));
      }

    } catch (err) {
      console.error('[SSE] 流式请求失败:', JSON.stringify(err));
      onError(new Error('Stream request failed'));
    } finally {
      httpRequest.destroy();
      console.info('[SSE] HTTP连接已关闭');
    }
  }
}
