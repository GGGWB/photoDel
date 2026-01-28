import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PhotoService } from '../services/PhotoService';
import { CardStack } from '../components/CardStack';

@Entry
@Component
struct Index {
  @State photos: Array<photoAccessHelper.PhotoAsset> = [];
  @State currentIndex: number = 0;
  @State removedCount: number = 0;
  @State isLoading: boolean = true;
  private photoService: PhotoService | null = null;

  aboutToAppear(): void {
    let context = getContext(this) as common.UIAbilityContext;
    this.photoService = new PhotoService(context);
    setTimeout((): void => {
      this.loadPhotos();
    }, 1000);
  }

  async loadPhotos(): Promise<void> {
    this.isLoading = true;
    this.removedCount = 0;
    if (this.photoService) {
      const assets = await this.photoService.getRandomAssets(20);
      this.photos = assets;
      this.currentIndex = 0;
    }
    this.isLoading = false;
  }

  async onSwipeDown(asset: photoAccessHelper.PhotoAsset): Promise<void> {
    if (this.photoService) {
      try {
        await this.photoService.moveToTrash(asset);
        this.removedCount++;
      } catch (err) {
        console.error("Delete failed", JSON.stringify(err));
      }
    }
    this.currentIndex++;
  }

  onSwipeUp(asset: photoAccessHelper.PhotoAsset): void {
    this.currentIndex++;
  }

  onSwipeLeft(asset: photoAccessHelper.PhotoAsset): void {
    try {
      let displayName: string = asset.displayName || '未知';
      let info = `文件名: ${displayName}\n`;
      // Use get method for properties
      let dateAdded: number = asset.get(photoAccessHelper.PhotoKeys.DATE_ADDED) as number || 0;
      info += `日期: ${new Date(dateAdded * 1000).toLocaleString()}\n`;

      this.getUIContext().showAlertDialog({
        title: '照片信息',
        message: info,
        confirm: {
          value: '关闭',
          action: (): void => {}
        }
      });
    } catch (e) {
      console.error("Show info failed", JSON.stringify(e));
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text(`进度: ${this.photos.length > 0 ? Math.min(this.currentIndex + 1, this.photos.length) : 0}/${this.photos.length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button("回收站")
          .onClick((): void => {
            router.pushUrl({ url: 'pages/TrashPage' });
          })
      }
      .width('100%')
      .padding(20)
      .height(60)

      // Main Content
      Stack() {
        if (this.isLoading) {
          LoadingProgress()
        } else if (this.photos.length === 0) {
          Column() {
            Text("未获取到照片或无权限")
              .margin({ bottom: 20 })
            Button("重试/加载")
              .onClick((): void => {
                this.loadPhotos();
              })
          }
        } else if (this.currentIndex >= this.photos.length) {
          // Finished Batch
          Column() {
            Text("本组整理完成!")
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
            Text(`共删除 ${this.removedCount} 张`)
              .fontSize(16)
              .margin({ bottom: 30 })

            Button("再来一组")
              .height(50)
              .width(200)
              .onClick((): void => {
                this.loadPhotos();
              })
          }
        } else {
          // Card Stack
          CardStack({
            photos: $photos,
            currentIndex: $currentIndex,
            removedCount: $removedCount,
            onSwipeDown: (a: photoAccessHelper.PhotoAsset): void => { this.onSwipeDown(a); },
            onSwipeUp: (a: photoAccessHelper.PhotoAsset): void => { this.onSwipeUp(a); },
            onSwipeLeft: (a: photoAccessHelper.PhotoAsset): void => { this.onSwipeLeft(a); }
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}