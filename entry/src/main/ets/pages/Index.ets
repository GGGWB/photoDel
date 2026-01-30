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
 * 
 * v2.5 更新：
 * - 图标极简纯白化 (White & Minimalist Icons)。
 * - 移除了设置图标的外圆装饰。
 * - 统一了所有功能图标的颜色为白色文本色 (TEXT_PRIMARY)。
 * 
 * v3.1 更新：
 * - 新增设置页面 (SettingsPage): 提供数据重置与历史清除功能。
 * - 视觉焕新: 替换了菜单、返回及风险提示图标，优化了布局对齐与间距。
 * - 状态同步: 实现了主页与设置页的数据实时联动，支持“后悔药”机制（重置保留后自动刷新）。
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { router, promptAction } from '@kit.ArkUI';


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

    this.loadPhotos(); // Load photos immediately (parallel)
    this.initStats();
  }

  async onPageShow(): Promise<void> {
    if (this.statsService) {
       const savedKept = await this.statsService.getTotalKept();
       const savedDeleted = await this.statsService.getTotalDeleted();

       // Detect Reset: If local values are greater than saved values, a reset happened.
       if (this.totalKept > 0 && savedKept === 0) {
           // History was cleared, we must reload photos to include previously kept ones
           this.totalKept = 0;
           this.photos = []; 
           this.albumTotal = await this.photoService?.getAlbumCount() || 0;
           await this.loadPhotos();
           promptAction.showToast({ message: '相册列表已刷新', duration: 1000 });
       }
       
       if (this.totalDeleted > 0 && savedDeleted === 0) {
           this.totalDeleted = 0;
           this.removedCount = 0; // Optional: reset current session removed count too?
       }

       // Sync perfectly
       this.totalKept = savedKept;
       this.totalDeleted = savedDeleted;
       this.totalProcessed = await this.statsService.getTotalProcessed();
    }
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
  }

  async loadPhotos(): Promise<void> {
    this.removedCount = 0;
    if (this.photoService) {
      // 优先使用预加载的资源
      const preloaded = PhotoService.consumePreloadedAssets();
      if (preloaded && preloaded.length > 0) {
          this.photos = preloaded;
          this.currentIndex = 0;
          this.isLoading = false;
          console.info('Index: Used preloaded photos instantly');
          return;
      }
    }

    // 没有预加载数据，才显示加载状态并获取
    this.isLoading = true;
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
        this.totalDeleted++;
        this.totalProcessed++; // 增加已处理数
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
      // Mark as seen (persistent history)
      const context = getContext(this) as common.UIAbilityContext;
      const asset = this.photos[this.currentIndex];
      await PhotoService.markAsSeen(context, asset.uri);

      this.totalKept++;
      this.totalProcessed++; // 增加已处理数
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
        // 顶部导航栏
        Row() {
          // 左侧进度
          Stack() {
            Progress({ value: this.currentIndex, total: Math.max(this.photos.length, 1), type: ProgressType.Ring })
              .width(40)
              .height(40)
              .style({ strokeWidth: 3 })
              .color(AppColors.ACCENT_KEEP)
              .backgroundColor(AppColors.BG_TERTIARY)

            Text(`${this.currentIndex}`)
              .fontSize(14)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
          }

          // 右侧设置菜单
          Stack() {
            Image($r('app.media.ic_menu'))
              .width(22)
              .height(22)
              .fillColor(AppColors.TEXT_PRIMARY)
          }
          .onClick((): void => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
          .padding({ right: 4 }) // Keep original padding if needed, or remove if alignment requires it. Keeping it.
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center) // Critical for center alignment
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
            // 空状态处理
            if (this.albumTotal > 0) {
              // Case 1: 有照片但都被过滤了 (All Caught Up)
              Column() {
                Text('🎉')
                  .fontSize(80)
                Text('全部看完啦')
                  .fontSize(AppFontSizes.TITLE)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: AppSpacing.MD })
                Text('所有照片都已整理完毕')
                  .fontSize(AppFontSizes.BODY)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .margin({ top: AppSpacing.SM })

                // Optional: Provide a way to restart logic or verify
                 Button('刷新检查')
                  .height(48)
                  .width(160)
                  .borderRadius(AppRadius.LG)
                  .backgroundColor(AppColors.BG_TERTIARY)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .margin({ top: AppSpacing.XL })
                  .onClick((): void => {
                    this.loadPhotos();
                  })
              }
            } else {
              // Case 2: 系统真的没照片 (或无权限)
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

              // 按钮组 (Monochrome Clean Style)
              Row({ space: AppSpacing.LG }) {
                // Primary Action: White Solid
                Button('再来20张')
                  .layoutWeight(1)
                  .height(48)
                  .borderRadius(AppRadius.FULL)
                  .backgroundColor(Color.White) // Solid White
                  .fontSize(16)
                  .fontColor(Color.Black) // Dark Text
                  .fontWeight(FontWeight.Bold)
                  .onClick((): void => {
                    this.loadPhotos();
                  })

                // Secondary Action: Glass Outline
                Button('退出')
                  .layoutWeight(1)
                  .height(48)
                  .borderRadius(AppRadius.FULL)
                  .backgroundColor(AppColors.GLASS_BG)
                  .backgroundBlurStyle(BlurStyle.Regular)
                  .border({ width: 1, color: 'rgba(255,255,255,0.3)' }) // Subtle White Border
                  .fontSize(16)
                  .fontColor(Color.White) // White Text
                  .fontWeight(FontWeight.Medium)
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
            .offset({ y: -10 }) // Move whole card stack up by 10vp (relative to original)
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