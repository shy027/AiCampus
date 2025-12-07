import { webview } from '@kit.ArkWeb';

/**
 * Markdown 渲染组件
 * 使用 Web 组件 + marked.js 实现
 */
@Component
export struct MarkdownView {
  @Link content: string;
  controller: webview.WebviewController = new webview.WebviewController();
  @State isLoaded: boolean = false;

  @State webHeight: number = 100; // 默认高度

  // HTML 模板
  private readonly htmlTemplate: string = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        /* 基础样式重置 */
        body { 
          margin: 0; 
          padding: 12px; 
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          font-size: 15px;
          line-height: 1.6;
          color: #333;
          background-color: transparent;
          overflow-y: hidden; /* 禁用内部滚动 */
        }
        
        /* Markdown 样式模拟 (GitHub 风格) */
        h1, h2, h3, h4, h5, h6 { margin-top: 24px; margin-bottom: 16px; font-weight: 600; line-height: 1.25; }
        h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: .3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: .3em; }
        h3 { font-size: 1.25em; }
        
        p { margin-top: 0; margin-bottom: 16px; }
        
        code {
          padding: .2em .4em;
          margin: 0;
          font-size: 85%;
          background-color: #f6f8fa;
          border-radius: 6px;
          font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono, monospace;
        }
        
        pre {
          padding: 16px;
          overflow: auto;
          font-size: 85%;
          line-height: 1.45;
          background-color: #f6f8fa;
          border-radius: 6px;
          margin-bottom: 16px;
        }
        
        pre code {
          padding: 0;
          background-color: transparent;
          font-size: 100%;
          word-break: normal;
          white-space: pre;
        }

        blockquote {
          margin: 0 0 16px;
          padding: 0 1em;
          color: #6a737d;
          border-left: .25em solid #dfe2e5;
        }
        
        ul, ol { padding-left: 2em; margin-bottom: 16px; }
        
        img { max-width: 100%; box-sizing: border-box; background-color: #fff; }
        
        table {
          display: block;
          width: 100%;
          overflow: auto;
          border-spacing: 0;
          border-collapse: collapse;
          margin-bottom: 16px;
        }
        
        table th, table td {
          padding: 6px 13px;
          border: 1px solid #dfe2e5;
        }
        
        table tr { background-color: #fff; border-top: 1px solid #c6cbd1; }
        table tr:nth-child(2n) { background-color: #f6f8fa; }
        
        hr {
          height: .25em;
          padding: 0;
          margin: 24px 0;
          background-color: #e1e4e8;
          border: 0;
        }
        
        a { color: #0366d6; text-decoration: none; }
        a:hover { text-decoration: underline; }
      </style>
      <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    </head>
    <body>
      <div id="content"></div>
      <script>
        function updateContent(markdown) {
          const contentDiv = document.getElementById('content');
          if (typeof marked !== 'undefined') {
             marked.setOptions({
               gfm: true,
               breaks: true
             });
             contentDiv.innerHTML = marked.parse(markdown);
          } else {
             contentDiv.innerText = markdown;
          }
          // 计算高度并发送 (添加一点 buffer)
          const height = document.body.scrollHeight;
          console.info('height:' + height);
        }
      </script>
    </body>
    </html>
  `;

  build() {
    Web({ src: '', controller: this.controller })
      .onControllerAttached(() => {
        // 使用 baseUrl 允许加载 CDN 资源
        this.controller.loadData(this.htmlTemplate, 'text/html', 'UTF-8', 'https://app');
      })
      .onPageEnd(() => {
        this.isLoaded = true;
        this.updateMarkdown(this.content);
      })
      .onConsole((event) => {
        if (event && event.message) {
           const msg = event.message.getMessage();
           if (msg.startsWith('height:')) {
             const heightStr = msg.substring(7);
             const height = parseInt(heightStr);
             if (!isNaN(height) && height > 0) {
               this.webHeight = height;
             }
             return true;
           } else if (msg.startsWith('log:')) {
             // console.info('JS Log: ' + msg);
             return true;
           }
        }
        return false;
      })
      .zoomAccess(false)
      .javaScriptAccess(true) // 显式启用 JS
      .domStorageAccess(true)
      .backgroundColor(Color.Transparent)
      .width('100%')
      .height(this.webHeight) // 动态高度
  }

  updateMarkdown(text: string) {
    if (this.isLoaded && this.controller) {
      // 转义特殊字符，防止 JS 注入错误
      const escapedText = JSON.stringify(text);
      // 调用 JS更新
      this.controller.runJavaScript(`updateContent(${escapedText})`);
    }
  }
}
