import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { UserService } from '../services/UserService';
import { AuthService } from '../services/AuthService';
import { StorageUtil } from '../utils/StorageUtil';
import { User, LoginResponse } from '../models/User';

@Entry
@Component
struct ProfilePage {
  @State userInfo: User = new User();
  @State isLoading: boolean = true;
  
  // 编辑状态：记录哪个字段正在编辑
  @State editingField: string = ''; // 'username' | 'email' | 'password' | ''
  
  // 编辑中的值
  @State editValue: string = '';
  @State confirmPassword: string = '';

  async aboutToAppear() {
    await this.loadUserInfo();
  }

  /**
   * 加载用户信息
   */
  private async loadUserInfo(): Promise<void> {
    try {
      const loginInfo = await StorageUtil.getUserInfo<LoginResponse>();
      if (loginInfo && loginInfo.userId) {
        const user = await UserService.getUserInfo(loginInfo.userId);
        this.userInfo = user;
      }
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `加载失败: ${error.message}` });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()

      if (this.isLoading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#1E90FF')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 头像和基本信息
            this.buildProfileHeader()

            // 详细信息
            this.buildInfoSection()

            // 登出按钮
            this.buildLogoutButton()
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F4F8')
  }

  @Builder
  buildHeader() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor('#333')
        .width(24)
        .onClick(() => {
          router.back();
        })

      Text('个人中心')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 24 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFF')
    .shadow({ radius: 2, color: '#00000010' })
  }

  @Builder
  buildProfileHeader() {
    Column() {
      // 头像（可点击修改）
      Stack() {
        Image(this.userInfo.avatar || $r('app.media.app_icon'))
          .width(80)
          .height(80)
          .borderRadius(40)

        // 编辑提示
        Column() {
          Text('点击修改')
            .fontSize(10)
            .fontColor('#FFF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#00000080')
            .borderRadius(10)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .borderRadius(40)
        .backgroundColor('#00000040')
        .opacity(0.8)
      }
      .width(80)
      .height(80)
      .margin({ top: 30, bottom: 16 })
      .onClick(() => {
        this.changeAvatar();
      })

      // 用户名
      Text(this.userInfo.username || '未设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ bottom: 8 })

      // 手机号
      Text(this.userInfo.phone || '')
        .fontSize(14)
        .fontColor('#666')
        .margin({ bottom: 30 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFF')
    .borderRadius(12)
    .margin({ top: 16 })
  }

  @Builder
  buildInfoSection() {
    Column() {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
        .margin({ bottom: 16 })

      // 用户名
      this.buildEditableItem('username', '用户名')

      Divider().margin({ top: 12, bottom: 12 })

      // 邮箱
      this.buildEditableItem('email', '邮箱')

      Divider().margin({ top: 12, bottom: 12 })

      // 密码
      this.buildEditableItem('password', '密码')

      Divider().margin({ top: 12, bottom: 12 })

      // 注册时间（只读）
      this.buildReadOnlyItem('注册时间', this.formatTime(this.userInfo.createTime))

      Divider().margin({ top: 12, bottom: 12 })

      // 最后登录（只读）
      this.buildReadOnlyItem('最后登录', this.formatTime(this.userInfo.lastLoginTime))
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF')
    .borderRadius(12)
    .margin({ top: 16 })
  }

  /**
   * 获取字段的显示值
   */
  private getDisplayValue(fieldName: string): string {
    if (fieldName === 'username') {
      return this.userInfo.username || '未设置';
    } else if (fieldName === 'email') {
      return this.userInfo.email || '未设置';
    } else if (fieldName === 'password') {
      return '******';
    }
    return '';
  }

  /**
   * 构建可编辑的信息项
   */
  @Builder
  buildEditableItem(fieldName: string, label: string) {
    if (this.editingField === fieldName) {
      // 编辑模式
      Column() {
        Row() {
          Text(label)
            .fontSize(14)
            .fontColor('#666')
            .width(70)

          Column() {
            // 第一个输入框（密码或普通输入）
            if (fieldName === 'password') {
              TextInput({ placeholder: '请输入新密码' })
                .type(InputType.Password)
                .fontSize(14)
                .height(36)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onChange((value: string) => {
                  this.editValue = value;
                })
            } else {
              TextInput({ text: this.editValue })
                .fontSize(14)
                .height(36)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onChange((value: string) => {
                  this.editValue = value;
                })
            }

            // 密码确认框（仅密码字段显示）
            if (fieldName === 'password') {
              TextInput({ placeholder: '请再次输入新密码' })
                .type(InputType.Password)
                .fontSize(14)
                .height(36)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .margin({ top: 8 })
                .onChange((value: string) => {
                  this.confirmPassword = value;
                })
            }
          }
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        // 保存和取消按钮
        Row() {
          Button('取消')
            .fontSize(14)
            .fontColor('#666')
            .backgroundColor('#F5F5F5')
            .height(32)
            .layoutWeight(1)
            .margin({ right: 8 })
            .onClick(() => {
              this.cancelEdit();
            })

          Button('保存')
            .fontSize(14)
            .fontColor('#FFF')
            .backgroundColor('#1E90FF')
            .height(32)
            .layoutWeight(1)
            .onClick(() => {
              this.saveField(fieldName);
            })
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .width('100%')
    } else {
      // 显示模式
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor('#666')
          .width(70)

        Text(this.getDisplayValue(fieldName))
          .fontSize(14)
          .fontColor('#333')
          .layoutWeight(1)

        // 编辑图标（使用文本代替）
        Text('✎')
          .fontSize(18)
          .fontColor('#1E90FF')
          .onClick(() => {
            this.startEdit(fieldName, this.getDisplayValue(fieldName));
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  buildReadOnlyItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666')
        .width(70)

      Text(value)
        .fontSize(14)
        .fontColor('#333')
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  buildLogoutButton() {
    Button('登出账号')
      .fontSize(16)
      .fontColor('#FF4444')
      .backgroundColor('#FFF')
      .width('100%')
      .height(50)
      .borderRadius(12)
      .margin({ top: 16 })
      .onClick(() => {
        this.logout();
      })
  }

  /**
   * 开始编辑某个字段
   */
  private startEdit(fieldName: string, currentValue: string): void {
    this.editingField = fieldName;
    
    // 密码字段不显示当前值
    if (fieldName === 'password') {
      this.editValue = '';
      this.confirmPassword = '';
    } else {
      this.editValue = currentValue === '未设置' ? '' : currentValue;
    }
  }

  /**
   * 取消编辑
   */
  private cancelEdit(): void {
    this.editingField = '';
    this.editValue = '';
    this.confirmPassword = '';
  }

  /**
   * 保存字段
   */
  private async saveField(fieldName: string): Promise<void> {
    try {
      if (fieldName === 'username') {
        await this.saveUsername();
      } else if (fieldName === 'email') {
        await this.saveEmail();
      } else if (fieldName === 'password') {
        await this.savePassword();
      }
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `保存失败: ${error.message}` });
    }
  }

  /**
   * 保存用户名
   */
  private async saveUsername(): Promise<void> {
    if (!this.editValue.trim()) {
      promptAction.showToast({ message: '用户名不能为空' });
      return;
    }

    await UserService.updateUserInfo(this.editValue.trim(), undefined);
    
    // 重新加载用户信息以刷新显示
    await this.loadUserInfo();
    
    // 更新本地存储
    const loginInfo = await StorageUtil.getUserInfo<LoginResponse>();
    if (loginInfo) {
      loginInfo.username = this.userInfo.username;
      await StorageUtil.saveUserInfo(loginInfo);
    }
    
    this.cancelEdit();
    promptAction.showToast({ message: '用户名已更新' });
  }

  /**
   * 保存邮箱
   */
  private async saveEmail(): Promise<void> {
    await UserService.updateUserInfo(undefined, this.editValue.trim() || undefined);
    
    // 重新加载用户信息以刷新显示
    await this.loadUserInfo();
    
    this.cancelEdit();
    promptAction.showToast({ message: '邮箱已更新' });
  }

  /**
   * 保存密码
   */
  private async savePassword(): Promise<void> {
    if (!this.editValue.trim()) {
      promptAction.showToast({ message: '密码不能为空' });
      return;
    }

    if (this.editValue !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }

    if (this.editValue.length < 6) {
      promptAction.showToast({ message: '密码长度至少6位' });
      return;
    }

    // 调用更新密码接口
    await UserService.updateUserInfo(undefined, undefined, this.editValue);
    
    // 重新加载用户信息以刷新显示
    await this.loadUserInfo();
    
    this.cancelEdit();
    promptAction.showToast({ message: '密码已更新' });
  }

  /**
   * 修改头像
   */
  private async changeAvatar(): Promise<void> {
    try {
      // 配置选择器选项
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      
      // 创建选择器并选择图片
      const photoPicker = new picker.PhotoViewPicker();
      const selectResult: picker.PhotoSelectResult = await photoPicker.select(photoSelectOptions);
      
      if (!selectResult || !selectResult.photoUris || selectResult.photoUris.length === 0) {
        promptAction.showToast({ message: '未选择图片' });
        return;
      }
      
      const imageUri = selectResult.photoUris[0];
      console.info('[Avatar] 选择的图片URI:', imageUri);
      
      // 显示上传提示
      promptAction.showToast({ message: '正在上传头像...' });
      
      // 上传头像
      const AvatarService = await import('../services/AvatarService');
      await AvatarService.AvatarService.uploadAvatar(imageUri);
      
      // 重新加载用户信息
      await this.loadUserInfo();
      
      promptAction.showToast({ message: '头像已更新' });
    } catch (err) {
      const error = err as Error;
      console.error('[Avatar] 上传失败:', JSON.stringify(err));
      promptAction.showToast({ message: `上传失败: ${error.message}` });
    }
  }

  /**
   * 登出
   */
  private async logout(): Promise<void> {
    try {
      await AuthService.logout();
      await StorageUtil.clear();
      router.replaceUrl({ url: 'pages/LoginPage' });
      promptAction.showToast({ message: '已登出' });
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: `登出失败: ${error.message}` });
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(time?: string): string {
    if (!time) {
      return '未知';
    }
    
    try {
      const date = new Date(time);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hour = String(date.getHours()).padStart(2, '0');
      const minute = String(date.getMinutes()).padStart(2, '0');
      
      return `${year}-${month}-${day} ${hour}:${minute}`;
    } catch {
      return '未知';
    }
  }
}
