/**
 * SettingsPage.ets
 * 
 * 设置页面 (v3.1)
 * 功能：
 * 1. 重置删除统计 (无风险)
 * 2. 重置保留历史 (高风险，需二次确认)
 */
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppColors, AppFontSizes, AppSpacing, AppRadius } from '../common/Theme';
import { StatsService } from '../services/StatsService';
import { PhotoService } from '../services/PhotoService';

@Entry
@Component
struct SettingsPage {
  @State totalDeleted: number = 0;
  @State totalKept: number = 0;
  private statsService: StatsService | null = null;
  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.statsService = new StatsService(this.context);
    this.initStats();
  }

  async initStats() {
    if (this.statsService) {
      await this.statsService.init();
      this.totalDeleted = await this.statsService.getTotalDeleted();
      this.totalKept = await this.statsService.getTotalKept();
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_public_back')) // System back icon usually available, or text
          .width(17)
          .height(17)
          .fillColor(AppColors.TEXT_PRIMARY)
          .onClick(() => {
            router.back();
          })
        
        Text('设置')
          .fontSize(17)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ left: AppSpacing.MD })
      }
      .width('100%')
      .padding({ top: 10, left: AppSpacing.LG, right: AppSpacing.LG, bottom: AppSpacing.MD })
      .alignItems(VerticalAlign.Center)

      // 选项列表
      Column({ space: AppSpacing.LG }) {
        
        // 1. 重置删除数据 (Safe)
        Column() {
          Row() {
            Column() {
              Text('重置删除计数')
                .fontSize(16)
                .fontColor(AppColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Text(`当前: ${this.totalDeleted}`)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Button('重置')
              .height(32)
              .fontSize(14)
              .backgroundColor(AppColors.BG_TERTIARY)
              .fontColor(AppColors.TEXT_PRIMARY)
              .onClick(async () => {
                if (this.statsService) {
                  await this.statsService.resetDeleted();
                  this.totalDeleted = 0;
                  promptAction.showToast({
                    message: '删除统计已重置',
                    duration: 2000
                  }); 
                }
              })
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .backgroundColor(AppColors.GLASS_BG)
          .borderRadius(AppRadius.MD)
        }

        // 2. 重置保留历史 (Dangerous)
        Column() {
          Row() {
            Column() {
              Row({ space: 6 }) {
                Text('重置保留数据')
                  .fontSize(16)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Medium)
                
                // 警告图标 (User Provided)
                Image($r('app.media.ic_risk'))
                  .width(17)
                  .height(17)
                  .onClick(() => {
                    AlertDialog.show({
                        title: '风险提示',
                        message: '这项操作会清除所有照片的“已阅”状态。\n\n这意味着，您以前整理过并选择“保留”的照片，可能会再次出现在待处理列表中。',
                        confirm: { value: '知道了', action: () => {} }
                    })
                  })
              }

              Text(`当前: ${this.totalKept}`)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Button('重置')
              .height(32)
              .fontSize(14)
              .backgroundColor('rgba(255, 0, 0, 0.2)') // Red tint
              .fontColor(Color.Red)
              .onClick(() => {
                 // Second Confirmation
                 AlertDialog.show({
                     title: '确定要重置吗？',
                     message: '此操作不可撤销。\n您的历史记录将被清空。',
                     primaryButton: {
                         value: '取消',
                         action: () => {}
                     },
                     secondaryButton: {
                         value: '确定重置',
                         fontColor: Color.Red,
                         action: async () => {
                             if (this.statsService && this.context) {
                                 await this.statsService.resetKept();
                                 await PhotoService.clearHistory(this.context);
                                 this.totalKept = 0;
                                 promptAction.showToast({
                                   message: '历史记录已清空',
                                   duration: 2000
                                 });
                             }
                         }
                     }
                 })
              })
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .backgroundColor(AppColors.GLASS_BG)
          .borderRadius(AppRadius.MD)
          .border({ width: 1, color: 'rgba(255,0,0,0.1)' })
        }

      }
      .padding(AppSpacing.LG)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180, 
      colors: [
        [AppColors.BG_PRIMARY, 0.0],
        [AppColors.BG_SECONDARY, 0.6],
        [AppColors.BG_TERTIARY, 1.0]
      ]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
