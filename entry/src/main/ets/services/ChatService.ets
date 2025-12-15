import { HttpUtil } from '../utils/HttpUtil';
import { ApiConstants } from '../constants/ApiConstants';
import { AssistantResponse } from '../models/AssistantResponse';

/**
 * 聊天请求参数
 */
class ChatRequestParams {
  userId: string = '';
  message: string = '';
  sessionId?: number;
}

/**
 * 聊天服务
 */
export class ChatService {
  /**
   * 调用 AI 对话接口（非流式）
   */
  static async chat(userId: string, message: string, agentType: string, sessionId?: number): Promise<AssistantResponse> {
    const params = new ChatRequestParams();
    params.userId = userId;
    params.message = message;
    if (sessionId) {
      params.sessionId = sessionId;
    }
    const path = ApiConstants.AGENT_CHAT_API.replace('{type}', agentType);
    // 使用 postDirect 因为接口直接返回 AssistantResponse，不包装在 Result 中
    return await HttpUtil.postDirect<AssistantResponse>(path, params);
  }

  /**
   * 调用 AI 对话接口（流式）
   */
  static async chatStream(
    userId: string,
    message: string,
    agentType: string,
    sessionId: number | undefined,
    onMessage: (data: string) => void,
    onComplete: () => void,
    onError: (error: Error) => void
  ): Promise<void> {
    const params: Record<string, Object> = {
      'userId': userId,
      'message': message
    };
    if (sessionId) {
      params['sessionId'] = sessionId;
    }
    const path = ApiConstants.AGENT_CHAT_STREAM_API.replace('{type}', agentType);
    await HttpUtil.streamRequest(
      path,
      params,
      onMessage,
      onComplete,
      onError
    );
  }
}
