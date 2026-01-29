import { AppColors, AppRadius } from '../common/Theme';

@Component
export struct PhotoCard {
  @Prop assetUri: string = '';
  @Prop isActive: boolean = false;
  @Prop offsetX: number = 0;
  @Prop offsetY: number = 0;

  // 计算手势反馈的透明度
  private getDeleteOpacity(): number {
    if (this.offsetY > 30) {
      return Math.min((this.offsetY - 30) / 100, 0.9);
    }
    return 0;
  }

  private getKeepOpacity(): number {
    if (this.offsetY < -30) {
      return Math.min((-this.offsetY - 30) / 100, 0.9);
    }
    return 0;
  }

  private getInfoOpacity(): number {
    if (this.offsetX < -30) {
      return Math.min((-this.offsetX - 30) / 100, 0.9);
    }
    return 0;
  }

  build() {
    Stack() {
      // 照片内容
      Image(this.assetUri)
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('100%')
        .borderRadius(AppRadius.LG)

      // 删除反馈层 (下滑)
      if (this.isActive && this.getDeleteOpacity() > 0) {
        Column() {
          Text('🗑️')
            .fontSize(60)
          Text('删除')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .borderRadius(AppRadius.LG)
        .backgroundColor(AppColors.ACCENT_DELETE)
        .opacity(this.getDeleteOpacity())
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // 保留反馈层 (上滑)
      if (this.isActive && this.getKeepOpacity() > 0) {
        Column() {
          Text('❤️')
            .fontSize(60)
          Text('保留')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .borderRadius(AppRadius.LG)
        .backgroundColor(AppColors.ACCENT_KEEP)
        .opacity(this.getKeepOpacity())
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // 详情反馈层 (左滑)
      if (this.isActive && this.getInfoOpacity() > 0) {
        Column() {
          Text('ℹ️')
            .fontSize(60)
          Text('详情')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .borderRadius(AppRadius.LG)
        .backgroundColor(AppColors.ACCENT_INFO)
        .opacity(this.getInfoOpacity())
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // 底部渐变遮罩
      if (this.isActive) {
        Column()
          .width('100%')
          .height('20%')
          .position({ x: 0, y: '80%' })
          .linearGradient({
            direction: GradientDirection.Top,
            colors: [['#00000000', 0], ['#CC000000', 1]]
          })
          .borderRadius({ bottomLeft: AppRadius.LG, bottomRight: AppRadius.LG })
      }
    }
    .width('100%')
    .height('100%')
    .shadow({
      radius: this.isActive ? 20 : 10,
      color: '#60000000',
      offsetX: 0,
      offsetY: this.isActive ? 8 : 4
    })
    .borderRadius(AppRadius.LG)
    .clip(true)
  }
}
