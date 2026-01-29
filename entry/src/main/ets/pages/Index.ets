import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PhotoService } from '../services/PhotoService';
import { CardStack } from '../components/CardStack';
import { ActionBar } from '../components/ActionBar';
import { AppColors, AppFontSizes, AppSpacing, AppRadius } from '../common/Theme';

@Entry
@Component
struct Index {
  @State photos: Array<photoAccessHelper.PhotoAsset> = [];
  @State currentIndex: number = 0;
  @State removedCount: number = 0;
  @State isLoading: boolean = true;
  @State showGuide: boolean = true;
  private photoService: PhotoService | null = null;

  aboutToAppear(): void {
    let context = getContext(this) as common.UIAbilityContext;
    this.photoService = new PhotoService(context);
    setTimeout((): void => {
      this.loadPhotos();
    }, 800);
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

  async handleDelete(): Promise<void> {
    if (this.currentIndex < this.photos.length && this.photoService) {
      const asset = this.photos[this.currentIndex];
      try {
        await this.photoService.moveToTrash(asset);
        this.removedCount++;
      } catch (err) {
        console.error("Delete failed");
      }
      this.currentIndex++;
    }
  }

  handleKeep(): void {
    if (this.currentIndex < this.photos.length) {
      this.currentIndex++;
    }
  }

  handleInfo(): void {
    if (this.currentIndex < this.photos.length) {
      const asset = this.photos[this.currentIndex];
      let displayName = asset.displayName || '未知文件';
      let dateAdded: number = asset.get(photoAccessHelper.PhotoKeys.DATE_ADDED) as number || 0;
      let dateStr = new Date(dateAdded * 1000).toLocaleString();

      this.getUIContext().showAlertDialog({
        title: '照片详情',
        message: `📁 ${displayName}\n📅 ${dateStr}`,
        confirm: {
          value: '关闭',
          action: (): void => {}
        }
      });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 进度指示
        Stack() {
          Progress({ value: this.currentIndex, total: Math.max(this.photos.length, 1), type: ProgressType.Ring })
            .width(44)
            .height(44)
            .style({ strokeWidth: 4 })
            .color(AppColors.ACCENT_PRIMARY)
            .backgroundColor(AppColors.BG_TERTIARY)

          Text(`${this.currentIndex}`)
            .fontSize(14)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
        }

        Column() {
          Text('Photo Cleaner')
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text(`共 ${this.photos.length} 张`)
            .fontSize(AppFontSizes.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: AppSpacing.MD })

        Blank()

        // 回收站按钮
        Column() {
          Text('🗑️')
            .fontSize(24)
        }
        .width(44)
        .height(44)
        .borderRadius(AppRadius.MD)
        .backgroundColor(AppColors.BG_TERTIARY)
        .justifyContent(FlexAlign.Center)
        .onClick((): void => {
          router.pushUrl({ url: 'pages/TrashPage' });
        })
      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.MD, bottom: AppSpacing.MD })
      .backgroundColor(AppColors.BG_SECONDARY)

      // 主内容区
      Stack() {
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(60)
              .height(60)
              .color(AppColors.ACCENT_PRIMARY)
            Text('加载中...')
              .fontSize(AppFontSizes.BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: AppSpacing.MD })
          }
        } else if (this.photos.length === 0) {
          Column() {
            Text('📷')
              .fontSize(80)
            Text('暂无照片')
              .fontSize(AppFontSizes.TITLE)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .margin({ top: AppSpacing.MD })
            Text('请授予相册访问权限')
              .fontSize(AppFontSizes.BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: AppSpacing.SM })

            Button('重新加载')
              .height(48)
              .width(160)
              .borderRadius(AppRadius.LG)
              .backgroundColor(AppColors.ACCENT_PRIMARY)
              .margin({ top: AppSpacing.XL })
              .onClick((): void => {
                this.loadPhotos();
              })
          }
          .justifyContent(FlexAlign.Center)
        } else if (this.currentIndex >= this.photos.length) {
          // 完成状态
          Column() {
            Text('🎉')
              .fontSize(100)
            Text('整理完成!')
              .fontSize(AppFontSizes.TITLE)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .margin({ top: AppSpacing.MD })
            Text(`本次删除 ${this.removedCount} 张照片`)
              .fontSize(AppFontSizes.BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: AppSpacing.SM })

            Button('再来一组')
              .height(56)
              .width(200)
              .borderRadius(AppRadius.XL)
              .backgroundColor(AppColors.ACCENT_PRIMARY)
              .fontSize(AppFontSizes.SUBTITLE)
              .fontWeight(FontWeight.Bold)
              .margin({ top: AppSpacing.XXL })
              .onClick((): void => {
                this.loadPhotos();
              })
          }
          .justifyContent(FlexAlign.Center)
        } else {
          // 卡片堆叠
          CardStack({
            photos: $photos,
            currentIndex: $currentIndex,
            removedCount: $removedCount,
            onSwipeDown: (a: photoAccessHelper.PhotoAsset): void => { this.handleDelete(); },
            onSwipeUp: (a: photoAccessHelper.PhotoAsset): void => { this.handleKeep(); },
            onSwipeLeft: (a: photoAccessHelper.PhotoAsset): void => { this.handleInfo(); }
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // 底部操作栏 (仅在有照片且未完成时显示)
      if (!this.isLoading && this.photos.length > 0 && this.currentIndex < this.photos.length) {
        ActionBar({
          onDelete: (): void => { this.handleDelete(); },
          onKeep: (): void => { this.handleKeep(); },
          onInfo: (): void => { this.handleInfo(); }
        })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(AppColors.BG_PRIMARY)
  }
}