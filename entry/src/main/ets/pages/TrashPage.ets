import { PhotoService } from '../services/PhotoService';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';

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
      // Header
      Row() {
        Button("返回")
          .onClick((): void => {
            router.back();
          })
        Text("回收站")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 })
      }
      .width('100%')
      .padding(10)
      .height(50)

      if (this.isLoading) {
        LoadingProgress()
          .layoutWeight(1)
      } else if (this.trashPhotos.length === 0) {
        Column() {
          Text("回收站为空")
            .fontSize(16)
            .fontColor(Color.Grey)
            .margin({ top: 20 })
          Text("已删除的照片请在系统相册中查看")
            .fontSize(14)
            .fontColor(Color.Grey)
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Grid() {
          ForEach(this.trashPhotos, (asset: photoAccessHelper.PhotoAsset) => {
            GridItem() {
              Image(asset.uri)
                .objectFit(ImageFit.Cover)
                .width('100%')
                .aspectRatio(1)
                .borderRadius(8)
                .onClick((): void => {
                  this.getUIContext().showAlertDialog({
                    title: '提示',
                    message: '请在系统相册中恢复照片',
                    confirm: { value: '知道了', action: (): void => {} }
                  });
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(5)
        .rowsGap(5)
        .padding(10)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}
