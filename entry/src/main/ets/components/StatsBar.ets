/**
 * StatsBar.ets
 * 
 * 底部统计栏组件
 * 显示相册总数、已处理、保留、删除等实时统计数据。
 * 提供进入“回收站”页面的入口。
 * 
 * v2.5 更新：
 * - 图标更新：更换了更简约的白色垃圾桶图标，并去除了背景底色，
 *   使视觉风格与暗黑玻璃主题更加统一。
 */
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
          Image($r('app.media.ic_trash_custom'))
            .width(24)
            .height(24)
            .fillColor(AppColors.TEXT_PRIMARY)
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
