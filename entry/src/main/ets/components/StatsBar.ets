import { AppColors, AppFontSizes, AppSpacing, AppRadius } from '../common/Theme';
import { router } from '@kit.ArkUI';

@Component
export struct StatsBar {
  @Prop albumTotal: number = 0;
  @Prop totalProcessed: number = 0;
  @Prop totalKept: number = 0;
  @Prop totalDeleted: number = 0;

  build() {
    Column() {
      Row() {
        // 相册总数
        Column() {
          Text(`${this.albumTotal}`)
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.ACCENT_INFO)
            .fontWeight(FontWeight.Bold)
          Text('相册')
            .fontSize(AppFontSizes.SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 已处理
        Column() {
          Text(`${this.totalProcessed}`)
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text('已处理')
            .fontSize(AppFontSizes.SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 已保留
        Column() {
          Text(`${this.totalKept}`)
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text('保留')
            .fontSize(AppFontSizes.SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 已删除
        Column() {
          Text(`${this.totalDeleted}`)
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text('删除')
            .fontSize(AppFontSizes.SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 回收站按钮
        Column() {
          Text('🗑️')
            .fontSize(16)
        }
        .width(32)
        .height(32)
        .borderRadius(AppRadius.SM)
        // Removed background color as requested
        .justifyContent(FlexAlign.Center)
        .onClick((): void => {
          router.pushUrl({ url: 'pages/TrashPage' });
        })
      }
      .padding({ left: AppSpacing.SM, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
    }
    .width('94%') // 浮动效果，不占满全宽
    .margin({ bottom: 10 }) // 调整底部距离
    .backgroundColor(AppColors.GLASS_BG) // 玻璃背景
    .backgroundBlurStyle(BlurStyle.Thin) // 毛玻璃模糊
    .borderRadius(AppRadius.XXL) // 大圆角
    .border({ width: 1, color: AppColors.GLASS_BORDER }) // 玻璃边框
    .shadow({ radius: 20, color: AppColors.OVERLAY_DARK, offsetY: 10 }) // 悬浮阴影
  }
}
