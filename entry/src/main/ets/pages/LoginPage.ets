import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { StorageUtil } from '../utils/StorageUtil';
import { LoginResponse } from '../models/User';

@Entry
@Component
struct LoginPage {
  @State loginMode: number = 0; // 0: 密码登录, 1: 验证码登录
  @State phone: string = '';
  @State password: string = '';
  @State smsCode: string = '';
  @State countdown: number = 0;
  @State isLoading: boolean = false;

  // 倒计时定时器
  private timer: number = -1;

  aboutToDisappear() {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  build() {
    Column() {
      // 顶部标题
      Column() {
        Text('智能校园助手')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1E90FF')
          .margin({ top: 80, bottom: 10 })

        Text('AI Campus Assistant')
          .fontSize(14)
          .fontColor('#999')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 登录表单
      Column() {
        // 登录方式切换
        Row() {
          Text('密码登录')
            .fontSize(18)
            .fontWeight(this.loginMode === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.loginMode === 0 ? '#1E90FF' : '#666')
            .onClick(() => {
              this.loginMode = 0;
            })

          Divider()
            .vertical(true)
            .height(20)
            .margin({ left: 20, right: 20 })
            .color('#E0E0E0')

          Text('验证码登录')
            .fontSize(18)
            .fontWeight(this.loginMode === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.loginMode === 1 ? '#1E90FF' : '#666')
            .onClick(() => {
              this.loginMode = 1;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 60, bottom: 40 })

        // 手机号输入
        Column() {
          TextInput({ placeholder: '请输入手机号' })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .fontSize(16)
            .height(50)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => {
              this.phone = value;
            })
        }
        .width('100%')
        .margin({ bottom: 20 })

        // 密码登录
        if (this.loginMode === 0) {
          Column() {
            TextInput({ placeholder: '请输入密码' })
              .type(InputType.Password)
              .fontSize(16)
              .height(50)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .onChange((value: string) => {
                this.password = value;
              })
          }
          .width('100%')
          .margin({ bottom: 30 })
        }

        // 验证码登录
        if (this.loginMode === 1) {
          Row() {
            TextInput({ placeholder: '请输入验证码' })
              .type(InputType.Number)
              .maxLength(6)
              .fontSize(16)
              .height(50)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .layoutWeight(1)
              .onChange((value: string) => {
                this.smsCode = value;
              })

            Button(this.countdown > 0 ? `${this.countdown}s` : '发送验证码')
              .fontSize(14)
              .height(50)
              .width(110)
              .margin({ left: 10 })
              .backgroundColor(this.countdown > 0 ? '#CCC' : '#1E90FF')
              .enabled(this.countdown === 0)
              .onClick(() => {
                this.sendSmsCode();
              })
          }
          .width('100%')
          .margin({ bottom: 30 })
        }

        // 登录按钮
        Button('登录')
          .fontSize(18)
          .fontColor('#FFF')
          .width('100%')
          .height(50)
          .borderRadius(8)
          .backgroundColor('#1E90FF')
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin();
          })
      }
      .width('85%')
      .padding(30)
      .borderRadius(16)
      .backgroundColor('#FFF')
      .shadow({ radius: 10, color: '#00000010' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F4F8')
  }

  /**
   * 发送验证码
   */
  private async sendSmsCode(): Promise<void> {
    if (!this.phone || this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }

    try {
      await AuthService.sendSms(this.phone);
      promptAction.showToast({ message: '验证码已发送' });

      // 开始倒计时
      this.countdown = 60;
      this.timer = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          clearInterval(this.timer);
        }
      }, 1000);
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `发送失败: ${error.message}` });
    }
  }

  /**
   * 处理登录
   */
  private async handleLogin(): Promise<void> {
    // 验证输入
    if (!this.phone || this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }

    if (this.loginMode === 0 && !this.password) {
      promptAction.showToast({ message: '请输入密码' });
      return;
    }

    if (this.loginMode === 1 && !this.smsCode) {
      promptAction.showToast({ message: '请输入验证码' });
      return;
    }

    this.isLoading = true;

    try {
      let response: LoginResponse;
      if (this.loginMode === 0) {
        // 密码登录
        response = await AuthService.loginByPassword(this.phone, this.password);
      } else {
        // 验证码登录
        response = await AuthService.loginBySms(this.phone, this.smsCode);
      }

      // 保存登录信息
      if (response.token) {
        await StorageUtil.saveToken(response.token);
      }
      if (response.userId) {
        await StorageUtil.saveUserId(response.userId);
      }
      await StorageUtil.saveUserInfo(response);

      promptAction.showToast({ message: '登录成功' });

      // 跳转到聊天页面
      router.replaceUrl({
        url: 'pages/ChatPage'
      });
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `登录失败: ${error.message}` });
    } finally {
      this.isLoading = false;
    }
  }
}
