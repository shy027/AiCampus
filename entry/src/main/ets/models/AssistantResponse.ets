/**
 * AI 响应模型
 */
export class AssistantResponse {
  userId?: string;
  threadId?: string;
  sessionId?: number;
  answer?: string;
  suggestion?: string;
  type?: string;
  needsFurtherHelp?: boolean;

  constructor(data?: AssistantResponse) {
    if (data) {
      this.userId = data.userId;
      this.threadId = data.threadId;
      this.sessionId = data.sessionId;
      this.answer = data.answer;
      this.suggestion = data.suggestion;
      this.type = data.type;
      this.needsFurtherHelp = data.needsFurtherHelp;
    }
  }
}
