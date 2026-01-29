import { PhotoCard } from './PhotoCard';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppColors } from '../common/Theme';

@Component
export struct CardStack {
  @Link photos: Array<photoAccessHelper.PhotoAsset>;
  @Link @Watch('onIndexChange') currentIndex: number;
  @Link removedCount: number;

  // Callbacks
  onSwipeLeft: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeUp: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onSwipeDown: (photo: photoAccessHelper.PhotoAsset) => void = (photo: photoAccessHelper.PhotoAsset): void => {};
  onCardClick: () => void = (): void => {};

  // 手势状态
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State rotateAngle: number = 0;
  @State isAnimating: boolean = false;

  // 下层卡片动态缩放
  // @State nextScale: number = 0.92; // Deduced: Removed scaling

  private readonly THRESHOLD: number = 80;

  // 当 currentIndex 变化时，立即重置所有动画状态
  onIndexChange(): void {
    this.offsetX = 0;
    this.offsetY = 0;
    this.rotateAngle = 0;
    this.isAnimating = false;
  }

  build() {
    Stack() {
      // 使用 ForEach 渲染可见的 2 张照片，确保组件身份的稳定性
      // slice 切片：当前张 + 下一张
      ForEach(this.photos.slice(this.currentIndex, this.currentIndex + 2), (item: photoAccessHelper.PhotoAsset, index: number) => {
        Stack() {
          PhotoCard({
            assetUri: item.uri,
            isActive: index === 0 // 列表中的第一个就是当前活动的顶层卡片
          })
        }
        .zIndex(index === 0 ? 1 : 0) // 顶层 zIndex=1, 底层=0
        // 只有顶层卡片(index=0)应用偏才和旋转
        .translate(index === 0 ? { x: this.offsetX, y: this.offsetY } : { x: 0, y: 0 })
        .rotate(index === 0 ? { angle: this.rotateAngle } : { angle: 0 })
        // 绑定手势 (所有卡片都绑定，但只有 index=0 响应)
        // 避免在组件复用时动态移除/添加手势导致失效
        .gesture(
          PanGesture()
            .onActionUpdate((event?: GestureEvent): void => {
              // 只有顶层卡片允许滑动
              if (index !== 0) return;

              if (event && !this.isAnimating) {
                this.offsetX = event.offsetX;
                this.offsetY = event.offsetY;
                this.rotateAngle = event.offsetX / 15;
              }
            })
            .onActionEnd((): void => {
              if (index !== 0) return;
              if (this.isAnimating) return;

              if (this.offsetY > this.THRESHOLD) {
                this.flyOut('down', (): void => {
                  this.onSwipeDown(this.photos[this.currentIndex]);
                });
              } else if (this.offsetY < -this.THRESHOLD) {
                this.flyOut('up', (): void => {
                  this.onSwipeUp(this.photos[this.currentIndex]);
                });
              } else if (this.offsetX < -this.THRESHOLD) {
                this.onSwipeLeft(this.photos[this.currentIndex]);
                this.animateReset();
              } else {
                this.animateReset();
              }
            })
        )
        .onClick(() => {
          if (index === 0) {
            this.onCardClick();
          }
        })
      }, (item: photoAccessHelper.PhotoAsset) => item.uri) // 关键：使用 uri 作为唯一键值，确保复用

      if (this.currentIndex >= this.photos.length) {
        // 完成状态
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
    .width('90%') // 缩小宽度
    .height('86%') // 增加高度
  }

  flyOut(direction: string, callback: () => void): void {
    this.isAnimating = true;
    let targetY = direction === 'down' ? 800 : -800;

    // 动画：仅顶层飞出
    this.getUIContext().animateTo({
      duration: 250,
      curve: Curve.EaseOut,
      onFinish: (): void => {
        // 动画结束，只负责触发回调更新 index
        // 状态重置由 onIndexChange 自动接管
        callback();
      }
    }, (): void => {
      this.offsetY = targetY;
      this.offsetX = this.offsetX * 1.5;
      this.rotateAngle = this.rotateAngle * 1.2;
    });
  }

  animateReset(): void {
    this.getUIContext().animateTo({
      duration: 200,
      curve: Curve.EaseOut
    }, (): void => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.rotateAngle = 0;
    });
  }
}
