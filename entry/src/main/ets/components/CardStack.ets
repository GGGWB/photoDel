import { PhotoCard } from './PhotoCard';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppColors } from '../common/Theme';

@Component
export struct CardStack {
  @Link photos: Array<photoAccessHelper.PhotoAsset>;
  @Link currentIndex: number;
  @Link removedCount: number;

  // Callbacks with explicit types
  onSwipeLeft: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeRight: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeUp: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeDown: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};

  // Gesture State
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State rotateAngle: number = 0;

  private readonly THRESHOLD: number = 100;

  build() {
    Stack() {
      // 底层卡片 (下一张)
      if (this.currentIndex + 1 < this.photos.length) {
        PhotoCard({
          assetUri: this.photos[this.currentIndex + 1].uri,
          isActive: false
        })
          .scale({ x: 0.9, y: 0.9 })
          .opacity(0.8)
          .zIndex(0)
      }

      // 顶层卡片 (当前)
      if (this.currentIndex < this.photos.length) {
        PhotoCard({
          assetUri: this.photos[this.currentIndex].uri,
          isActive: true
        })
          .zIndex(1)
          .translate({ x: this.offsetX, y: this.offsetY })
          .rotate({ angle: this.rotateAngle })
          .gesture(
            PanGesture()
              .onActionUpdate((event?: GestureEvent): void => {
                if (event) {
                  this.offsetX = event.offsetX;
                  this.offsetY = event.offsetY;
                  this.rotateAngle = event.offsetX / 20;
                }
              })
              .onActionEnd((): void => {
                if (this.offsetY > this.THRESHOLD) {
                  // 下滑删除
                  this.onSwipeDown(this.photos[this.currentIndex]);
                  this.resetPosition();
                } else if (this.offsetY < -this.THRESHOLD) {
                  // 上滑保留
                  this.onSwipeUp(this.photos[this.currentIndex]);
                  this.resetPosition();
                } else if (this.offsetX < -this.THRESHOLD) {
                  // 左滑详情
                  this.onSwipeLeft(this.photos[this.currentIndex]);
                  this.animateReset();
                } else {
                  // 回弹
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
        }
      }
    }
    .width('92%')
    .height('70%')
  }

  resetPosition(): void {
    this.offsetX = 0;
    this.offsetY = 0;
    this.rotateAngle = 0;
  }

  animateReset(): void {
    this.getUIContext().animateTo({ duration: 300 }, (): void => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.rotateAngle = 0;
    });
  }
}
