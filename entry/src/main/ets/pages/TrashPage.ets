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
      Row() {
        // 返回按钮
        Column() {
          Text('←')
            .fontSize(20)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width(40)
        .height(40)
        .borderRadius(AppRadius.SM)
        .backgroundColor(AppColors.BG_TERTIARY)
        .justifyContent(FlexAlign.Center)
        .onClick((): void => {
          router.back();
        })

        Text("回收站")
          .fontSize(AppFontSizes.SUBTITLE)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ left: AppSpacing.MD })

        Blank()

        Text(`${this.trashPhotos.length} 张`)
          .fontSize(AppFontSizes.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.MD, bottom: AppSpacing.MD })
      .backgroundColor(AppColors.BG_SECONDARY)

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
    .backgroundColor(AppColors.BG_PRIMARY)
  }
}
