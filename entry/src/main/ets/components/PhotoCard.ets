import { photoAccessHelper } from '@kit.MediaLibraryKit';

@Component
export struct PhotoCard {
  @Prop assetUri: string = '';
  @Prop isActive: boolean = false;

  build() {
    Stack() {
      // Photo content
      Image(this.assetUri)
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('100%')
        .borderRadius(16)
        .backgroundColor(Color.Black)

      // Overlay gradient for better visibility
      if (this.isActive) {
        Column()
          .width('100%')
          .height('15%')
          .position({ x: 0, y: '85%' })
          .linearGradient({
            direction: GradientDirection.Top,
            colors: [['#00000000', 0], ['#80000000', 1]]
          })
      }
    }
    .width('100%')
    .height('100%')
    .shadow({ radius: 10, color: '#40000000', offsetX: 0, offsetY: 4 })
    .borderRadius(16)
    .clip(true)
  }
}
