/**
 * 主题设计 Token
 * 统一管理颜色、字号、间距等设计常量
 */

// 颜色系统 - 深色主题 (Glassmorphism & Neon)
export class AppColors {
  // 背景色
  static readonly BG_PRIMARY: string = '#0F0C29';      // 渐变起点 (Midnight Blue)
  static readonly BG_SECONDARY: string = '#302B63';    // 渐变中间 (Deep Purple)
  static readonly BG_TERTIARY: string = '#24243E';     // 渐变终点 (Dark Blue-Grey)
  
  static readonly GLASS_BG: string = '#1AFFFFFF';      // 玻璃态背景 (10% White)
  static readonly GLASS_BORDER: string = '#33FFFFFF';  // 玻璃态边框 (20% White)

  // 强调色 (Neon)
  static readonly ACCENT_DELETE: string = '#FF0055';   // 霓虹红
  static readonly ACCENT_KEEP: string = '#00FF99';     // 霓虹绿
  static readonly ACCENT_INFO: string = '#00DDEB';     // 霓虹蓝
  static readonly ACCENT_PRIMARY: string = '#7F00FF';  // 主强调色 (Electric Violet)
  
  // 阴影光晕
  static readonly GLOW_DELETE: string = '#80FF0055';   // 红色光晕
  static readonly GLOW_KEEP: string = '#8000FF99';     // 绿色光晕

  // 文字色
  static readonly TEXT_PRIMARY: string = '#FFFFFF';    // 主文字 - 纯白
  static readonly TEXT_SECONDARY: string = '#EBEBF5';  // 次文字 - 浅灰 (60% White)
  static readonly TEXT_TERTIARY: string = '#EBEBF599'; // 辅助文字 - (30% White)

  // 遮罩
  static readonly OVERLAY_LIGHT: string = '#1AFFFFFF';
  static readonly OVERLAY_DARK: string = '#80000000';
}

// 字体大小
export class AppFontSizes {
  static readonly TITLE: number = 24;
  static readonly SUBTITLE: number = 18;
  static readonly BODY: number = 16;
  static readonly CAPTION: number = 14;
  static readonly SMALL: number = 12;
}

// 间距
export class AppSpacing {
  static readonly XS: number = 4;
  static readonly SM: number = 8;
  static readonly MD: number = 16;
  static readonly LG: number = 24;
  static readonly XL: number = 32;
  static readonly XXL: number = 48;
}

// 圆角
export class AppRadius {
  static readonly SM: number = 8;
  static readonly MD: number = 16;
  static readonly LG: number = 24;
  static readonly XL: number = 32;
  static readonly XXL: number = 48;
  static readonly FULL: number = 999;
}

// 动画时长
export class AppAnimation {
  static readonly FAST: number = 150;
  static readonly NORMAL: number = 300;
  static readonly SLOW: number = 500;
}
