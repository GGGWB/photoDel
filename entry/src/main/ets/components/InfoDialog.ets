import { AppColors, AppFontSizes, AppRadius, AppSpacing } from '../common/Theme';

@CustomDialog
export struct InfoDialog {
  controller: CustomDialogController;
  
  // Data props
  displayName: string = '';
  dateAdded: string = '';
  fileSize: string = ''; // e.g. "4.5 MB"
  resolution: string = ''; // e.g. "4000x3000"
  filePath: string = ''; // New field
  location: string = '无'; // e.g. "39.9, 116.4" or "无"

  build() {
    Column() {
      // Title
      Text('照片详情')
        .fontSize(AppFontSizes.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: AppSpacing.MD })

      // Content List
      List({ space: AppSpacing.SM }) {
        // Basic Info
        ListItem() { this.InfoRow('📄', '文件名', this.displayName) }
        ListItem() { this.InfoRow('📅', '拍摄时间', this.dateAdded) }
        ListItem() { this.InfoRow('💾', '大小', this.fileSize) }
        ListItem() { this.InfoRow('📐', '分辨率', this.resolution) }
        ListItem() { this.InfoRow('📂', '存储位置', this.filePath, 4) }
        
        if (this.location !== '无') {
             ListItem() { this.InfoRow('📍', '位置', this.location) }
        }
      }
      .width('100%')
      // Removed layoutWeight to let list determine height
      .constraintSize({ maxHeight: '60%' }) // Limit max height

      // Close Button
      Button('关闭')
        .width('100%') // Full width
        .height(40)
        .margin({ top: AppSpacing.LG })
        .backgroundColor('#F5F5F5') // Light gray button
        .fontColor(Color.Blue) // Standard action color
        .onClick(() => {
          this.controller.close();
        })
    }
    .padding(AppSpacing.LG)
    .backgroundColor(Color.White)
    .borderRadius(AppRadius.LG)
    .width('80%') // Slightly smaller fixed width container, or 'auto' behavior
    // To make it truly content sized, we can use constraintSize but usually dialogs need a min width
  }

  @Builder
  InfoRow(icon: string, label: string, value: string, maxLines: number = 2) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: AppSpacing.SM })
        
      Column() {
        Text(label)
          .fontSize(12)
          .fontColor('#666666') // Dark gray label
          .margin({ bottom: 2 })
          
        Text(value)
          .fontSize(14)
          .fontColor(Color.Black)
          .maxLines(maxLines)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 4, bottom: 4 })
  }


}
