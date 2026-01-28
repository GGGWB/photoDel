import { PhotoCard } from './PhotoCard';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

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
      // Render only the top 2 cards for performance
      // The one below (next)
      if (this.currentIndex + 1 < this.photos.length) {
        PhotoCard({
          assetUri: this.photos[this.currentIndex + 1].uri,
          isActive: false
        })
          .scale({ x: 0.9, y: 0.9 })
          .opacity(0.8)
          .zIndex(0)
      }

      // The top one (current)
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
                // Determine action based on offset
                if (this.offsetY > this.THRESHOLD) {
                  // Down: Delete
                  this.onSwipeDown(this.photos[this.currentIndex]);
                  this.resetPosition();
                } else if (this.offsetY < -this.THRESHOLD) {
                  // Up: Keep
                  this.onSwipeUp(this.photos[this.currentIndex]);
                  this.resetPosition();
                } else if (this.offsetX < -this.THRESHOLD) {
                  // Left: Info
                  this.onSwipeLeft(this.photos[this.currentIndex]);
                  this.animateReset();
                } else {
                  // Reset (Snap back)
                  this.animateReset();
                }
              })
          )
      } else {
        // Empty State (Batch finished)
        Text("已完成")
          .fontSize(30)
          .fontColor(Color.Gray)
      }
    }
    .width('90%')
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
