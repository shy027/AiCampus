import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ApiConstants } from '../constants/ApiConstants';
import { StorageUtil } from '../utils/StorageUtil';

/**
 * 上传头像响应
 */
class UploadAvatarResponse {
  avatarUrl?: string;
}

/**
 * 头像上传服务
 */
export class AvatarService {
  /**
   * 上传头像
   * @param fileUri 图片文件URI
   * @returns 头像URL
   */
  static async uploadAvatar(fileUri: string): Promise<string> {
    const httpRequest = http.createHttp();
    
    try {
      // 读取文件
      const file = fileIo.openSync(fileUri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      
      console.info('[AvatarService] 文件大小:', stat.size, 'bytes');
      
      // 获取token
      const token = await StorageUtil.getToken();
      
      // 构建multipart/form-data
      const boundary = '----WebKitFormBoundary' + Date.now();
      const fileName = 'avatar_' + Date.now() + '.jpg';
      
      // 构建请求体
      const uint8Array = new Uint8Array(buffer);
      
      // 创建完整的multipart body
      const bodyParts: Uint8Array[] = [];
      
      // 添加文件头部
      const headerText = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\nContent-Type: image/jpeg\r\n\r\n`;
      const textEncoder = new util.TextEncoder();
      const headerBytes = textEncoder.encodeInto(headerText);
      bodyParts.push(headerBytes);
      
      // 添加文件内容
      bodyParts.push(uint8Array);
      
      // 添加结束标记
      const footerText = `\r\n--${boundary}--\r\n`;
      const footerBytes = textEncoder.encodeInto(footerText);
      bodyParts.push(footerBytes);
      
      // 合并所有部分
      let totalLength = 0;
      for (const part of bodyParts) {
        totalLength += part.length;
      }
      
      const bodyArray = new Uint8Array(totalLength);
      let offset = 0;
      for (const part of bodyParts) {
        bodyArray.set(part, offset);
        offset += part.length;
      }
      
      // 发送请求
      const response = await httpRequest.request(
        `${ApiConstants.BASE_URL}${ApiConstants.USER_AVATAR}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': `multipart/form-data; boundary=${boundary}`
          },
          extraData: bodyArray.buffer
        }
      );
      
      if (response.responseCode !== 200) {
        throw new Error(`上传失败: HTTP ${response.responseCode}`);
      }
      
      const result: Record<string, ESObject> = JSON.parse(response.result as string);
      if (result.code !== 200) {
        throw new Error((result.message as string) || '上传失败');
      }
      
      const data = result.data as Record<string, ESObject>;
      return data.avatarUrl as string;
    } finally {
      httpRequest.destroy();
    }
  }
}
