import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';

import { PhotoService } from '../services/PhotoService';
import { StatsService } from '../services/StatsService';
import { CardStack } from '../components/CardStack';
import { StatsBar } from '../components/StatsBar';
import { AppColors, AppFontSizes, AppSpacing, AppRadius } from '../common/Theme';

@Entry
@Component
struct Index {
  @State photos: Array<photoAccessHelper.PhotoAsset> = [];
  @State currentIndex: number = 0;
  @State removedCount: number = 0;
  @State isLoading: boolean = true;

  // 相册总数
  @State albumTotal: number = 0;

  // 累计统计 (持久化)
  @State totalProcessed: number = 0;
  @State totalKept: number = 0;
  @State totalDeleted: number = 0;

  private photoService: PhotoService | null = null;
  private statsService: StatsService | null = null;

  aboutToAppear(): void {
    let context = getContext(this) as common.UIAbilityContext;
    this.photoService = new PhotoService(context);
    this.statsService = new StatsService(context);

    this.initStats();
  }

  async initStats(): Promise<void> {
    if (this.statsService) {
      await this.statsService.init();
      this.totalProcessed = await this.statsService.getTotalProcessed();
      this.totalKept = await this.statsService.getTotalKept();
      this.totalDeleted = await this.statsService.getTotalDeleted();
    }

    // 获取相册总数
    if (this.photoService) {
      this.albumTotal = await this.photoService.getAlbumCount();
    }

    setTimeout((): void => {
      this.loadPhotos();
    }, 300);
  }

  async loadPhotos(): Promise<void> {
    this.isLoading = true;
    this.removedCount = 0;
    if (this.photoService) {
      const assets = await this.photoService.getRandomAssets(20);
      this.photos = assets;
      this.currentIndex = 0;

      // 更新已处理总数
      if (this.statsService && assets.length > 0) {
        await this.statsService.addProcessed(assets.length);
        this.totalProcessed = await this.statsService.getTotalProcessed();
      }
    }
    this.isLoading = false;
  }

  async handleDelete(): Promise<void> {
    if (this.currentIndex < this.photos.length && this.photoService) {
      const asset = this.photos[this.currentIndex];
      try {
        await this.photoService.moveToTrash(asset);
        this.removedCount++;
        this.totalDeleted++;
        this.albumTotal--;

        if (this.statsService) {
          await this.statsService.incrementDeleted();
        }
      } catch (err) {
        console.error("Delete failed");
      }
      this.currentIndex++;
    }
  }

  async handleKeep(): Promise<void> {
    if (this.currentIndex < this.photos.length) {
      this.totalKept++;
      this.currentIndex++;

      if (this.statsService) {
        await this.statsService.incrementKept();
      }
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
      // 顶部导航栏
      Stack({ alignContent: Alignment.Center }) {
        // 左侧进度 (绝对定位或在Row中)
        Row() {
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
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 右侧设置菜单
        Row() {
          Image($r('sys.media.ohos_ic_public_more'))
            .width(24)
            .height(24)
            .fillColor(AppColors.ACCENT_PRIMARY)
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .onClick((): void => {
           // 显示设置
           this.getUIContext().showAlertDialog({ title: '设置', message: '更多功能敬请期待', confirm: { value: '好', action: ()=>{} } })
        })
        .width('100%')
        .justifyContent(FlexAlign.End)

        // 中间标题
        Text('去留之间')
          .fontSize(AppFontSizes.SUBTITLE)
          .fontColor(AppColors.ACCENT_INFO)
          .fontWeight(FontWeight.Bold)
          // Removed shadow as requested ("不要外边框")
      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: 10, bottom: AppSpacing.MD })
      // Removed background color and blur as requested

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
        } else if (this.currentIndex >= this.photos.length) {
          // 完成状态
          // 完成状态 (Neon & Glass)
          Column() {
            // 霓虹奖杯
            Text('🏆')
              .fontSize(100)
              // Removed shadow ("不要外边框")
            
            Text('All Clean!')
              .fontSize(36)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bolder)
              .margin({ top: AppSpacing.LG })
              // Removed shadow ("不要外边框")

            Row() {
              Text(`本次清除 ${this.removedCount} 张照片`)
                .fontSize(AppFontSizes.BODY)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .margin({ top: AppSpacing.MD })
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(AppColors.GLASS_BG)
            .borderRadius(AppRadius.FULL)

            // 按钮组
            Row({ space: AppSpacing.LG }) {
              // 再来20张
              Button('再来20张')
                .height(48)
                .padding({ left: 24, right: 24 })
                .borderRadius(AppRadius.FULL)
                .backgroundColor(AppColors.GLASS_BG)
                .backgroundBlurStyle(BlurStyle.Regular)
                .border({ width: 1, color: AppColors.ACCENT_PRIMARY })
                .fontSize(16)
                .fontColor(AppColors.ACCENT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .onClick((): void => {
                  this.loadPhotos();
                })

              // 退出
              Button('退出')
                .height(48)
                .padding({ left: 24, right: 24 })
                .borderRadius(AppRadius.FULL)
                .backgroundColor(AppColors.GLASS_BG)
                .backgroundBlurStyle(BlurStyle.Regular)
                .border({ width: 1, color: AppColors.ACCENT_DELETE })
                .fontSize(16)
                .fontColor(AppColors.ACCENT_DELETE)
                .fontWeight(FontWeight.Bold)
                .onClick((): void => {
                  const context = getContext(this) as common.UIAbilityContext;
                  context.terminateSelf();
                })
            }
            .margin({ top: AppSpacing.XXL })
          }
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
      .alignContent(Alignment.Center)

      // 底部统计栏
      StatsBar({
        albumTotal: this.albumTotal,
        totalProcessed: this.totalProcessed,
        totalKept: this.totalKept,
        totalDeleted: this.totalDeleted
      })
    }
    .height('100%')
    .width('100%')
    .linearGradient({
      angle: 180, // 从上到下
      colors: [
        [AppColors.BG_PRIMARY, 0.0],
        [AppColors.BG_SECONDARY, 0.6],
        [AppColors.BG_TERTIARY, 1.0]
      ]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 全屏沉浸式
  }
}