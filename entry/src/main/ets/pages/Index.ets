import { router } from '@kit.ArkUI';
import { StorageUtil } from '../utils/StorageUtil';

@Entry
@Component
struct Index {
  async aboutToAppear() {
    // 初始化存储工具
    await StorageUtil.init(getContext(this));

    // 检查登录状态
    const token = await StorageUtil.getToken();

    // 延迟一下，显示启动画面
    setTimeout(() => {
      if (token) {
        // 已登录，跳转到聊天页面
        router.replaceUrl({ url: 'pages/ChatPage' });
      } else {
        // 未登录，跳转到登录页面
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    }, 1000);
  }

  build() {
    Column() {
      // 启动画面
      Column() {
        Image($r('app.media.app_icon'))
          .width(100)
          .height(100)
          .margin({ bottom: 20 })

        Text('智能校园助手')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E90FF')
          .margin({ bottom: 10 })

        Text('AI Campus Assistant')
          .fontSize(14)
          .fontColor('#999')

        LoadingProgress()
          .color('#1E90FF')
          .width(40)
          .height(40)
          .margin({ top: 40 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F4F8')
  }
}