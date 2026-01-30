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
  @State isSelectMode: boolean = false;
  @State selectedUris: Array<string> = [];
  
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
    this.isSelectMode = false;
    this.selectedUris = [];
  }

  toggleSelection(uri: string): void {
    if (this.selectedUris.includes(uri)) {
      this.selectedUris = this.selectedUris.filter(u => u !== uri);
    } else {
      this.selectedUris.push(uri);
    }
  }

  getSelectedAssets(): Array<photoAccessHelper.PhotoAsset> {
    return this.trashPhotos.filter(asset => this.selectedUris.includes(asset.uri));
  }

  async handleRecover(): Promise<void> {
    const selected = this.getSelectedAssets();
    if (selected.length === 0 || !this.photoService) return;

    try {
      await this.photoService.recoverAssets(selected);
      // Give system time to process, then reload
      setTimeout(() => {
        this.loadTrash();
              this.getUIContext().showAlertDialog({
        title: '已恢复',
        message: `成功恢复 ${selected.length} 张照片`,
        confirm: { value: '好的', action: ()=>{} }
      });
      }, 500);
    } catch (err) {
      this.getUIContext().showAlertDialog({ title: '操作失败', message: '请检查权限或重试', confirm: { value: '关闭', action: ()=>{} } });
    }
  }

  async handleDelete(): Promise<void> {
    const selected = this.getSelectedAssets();
    if (selected.length === 0 || !this.photoService) return;

    this.getUIContext().showAlertDialog({
      title: '彻底删除',
      message: `确定要永久删除这 ${selected.length} 张照片吗？此操作无法撤销。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppColors.ACCENT_DELETE,
        action: async () => {
          try {
            if (this.photoService) {
              await this.photoService.deleteAssetsPermanently(selected);
              setTimeout(() => {
                this.loadTrash();
              }, 500);
            }
          } catch (err) {
             // Ignore error
          }
        }
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部导航栏
        Stack({ alignContent: Alignment.Center }) {
          // 左侧返回按钮
          Row() {
            Column() {
              Text('←')
                .fontSize(24)
                .fontColor(AppColors.ACCENT_PRIMARY)
                .fontWeight(FontWeight.Bold)
            }
            .width(44)
            .height(44)
            .justifyContent(FlexAlign.Center)
            .onClick((): void => {
              if (this.isSelectMode) {
                  this.isSelectMode = false;
                  this.selectedUris = [];
              } else {
                  router.back();
              }
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          // 中间标题
          Text(this.isSelectMode ? `已选择 ${this.selectedUris.length}` : "回收站")
            .fontSize(AppFontSizes.SUBTITLE)
            .fontColor(AppColors.ACCENT_INFO)
            .fontWeight(FontWeight.Bold)

          // 右侧选择按钮
          if (!this.isLoading && this.trashPhotos.length > 0) {
              Row() {
                  Text(this.isSelectMode ? '取消' : '选择')
                      .fontSize(16)
                      .fontColor(AppColors.TEXT_PRIMARY)
                      .onClick(() => {
                          this.isSelectMode = !this.isSelectMode;
                          this.selectedUris = [];
                      })
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
          }
        }
        .width('100%')
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: 10, bottom: AppSpacing.MD })

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
            Text('这里会显示系统相册最近删除的内容')
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
                Stack({ alignContent: Alignment.TopEnd }) {
                    Image(asset.uri)
                      .objectFit(ImageFit.Cover)
                      .width('100%')
                      .height('100%')
                      .borderRadius(AppRadius.SM)
                      .opacity(this.isSelectMode && !this.selectedUris.includes(asset.uri) ? 0.6 : 1.0)
                    
                    if (this.isSelectMode) {
                        if (this.selectedUris.includes(asset.uri)) {
                            // Checkmark
                             Stack() {
                                 Circle({ width: 24, height: 24 })
                                    .fill(AppColors.ACCENT_PRIMARY)
                                 Text('✓')
                                    .fontSize(14)
                                    .fontColor(Color.White)
                             }
                             .margin({ top: 4, right: 4 })
                        } else {
                            // Empty Circle
                             Circle({ width: 24, height: 24 })
                                .stroke(Color.White)
                                .strokeWidth(2)
                                .fill(Color.Transparent)
                                .margin({ top: 4, right: 4 })
                        }
                    }
                }
              }
              .aspectRatio(1)
              .onClick((): void => {
                if (this.isSelectMode) {
                    this.toggleSelection(asset.uri);
                } else {
                    // Preview (Simplified)
                    this.isSelectMode = true;
                    this.toggleSelection(asset.uri);
                }
              })
              .gesture(
                  LongPressGesture().onAction(() => {
                      if (!this.isSelectMode) {
                          this.isSelectMode = true;
                          this.toggleSelection(asset.uri);
                      }
                  })
              )
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(AppSpacing.SM)
          .rowsGap(AppSpacing.SM)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 80 }) // Bottom padding for toolbar
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')

      // 底部操作栏
      if (this.isSelectMode && this.selectedUris.length > 0) {
          Row() {
              // 恢复按钮
              Button('恢复')
                .layoutWeight(1)
                .height(44)
                .backgroundColor(AppColors.GLASS_BG)
                .fontColor(AppColors.ACCENT_KEEP)
                .backgroundBlurStyle(BlurStyle.Regular)
                .onClick(() => { this.handleRecover(); })
              
              Blank().width(AppSpacing.MD)

              // 删除按钮
              Button('彻底删除')
                .layoutWeight(1)
                .height(44)
                .backgroundColor(AppColors.GLASS_BG)
                .fontColor(AppColors.ACCENT_DELETE)
                .backgroundBlurStyle(BlurStyle.Regular)
                .onClick(() => { this.handleDelete(); })
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .backgroundColor(AppColors.GLASS_BG)
          .backgroundBlurStyle(BlurStyle.Thick)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
