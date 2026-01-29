import { AppColors, AppRadius } from '../common/Theme';

@Component
export struct PhotoCard {
  @Prop assetUri: string = '';
  @Prop isActive: boolean = false;

  build() {
    Stack() {
      // 照片内容
      Image(this.assetUri)
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('100%')
        .borderRadius(AppRadius.LG)
    }
    .width('100%')
    .height('100%')
    .shadow({
      radius: this.isActive ? 16 : 8,
      color: '#25000000',
      offsetX: 0,
      offsetY: this.isActive ? 6 : 3
    })
    .borderRadius(AppRadius.LG)
    .clip(true)
  }
}
