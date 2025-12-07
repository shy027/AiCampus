import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ChatService } from '../services/ChatService';
import { SessionService } from '../services/SessionService';
import { StorageUtil } from '../utils/StorageUtil';
import { Message } from '../models/Message';
import { LoginResponse } from '../models/User';
import { AssistantResponse } from '../models/AssistantResponse';

@Entry
@Component
struct ChatPage {
  @State messages: Message[] = [];
  @State inputText: string = '';
  @State isStreaming: boolean = true; // 是否使用流式输出
  @State isLoading: boolean = false;
  @State userInfo: LoginResponse | null = null;
  @State sessionId: number | undefined = undefined; // 当前会话 ID
  @State sessionTitle: string = '未命名会话'; // 会话标题
  @State isEditingTitle: boolean = false; // 是否正在编辑标题
  @State editingTitle: string = ''; // 编辑中的标题

  private scroller: Scroller = new Scroller();
  private userId: string = '';

  async aboutToAppear() {
    // 加载用户信息
    this.userInfo = await StorageUtil.getUserInfo<LoginResponse>();
    if (this.userInfo && this.userInfo.userId) {
      this.userId = this.userInfo.userId.toString();
    }

    // 检查是否从历史会话进入
    const params = router.getParams() as Record<string, Object>;
    if (params && params['sessionId']) {
      this.sessionId = params['sessionId'] as number;
      await this.loadSessionMessages();
    } else {
      // 新会话，添加欢迎消息
      const welcomeMsg = new Message();
      welcomeMsg.role = 'ai';
      welcomeMsg.content = '你好！我是智能校园助手，有什么可以帮助你的吗？';
      welcomeMsg.createTime = new Date().toISOString();
      this.messages.push(welcomeMsg);
    }
  }

  /**
   * 加载会话消息历史
   */
  private async loadSessionMessages(): Promise<void> {
    if (!this.sessionId) {
      return;
    }

    try {
      // 加载会话详情
      const session = await SessionService.getSessionDetail(this.sessionId);
      this.sessionTitle = session.title || '未命名会话';

      // 加载消息历史
      const messages = await SessionService.getSessionMessages(this.sessionId);
      this.messages = messages;
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `加载失败: ${error.message}` });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      // 消息列表
      this.buildMessageList()

      // 底部输入区域
      this.buildInputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F4F8')
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  buildHeader() {
    Column() {
      // 第一行：用户信息和按钮
      Row() {
        // 用户头像和信息
        Row() {
          Image(this.userInfo?.avatar || $r('app.media.app_icon'))
            .width(40)
            .height(40)
            .borderRadius(20)
            .margin({ right: 10 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/ProfilePage' });
            })

          Column() {
            Text(this.userInfo?.username || '用户')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')

            Text('在线')
              .fontSize(12)
              .fontColor('#1E90FF')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        // 新建会话按钮
        Image($r('app.media.add'))
          .width(24)
          .height(24)
          .margin({ right: 12 })
          .onClick(() => {
            this.createNewSession();
          })

        // 历史会话按钮
        Button('历史会话')
          .fontSize(14)
          .fontColor('#1E90FF')
          .backgroundColor('#E3F2FD')
          .height(36)
          .padding({ left: 16, right: 16 })
          .borderRadius(18)
          .onClick(() => {
            router.pushUrl({ 
              url: 'pages/HistoryPage',
              params: { currentSessionId: this.sessionId }
            });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 第二行：会话标题
      Row() {
        if (this.isEditingTitle) {
          // 编辑模式：显示输入框
          TextInput({ text: this.editingTitle })
            .fontSize(14)
            .layoutWeight(1)
            .height(32)
            .borderRadius(4)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.editingTitle = value;
            })
            .margin({ right: 8 })
        } else {
          // 显示模式：显示标题
          Text(this.sessionTitle)
            .fontSize(14)
            .fontColor('#666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }

        // 编辑/保存按钮（只有在有 sessionId 时才显示）
        if (this.sessionId) {
          if (this.isEditingTitle) {
            // 保存按钮
            Image($r('app.media.save'))
              .width(20)
              .height(20)
              .onClick(() => {
                this.saveTitle();
              })
          } else {
            // 编辑按钮
            Image($r('app.media.edit'))
              .width(20)
              .height(20)
              .onClick(() => {
                this.startEditTitle();
              })
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor('#FFF')
    .shadow({ radius: 4, color: '#00000010' })
  }

  /**
   * 构建消息列表
   */
  @Builder
  buildMessageList() {
    Scroll(this.scroller) {
      Column() {
        ForEach(this.messages, (msg: Message, index: number) => {
          this.buildMessageItem(msg, index);
        }, (msg: Message, index: number) => `${index}-${msg.content?.length || 0}-${msg.isStreaming}`)
      }
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  /**
   * 构建单条消息
   */
  @Builder
  buildMessageItem(msg: Message, index: number) {
    Row() {
      if (msg.role === 'user') {
        // 用户消息（右侧）
        Blank()

        Column() {
          Text(msg.content)
            .fontSize(15)
            .fontColor('#FFF')
            .padding(12)
            .borderRadius(12)
            .backgroundColor('#1E90FF')
            .maxLines(999)
        }
        .alignItems(HorizontalAlign.End)
        .width('75%')

        Image(this.userInfo?.avatar || $r('app.media.app_icon'))
          .width(36)
          .height(36)
          .borderRadius(18)
          .margin({ left: 8 })
      } else {
        // AI 消息（左侧）
        Image($r('app.media.app_icon'))
          .width(36)
          .height(36)
          .borderRadius(18)
          .margin({ right: 8 })

        Column() {
          // 气泡容器
          Column() {
            // 暂时使用Text组件，避免MarkdownView的Web加载延迟
            Text(msg.content || '')
              .fontSize(15)
              .fontColor('#333')
              .lineHeight(24)
              .width('100%')
          }
          .backgroundColor('#FFF')
          .borderRadius(12)
          .padding(12)
          .width('100%')

          // 流式输出中的提示
          if (msg.isStreaming) {
            Text('正在输入...')
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('75%')

        Blank()
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建底部输入区域
   */
  @Builder
  buildInputArea() {
    Column() {
      // 流式输出开关
      Row() {
        Text('流式输出')
          .fontSize(14)
          .fontColor('#666')

        Toggle({ type: ToggleType.Switch, isOn: this.isStreaming })
          .selectedColor('#1E90FF')
          .margin({ left: 8 })
          .onChange((isOn: boolean) => {
            this.isStreaming = isOn;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .justifyContent(FlexAlign.End)

      // 输入框和发送按钮
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .fontSize(15)
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })

        Button('发送')
          .fontSize(15)
          .fontColor('#FFF')
          .width(70)
          .height(44)
          .margin({ left: 10 })
          .borderRadius(22)
          .backgroundColor('#1E90FF')
          .enabled(!this.isLoading && this.inputText.trim().length > 0)
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFF')
    .shadow({ radius: 4, color: '#00000010', offsetY: -2 })
  }

  /**
   * 发送消息
   */
  private async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isLoading || !this.userId) {
      return;
    }

    // 添加用户消息
    const userMsg = new Message();
    userMsg.role = 'user';
    userMsg.content = text;
    userMsg.createTime = new Date().toISOString();
    this.messages = [...this.messages, userMsg];

    // 清空输入框
    this.inputText = '';

    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);

    this.isLoading = true;

    try {
      if (this.isStreaming) {
        // 流式输出
        await this.sendStreamMessage(text);
      } else {
        // 非流式输出
        await this.sendNormalMessage(text);
      }
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `发送失败: ${error.message}` });
      // 添加错误提示消息
      const errorMsg = new Message();
      errorMsg.role = 'ai';
      errorMsg.content = '抱歉，消息发送失败，请稍后重试。';
      errorMsg.createTime = new Date().toISOString();
      this.messages = [...this.messages, errorMsg];
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 发送非流式消息
   */
  private async sendNormalMessage(text: string): Promise<void> {
    const response: AssistantResponse = await ChatService.chat(this.userId, text, this.sessionId);

    // 从响应中获取 sessionId（如果是新会话）
    if (response.sessionId && !this.sessionId) {
      this.sessionId = response.sessionId;
    }

    // 添加 AI 回复
    const aiMsg = new Message();
    aiMsg.role = 'ai';
    aiMsg.content = response.answer || '';
    aiMsg.createTime = new Date().toISOString();
    this.messages = [...this.messages, aiMsg];

    // 如果有建议，也显示
    if (response.suggestion) {
      const suggestionMsg = new Message();
      suggestionMsg.role = 'ai';
      suggestionMsg.content = `建议：${response.suggestion}`;
      suggestionMsg.createTime = new Date().toISOString();
      this.messages = [...this.messages, suggestionMsg];
    }

    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  /**
   * 发送流式消息
   */
  private async sendStreamMessage(text: string): Promise<void> {
    console.info('[ChatPage] 开始发送流式消息:', text);
    
    // 创建一个空的 AI 消息，用于逐步追加内容
    const aiMessage = new Message();
    aiMessage.role = 'ai';
    aiMessage.content = '';
    aiMessage.createTime = new Date().toISOString();
    aiMessage.isStreaming = true;
    this.messages = [...this.messages, aiMessage];

    const messageIndex = this.messages.length - 1;
    console.info('[ChatPage] 创建AI消息占位，索引:', messageIndex);

    await ChatService.chatStream(
      this.userId,
      text,
      this.sessionId,
      // onMessage: 接收到数据片段
      // onMessage: 接收到数据片段
      (data: string) => {
        console.info('[ChatPage] 收到流式数据片段，长度:', data.length);
        console.debug('[ChatPage] 数据内容:', data);
        
        // 创建新的消息对象以触发UI更新
        const currentMsg = this.messages[messageIndex];
        const newMsg = new Message(currentMsg);
        newMsg.content = (currentMsg.content || '') + data;
        
        console.debug('[ChatPage] 更新后内容总长度:', newMsg.content.length);
        
        // 更新数组中的对象
        this.messages[messageIndex] = newMsg;
        // 触发数组引用的更新检测
        this.messages = [...this.messages];

        // 滚动到底部
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom);
        }, 50);
      },
      // onComplete: 完成
      () => {
        console.info('[ChatPage] 流式消息接收完成');
        this.messages[messageIndex].isStreaming = false;
        this.messages = [...this.messages]; // 触发更新
        
        // 注意：流式接口无法直接获取 sessionId
        // 如果需要 sessionId，建议在第一次对话时使用非流式接口
      },
      // onError: 错误
      (error: Error) => {
        console.error('[ChatPage] 流式消息接收失败:', error.message);
        this.messages[messageIndex].isStreaming = false;
        this.messages[messageIndex].content = `错误: ${error.message}`;
        this.messages = [...this.messages]; // 触发更新
      }
    );
  }

  /**
   * 开始编辑标题
   */
  private startEditTitle(): void {
    this.editingTitle = this.sessionTitle;
    this.isEditingTitle = true;
  }

  /**
   * 保存标题
   */
  private async saveTitle(): Promise<void> {
    const newTitle = this.editingTitle.trim();
    if (!newTitle) {
      promptAction.showToast({ message: '标题不能为空' });
      return;
    }

    if (!this.sessionId) {
      promptAction.showToast({ message: '请先进行对话' });
      return;
    }

    try {
      await SessionService.updateSessionTitle(this.sessionId, newTitle);
      this.sessionTitle = newTitle;
      this.isEditingTitle = false;
      promptAction.showToast({ message: '标题已保存' });
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `保存失败: ${error.message}` });
    }
  }

  /**
   * 创建新会话
   */
  private createNewSession(): void {
    // 清空当前会话数据
    this.sessionId = undefined;
    this.sessionTitle = '未命名会话';
    this.inputText = '';
    this.isLoading = false;
    this.messages = [];
    this.isEditingTitle = false; // 重置编辑状态
    this.editingTitle = '';
    
    // 使用 setTimeout 确保状态完全重置
    setTimeout(() => {
      // 创建新的消息数组（强制触发状态更新）
      const welcomeMsg = new Message();
      welcomeMsg.role = 'ai';
      welcomeMsg.content = '你好！我是智能校园助手，有什么可以帮助你的吗？';
      welcomeMsg.createTime = new Date().toISOString();
      
      // 重新赋值消息数组
      this.messages = [welcomeMsg];
      
      // 滚动到顶部
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Top);
      }, 100);
    }, 50);
  }
}
