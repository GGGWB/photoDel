import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PhotoService } from '../services/PhotoService';
import { AppColors, AppFontSizes, AppSpacing, AppRadius } from '../common/Theme';

@Entry
@Component
struct IntroPage {
  @State opacityValue: number = 0;
  @State scaleValue: number = 0.9;
  
  // Gesture State
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State rotateAngle: number = 0;
  @State isAnimating: boolean = false;

  private readonly THRESHOLD: number = 100;

  onPageShow(): void {
    // Attempt preload (idempotent safe) with retries to handle permission timing
    const context = getContext(this) as common.UIAbilityContext;
    PhotoService.preload(context);
    setTimeout(() => { PhotoService.preload(context); }, 1000); // Retry after 1s
    setTimeout(() => { PhotoService.preload(context); }, 3000); // Retry after 3s

    animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
      this.opacityValue = 1;
      this.scaleValue = 1;
    });
  }

  build() {
    Stack() {
      // 1. Background Gradient (Fixed)
      Column()
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

      // 2. Swipeable Poster Card
      Column() {
        // --- Poster Header ---
        Row() {
          Text('照片\n断舍离')
            .fontSize(40)
            .fontWeight(FontWeight.Bolder)
            .fontColor('#1D1D1F') // Ink Black
            .lineHeight(50)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ top: 30, left: 30 }) // Reduced top padding

        // --- Poster Abstract Visuals ---
        Stack() {
          // Decorative Blobs
          Circle({ width: 80, height: 80 })
            .fill('#E0F7FA')
            .position({ x: 0, y: 60 })
            .blur(20)
          
          Circle({ width: 100, height: 100 })
            .fill('#FFF9C4')
            .position({ x: 200, y: 100 })
            .blur(20)

          // Main Icons
          Text('🗑️')
            .fontSize(40)
            .position({ x: 20, y: 150 })
            .rotate({ angle: -15 })

          Text('❤️')
            .fontSize(50)
            .position({ x: 220, y: 40 })
            .rotate({ angle: 15 })
            
          // Central Focus
          Column() {
            Text('📸')
              .fontSize(80)
              .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetY: 10 })
          }
          .width(140)
          .height(140)
          .borderRadius(30)
          .backgroundColor(Color.White)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: 30, color: 'rgba(0,0,0,0.15)', offsetY: 15 })
          .rotate({ angle: 5 })
          .position({ x: 80, y: 60 })
        }
        .width('100%')
        .height(250)
        .margin({ top: 10 }) // Reduced margin

        // --- Gesture Guides (Compact) ---
        Row() {
          Column() {
            Text('👆')
              .fontSize(16)
            Text('保留')
              .fontSize(10)
              .fontColor('#1D1D1F')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 4 })
          }

          Column() {
            Text('👇')
              .fontSize(16)
            Text('删除')
              .fontSize(10)
              .fontColor('#1D1D1F')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 4 })
          }
          
          Column() {
            Text('👈')
              .fontSize(16)
            Text('详情')
              .fontSize(10)
              .fontColor('#1D1D1F')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 4 })
          }
        }
        .width('70%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ top: 5 }) // Reduced margin
        .padding({ top: 6, bottom: 6 }) // Tighter padding

        // --- Slogan ---
        Text('只留心动')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor('#424242')
          .letterSpacing(4)
          .margin({ top: 15 }) // Reduced margin

        Text('Keep what matters.')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 4 }) // Reduced margin
          .fontStyle(FontStyle.Italic)

        Blank()

        // --- Action Hint ---
        Column() {
          Text('SWIPE UP')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#BDBDBD')
            .letterSpacing(2)
          
          Text('上滑开启整理')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1D1D1F')
            .margin({ top: 4 })
        }
        .margin({ bottom: 30 }) // Lifted up
        .onClick(() => {
          this.triggerFlyOut();
        })

      }
      .width('88%') // Slightly narrower like a poster
      .height('78%') // Poster ratio
      .backgroundColor('#FFFFFF') // Paper White
      .borderRadius(24)
      .shadow({ radius: 50, color: 'rgba(0,0,0,0.25)', offsetY: 20 }) // Deep shadow for floating effect
      // Animation & Gesture Transforms
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .opacity(this.opacityValue)
      .translate({ x: this.offsetX, y: this.offsetY })
      .rotate({ angle: this.rotateAngle })
      .gesture(
        PanGesture()
          .onActionUpdate((event?: GestureEvent) => {
            if (event && !this.isAnimating) {
              this.offsetX = event.offsetX;
              this.offsetY = event.offsetY;
              this.rotateAngle = event.offsetX / 20; 
            }
          })
          .onActionEnd(() => {
            if (this.isAnimating) return;
            if (this.offsetY < -this.THRESHOLD) {
              this.triggerFlyOut();
            } else {
              this.animateReset();
            }
          })
      )
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  triggerFlyOut() {
    this.isAnimating = true;
    animateTo({
      duration: 300,
      curve: Curve.EaseIn,
      onFinish: () => {
        router.replaceUrl({ url: 'pages/Index' });
      }
    }, () => {
      this.offsetY = -1000; // Fly up
      this.rotateAngle = this.rotateAngle * 2;
      this.opacityValue = 0;
    });
  }

  animateReset() {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut // Elastic-like return
    }, () => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.rotateAngle = 0;
    });
  }


}
