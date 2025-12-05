import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { SessionService } from '../services/SessionService';
import { StorageUtil } from '../utils/StorageUtil';
import { Session } from '../models/Session';

@Entry
@Component
struct HistoryPage {
  @State sessions: Session[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear() {
    await this.loadSessions();
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      // 会话列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .color('#1E90FF')
            .width(50)
            .height(50)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.sessions.length === 0) {
        Column() {
          Text('暂无历史会话')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.sessions, (session: Session) => {
            ListItem() {
              this.buildSessionItem(session)
            }
          }, (session: Session) => session.id?.toString() || '')
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }
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
    Row() {
      Image($r('sys.media.ohos_ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor('#333')
        .onClick(() => {
          router.back();
        })

      Text('历史会话')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ left: 12 })

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFF')
    .shadow({ radius: 4, color: '#00000010' })
  }

  /**
   * 构建会话项
   */
  @Builder
  buildSessionItem(session: Session) {
    Row() {
      Column() {
        Text(session.title || '新会话')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.formatTime(session.createTime || ''))
          .fontSize(13)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => {
        this.openSession(session);
      })

      // 删除图标
      Image($r('app.media.delete'))
        .width(20)
        .height(20)
        .margin({ left: 12, right: 8 })
        .onClick(() => {
          this.confirmDelete(session);
        })

      // 箭头图标
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(20)
        .height(20)
        .fillColor('#CCC')
        .onClick(() => {
          this.openSession(session);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF')
  }



  /**
   * 加载会话列表
   */
  private async loadSessions() {
    this.isLoading = true;
    try {
      const userId = await StorageUtil.getUserId();
      if (userId) {
        this.sessions = await SessionService.getSessionList(userId);
      }
    } catch (err) {
      promptAction.showToast({ message: `加载失败: ${err}` });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 打开会话
   */
  private openSession(session: Session) {
    // 跳转到聊天页面，并传递会话 ID
    router.replaceUrl({
      url: 'pages/ChatPage',
      params: { sessionId: session.id }
    });
  }

  /**
   * 确认删除会话
   */
  private confirmDelete(session: Session): void {
    if (!session.id) {
      return;
    }

    // 使用 AlertDialog 进行二次确认
    AlertDialog.show({
      title: '确认删除',
      message: `确定要删除会话「${session.title || '新会话'}」吗？`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消操作
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4444',
        action: () => {
          this.deleteSession(session);
        }
      }
    });
  }

  /**
   * 删除会话
   */
  private async deleteSession(session: Session): Promise<void> {
    if (!session.id) {
      return;
    }

    try {
      // 检查是否是从聊天页面跳转过来的，并且删除的是当前会话
      const params = router.getParams() as Record<string, Object>;
      const currentSessionId = params ? params['currentSessionId'] as number : undefined;
      const isCurrentSession = currentSessionId === session.id;

      await SessionService.deleteSession(session.id);
      promptAction.showToast({ message: '删除成功' });

      if (isCurrentSession) {
        // 如果删除的是当前会话，跳转到新会话
        router.replaceUrl({
          url: 'pages/ChatPage'
        });
      } else {
        // 如果不是当前会话，刷新列表
        await this.loadSessions();
      }
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `删除失败: ${error.message}` });
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(timeStr: string): string {
    if (!timeStr) {
      return '';
    }

    try {
      const date = new Date(timeStr);
      const now = new Date();
      const diff = now.getTime() - date.getTime();

      // 今天
      if (diff < 24 * 60 * 60 * 1000 && date.getDate() === now.getDate()) {
        return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      }

      // 昨天
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      if (date.getDate() === yesterday.getDate()) {
        return `昨天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
      }

      // 其他日期
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    } catch (err) {
      return timeStr;
    }
  }
}
