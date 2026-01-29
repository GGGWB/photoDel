import { AppColors, AppRadius, AppSpacing } from '../common/Theme';

@Component
export struct ActionBar {
  onDelete: () => void = (): void => {};
  onKeep: () => void = (): void => {};
  onInfo: () => void = (): void => {};

  build() {
    Row() {
      // 删除按钮
      Column() {
        Text('✕')
          .fontSize(28)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(64)
      .height(64)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(AppColors.ACCENT_DELETE)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 10, color: '#40FF4757', offsetX: 0, offsetY: 4 })
      .onClick((): void => {
        this.onDelete();
      })

      // 详情按钮
      Column() {
        Text('i')
          .fontSize(24)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .fontStyle(FontStyle.Italic)
      }
      .width(52)
      .height(52)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(AppColors.ACCENT_INFO)
      .justifyContent(FlexAlign.Center)
      .margin({ left: AppSpacing.XL, right: AppSpacing.XL })
      .shadow({ radius: 8, color: '#405352ED', offsetX: 0, offsetY: 4 })
      .onClick((): void => {
        this.onInfo();
      })

      // 保留按钮
      Column() {
        Text('♥')
          .fontSize(28)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(64)
      .height(64)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(AppColors.ACCENT_KEEP)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 10, color: '#402ED573', offsetX: 0, offsetY: 4 })
      .onClick((): void => {
        this.onKeep();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ top: AppSpacing.MD, bottom: AppSpacing.LG })
  }
}
