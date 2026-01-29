/**
 * Index.ets
 * 
 * 主页面 (Main Page)
 * 核心功能：
 * 1. 卡片堆叠交互 (CardStack)：左滑详情，上滑保留，下滑删除。
 * 2. 沉浸式全屏预览 (Immersive Full Screen)：支持共享元素转场。
 * 3. 数据统计 (StatsBar)：实时显示处理进度与结果。
 * 
 * v2.4 更新：
 * - 优化了全屏预览的稳定性 (Crash Fix & Debounce)。
 * - 调整了顶部图标的样式与布局 (UI Polish)。
 * - 实现了智能图片适配策略 (Smart ObjectFit)。
 */
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

  // 全屏预览状态
  @State isFullScreen: boolean = false;
  private lastClickTime: number = 0;

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
      this.checkCompletion();
    }
  }

  async handleKeep(): Promise<void> {
    if (this.currentIndex < this.photos.length) {
      this.totalKept++;
      this.currentIndex++;

      if (this.statsService) {
        await this.statsService.incrementKept();
      }
      this.checkCompletion();
    }
  }

  checkCompletion(): void {
    if (this.currentIndex >= this.photos.length && this.photoService) {
      this.photoService.commitDeletions();
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

  getImageFit(index: number): ImageFit {
    try {
      if (index >= this.photos.length) return ImageFit.Contain;
      const w = this.photos[index].get(photoAccessHelper.PhotoKeys.WIDTH) as number || 0;
      const h = this.photos[index].get(photoAccessHelper.PhotoKeys.HEIGHT) as number || 0;
      // 简单的判断：如果高度 > 宽度，视为竖屏图，使用 Cover 填充
      // 否则（横屏或正方形），使用 Contain 完整显示
      return h > w ? ImageFit.Cover : ImageFit.Contain;
    } catch (err) {
      console.warn(`getImageFit error: ${JSON.stringify(err)}`);
      return ImageFit.Contain;
    }
  }

  build() {
    Stack() {
      // 底层内容
      Column() {
        // 顶部导航栏
        Stack({ alignContent: Alignment.Center }) {
          // 左侧进度
          Row() {
            Stack() {
              Progress({ value: this.currentIndex, total: Math.max(this.photos.length, 1), type: ProgressType.Ring })
                .width(40)
                .height(40)
                .style({ strokeWidth: 3 })
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
            Stack() {
              Progress({ value: 1, total: 1, type: ProgressType.Ring })
                .width(36)
                .height(36)
                .style({ strokeWidth: 2 }) // 更细的圆圈
                .color(AppColors.ACCENT_PRIMARY)
                .backgroundColor(AppColors.BG_TERTIARY)

              // 汉堡菜单图标 (三道杠)
              Column({ space: 3 }) { //稍微减小间距以匹配更小的图标
                Rect().width(12).height(2).fill(AppColors.ACCENT_PRIMARY).radius(2)
                Rect().width(12).height(2).fill(AppColors.ACCENT_PRIMARY).radius(2)
                Rect().width(12).height(2).fill(AppColors.ACCENT_PRIMARY).radius(2)
              }
              .justifyContent(FlexAlign.Center)
            }
            .onClick((): void => {
              this.getUIContext().showAlertDialog({ title: '设置', message: '更多功能敬请期待', confirm: { value: '好', action: ()=>{} } })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)

          // 中间标题
          Text('去留之间')
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.ACCENT_INFO)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: 10, bottom: AppSpacing.MD })

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
            Column() {
              Text('🏆')
                .fontSize(100)
              
              Text('All Clean!')
                .fontSize(36)
                .fontColor(AppColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bolder)
                .margin({ top: AppSpacing.LG })

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
                Button('再来20张')
                  .layoutWeight(1)
                  .height(48)
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

                Button('退出')
                  .layoutWeight(1)
                  .height(48)
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
              .width('80%')
              .justifyContent(FlexAlign.Center)
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
              onSwipeLeft: (a: photoAccessHelper.PhotoAsset): void => { this.handleInfo(); },
              onCardClick: (): void => { 
                this.lastClickTime = Date.now(); // 记录开启时间
                this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                  this.isFullScreen = true; 
                });
              } 
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


      // 全屏预览层 (Overlay)
      if (this.isFullScreen && this.currentIndex < this.photos.length) {
        Stack() {
          Image(this.photos[this.currentIndex].uri)
            .width('100%')
            .height('100%')
            .objectFit(this.getImageFit(this.currentIndex))
            .geometryTransition(this.photos[this.currentIndex].uri) // Shared Element ID
            .transition(TransitionEffect.opacity(1)) // Keep image opaque during transition
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black) // Background for full screen
        .onClick(() => {
          // 防误触：如果距离开启时间太短（500ms），则忽略点击
          if (Date.now() - this.lastClickTime < 500) return;

          this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
            this.isFullScreen = false;
          });
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // Make sure it covers everything
        .transition(TransitionEffect.OPACITY) // Fade in the black background
        .zIndex(999)
      }
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}