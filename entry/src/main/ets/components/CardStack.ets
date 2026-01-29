import { PhotoCard } from './PhotoCard';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppColors, AppRadius, AppAnimation } from '../common/Theme';

@Component
export struct CardStack {
  @Link photos: Array<photoAccessHelper.PhotoAsset>;
  @Link currentIndex: number;
  @Link removedCount: number;

  // Callbacks
  onSwipeLeft: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeRight: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeUp: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeDown: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};

  // Gesture State
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State rotateAngle: number = 0;
  @State cardScale: number = 1;

  private readonly THRESHOLD: number = 120;

  build() {
    Stack() {
      // 第三张卡片 (背景)
      if (this.currentIndex + 2 < this.photos.length) {
        PhotoCard({
          assetUri: this.photos[this.currentIndex + 2].uri,
          isActive: false,
          offsetX: 0,
          offsetY: 0
        })
          .scale({ x: 0.85, y: 0.85 })
          .opacity(0.5)
          .zIndex(0)
      }

      // 第二张卡片 (次层)
      if (this.currentIndex + 1 < this.photos.length) {
        PhotoCard({
          assetUri: this.photos[this.currentIndex + 1].uri,
          isActive: false,
          offsetX: 0,
          offsetY: 0
        })
          .scale({ x: 0.92, y: 0.92 })
          .opacity(0.7)
          .zIndex(1)
      }

      // 顶层卡片 (当前操作)
      if (this.currentIndex < this.photos.length) {
        PhotoCard({
          assetUri: this.photos[this.currentIndex].uri,
          isActive: true,
          offsetX: this.offsetX,
          offsetY: this.offsetY
        })
          .zIndex(2)
          .translate({ x: this.offsetX, y: this.offsetY })
          .rotate({ angle: this.rotateAngle })
          .scale({ x: this.cardScale, y: this.cardScale })
          .gesture(
            PanGesture()
              .onActionStart((): void => {
                this.cardScale = 1.02;
              })
              .onActionUpdate((event?: GestureEvent): void => {
                if (event) {
                  this.offsetX = event.offsetX;
                  this.offsetY = event.offsetY;
                  this.rotateAngle = event.offsetX / 25;
                }
              })
              .onActionEnd((): void => {
                this.cardScale = 1;
                if (this.offsetY > this.THRESHOLD) {
                  this.flyOut('down');
                  this.onSwipeDown(this.photos[this.currentIndex]);
                } else if (this.offsetY < -this.THRESHOLD) {
                  this.flyOut('up');
                  this.onSwipeUp(this.photos[this.currentIndex]);
                } else if (this.offsetX < -this.THRESHOLD) {
                  this.onSwipeLeft(this.photos[this.currentIndex]);
                  this.animateReset();
                } else {
                  this.animateReset();
                }
              })
          )
      } else {
        // 空状态
        Column() {
          Text('🎉')
            .fontSize(80)
          Text('整理完成')
            .fontSize(28)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16 })
          Text(`本次删除 ${this.removedCount} 张`)
            .fontSize(16)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 8 })
        }
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('92%')
    .height('75%')
  }

  flyOut(direction: string): void {
    let targetY = direction === 'down' ? 800 : -800;
    this.getUIContext().animateTo({
      duration: AppAnimation.NORMAL,
      curve: Curve.EaseOut
    }, (): void => {
      this.offsetY = targetY;
      this.offsetX = this.offsetX * 2;
    });

    // 延迟重置
    setTimeout((): void => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.rotateAngle = 0;
    }, AppAnimation.NORMAL);
  }

  animateReset(): void {
    this.getUIContext().animateTo({
      duration: AppAnimation.NORMAL,
      curve: Curve.Spring
    }, (): void => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.rotateAngle = 0;
    });
  }
}
