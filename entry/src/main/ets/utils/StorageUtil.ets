import { preferences } from '@kit.ArkData';
import { ApiConstants } from '../constants/ApiConstants';

/**
 * 本地存储工具类
 */
export class StorageUtil {
  private static dataPreferences: preferences.Preferences | null = null;

  /**
   * 初始化 Preferences
   */
  static async init(context: Context): Promise<void> {
    try {
      StorageUtil.dataPreferences = await preferences.getPreferences(context, 'AiCampusData');
    } catch (err) {
      console.error('StorageUtil init failed:', JSON.stringify(err));
    }
  }

  /**
   * 保存字符串
   */
  static async putString(key: string, value: string): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      console.error('StorageUtil not initialized');
      return;
    }
    try {
      await StorageUtil.dataPreferences.put(key, value);
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('StorageUtil putString failed:', JSON.stringify(err));
    }
  }

  /**
   * 获取字符串
   */
  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!StorageUtil.dataPreferences) {
      console.error('StorageUtil not initialized');
      return defaultValue;
    }
    try {
      const value = await StorageUtil.dataPreferences.get(key, defaultValue);
      return value as string;
    } catch (err) {
      console.error('StorageUtil getString failed:', JSON.stringify(err));
      return defaultValue;
    }
  }

  /**
   * 保存对象（JSON 序列化）
   */
  static async putObject(key: string, value: Object): Promise<void> {
    await StorageUtil.putString(key, JSON.stringify(value));
  }

  /**
   * 获取对象（JSON 反序列化）
   */
  static async getObject<T>(key: string): Promise<T | null> {
    const str = await StorageUtil.getString(key);
    if (!str) {
      return null;
    }
    try {
      return JSON.parse(str) as T;
    } catch (err) {
      console.error('StorageUtil getObject parse failed:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 删除数据
   */
  static async remove(key: string): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      console.error('StorageUtil not initialized');
      return;
    }
    try {
      await StorageUtil.dataPreferences.delete(key);
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('StorageUtil remove failed:', JSON.stringify(err));
    }
  }

  /**
   * 清空所有数据
   */
  static async clear(): Promise<void> {
    if (!StorageUtil.dataPreferences) {
      console.error('StorageUtil not initialized');
      return;
    }
    try {
      await StorageUtil.dataPreferences.clear();
      await StorageUtil.dataPreferences.flush();
    } catch (err) {
      console.error('StorageUtil clear failed:', JSON.stringify(err));
    }
  }

  // 便捷方法：Token 相关
  static async saveToken(token: string): Promise<void> {
    await StorageUtil.putString(ApiConstants.STORAGE_TOKEN, token);
  }

  static async getToken(): Promise<string> {
    return await StorageUtil.getString(ApiConstants.STORAGE_TOKEN);
  }

  static async removeToken(): Promise<void> {
    await StorageUtil.remove(ApiConstants.STORAGE_TOKEN);
  }

  // 便捷方法：用户 ID
  static async saveUserId(userId: number): Promise<void> {
    await StorageUtil.putString(ApiConstants.STORAGE_USER_ID, userId.toString());
  }

  static async getUserId(): Promise<number> {
    const str = await StorageUtil.getString(ApiConstants.STORAGE_USER_ID);
    return str ? parseInt(str) : 0;
  }

  // 便捷方法：用户信息
  static async saveUserInfo(userInfo: Object): Promise<void> {
    await StorageUtil.putObject(ApiConstants.STORAGE_USER_INFO, userInfo);
  }

  static async getUserInfo<T>(): Promise<T | null> {
    return await StorageUtil.getObject<T>(ApiConstants.STORAGE_USER_INFO);
  }
}
