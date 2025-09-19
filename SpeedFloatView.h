//
//  SpeedFloatView.h
//  WeChat++
//
//  浮动速度显示视图头文件
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>
#import "FXBlurView.h"

@interface SpeedFloatView : UIView

@property (nonatomic, strong) FXBlurView *blurView;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIView *animationView;
@property (nonatomic, assign) BOOL isLeftSide;

/**
 * 获取单例实例
 */
+ (instancetype)sharedInstance;

/**
 * 显示速度浮窗
 * @param speed 播放速度
 * @param isLeftSide 是否显示在左侧
 */
- (void)showWithSpeed:(float)speed isLeftSide:(BOOL)isLeftSide;

/**
 * 隐藏浮窗
 */
- (void)hide;

/**
 * 开始动画效果
 */
- (void)startAnimation;

/**
 * 获取顶层视图控制器
 */
- (UIViewController *)topViewController;

@end