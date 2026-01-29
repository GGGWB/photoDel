import { PhotoService } from '../services/PhotoService';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppColors, AppFontSizes, AppSpacing, AppRadius } from '../common/Theme';

@Entry
@Component
struct TrashPage {
  @State trashPhotos: Array<photoAccessHelper.PhotoAsset> = [];
  @State isLoading: boolean = true;
  private photoService: PhotoService | null = null;

  aboutToAppear(): void {
    let context = getContext(this) as common.UIAbilityContext;
    this.photoService = new PhotoService(context);
    this.loadTrash();
  }

  async loadTrash(): Promise<void> {
    this.isLoading = true;
    if (this.photoService) {
      this.trashPhotos = await this.photoService.getTrashAssets();
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // 顶部导航栏
      Stack({ alignContent: Alignment.Center }) {
        // 左侧返回按钮
        Row() {
          Column() {
            Text('←')
              .fontSize(24) // Slightly larger for better clickability
              .fontColor(AppColors.ACCENT_PRIMARY) // Neon accent
              .fontWeight(FontWeight.Bold)
          }
          .width(44)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .onClick((): void => {
            router.back();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 中间标题
        Text("回收站")
          .fontSize(AppFontSizes.SUBTITLE)
          .fontColor(AppColors.ACCENT_INFO) // Match Index Title Color
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: 10, bottom: AppSpacing.MD }) // 调整顶部距离
      // Removed background color as requested

      // 内容区
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(60)
            .height(60)
            .color(AppColors.ACCENT_PRIMARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.trashPhotos.length === 0) {
        Column() {
          Text('🗑️')
            .fontSize(64)
            .opacity(0.3)
          Text('回收站为空')
            .fontSize(AppFontSizes.TITLE)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: AppSpacing.MD })
          Text('已删除的照片在系统相册中')
            .fontSize(AppFontSizes.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: AppSpacing.SM })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Grid() {
          ForEach(this.trashPhotos, (asset: photoAccessHelper.PhotoAsset) => {
            GridItem() {
              Image(asset.uri)
                .objectFit(ImageFit.Cover)
                .width('100%')
                .height('100%')
                .borderRadius(AppRadius.SM)
            }
            .aspectRatio(1)
            .onClick((): void => {
              this.getUIContext().showAlertDialog({
                title: '恢复照片',
                message: '请在系统相册中恢复已删除的照片',
                confirm: { value: '知道了', action: (): void => {} }
              });
            })
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(AppSpacing.SM)
        .rowsGap(AppSpacing.SM)
        .padding(AppSpacing.MD)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180, // 从上到下
      colors: [
        [AppColors.BG_PRIMARY, 0.0],
        [AppColors.BG_SECONDARY, 0.6],
        [AppColors.BG_TERTIARY, 1.0]
      ]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 沉浸式：延伸至状态栏和底部
  }
}
