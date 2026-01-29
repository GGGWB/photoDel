/**
 * 主题设计 Token
 * 统一管理颜色、字号、间距等设计常量
 */

// 颜色系统 - 浅色主题 (米色调)
export class AppColors {
  // 背景色
  static readonly BG_PRIMARY: string = '#FAF9F6';      // 主背景 - 米白
  static readonly BG_SECONDARY: string = '#F0EFEB';    // 次背景 - 暖灰
  static readonly BG_TERTIARY: string = '#E8E6E1';     // 三级背景
  static readonly BG_CARD: string = '#FFFFFF';         // 卡片背景

  // 强调色
  static readonly ACCENT_DELETE: string = '#FF3B30';   // 删除 - 红色
  static readonly ACCENT_KEEP: string = '#34C759';     // 保留 - 绿色
  static readonly ACCENT_INFO: string = '#007AFF';     // 详情 - 蓝色
  static readonly ACCENT_PRIMARY: string = '#007AFF';  // 主强调色 - 蓝

  // 文字色
  static readonly TEXT_PRIMARY: string = '#1C1C1E';    // 主文字 - 深灰黑
  static readonly TEXT_SECONDARY: string = '#8E8E93';  // 次文字 - 灰
  static readonly TEXT_TERTIARY: string = '#C7C7CC';   // 辅助文字

  // 遮罩
  static readonly OVERLAY_LIGHT: string = '#40FFFFFF';
  static readonly OVERLAY_DARK: string = '#60000000';
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
  static readonly FULL: number = 999;
}

// 动画时长
export class AppAnimation {
  static readonly FAST: number = 150;
  static readonly NORMAL: number = 300;
  static readonly SLOW: number = 500;
}
