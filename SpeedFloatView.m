//
//  SpeedFloatView.m
//  WeChat++
//
//  速度浮动视图实现
//  有问题 联系pxx917144686
//

#import "SpeedFloatView.h"
#import "pop/POP.h"
#import "fxblurview/FXBlurView.h"

@implementation SpeedFloatView

static SpeedFloatView *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SpeedFloatView alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.alpha = 0.0;
    self.frame = CGRectMake(0, 0, 80, 50);
    
    // 设置圆角和边框，使用更大的圆角值创建胶囊形状
    self.layer.cornerRadius = 25.0;
    self.clipsToBounds = YES;
    
    // 创建模糊背景
    _blurView = [[FXBlurView alloc] initWithFrame:self.bounds];
    _blurView.blurRadius = 10.0;
    _blurView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
    _blurView.layer.cornerRadius = 25.0;
    [self addSubview:_blurView];
    
    // 创建速度标签
    _speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 44, 34)];
    _speedLabel.textColor = [UIColor whiteColor];
    _speedLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    _speedLabel.textAlignment = NSTextAlignmentCenter;
    _speedLabel.text = @"1.0x";
    [self addSubview:_speedLabel];
    
    // 创建动画视图容器
    _animationView = [[UIView alloc] initWithFrame:CGRectMake(54, 12, 24, 26)];
    [self addSubview:_animationView];
    
    // 创建动画点
    [self createAnimationDots];
}

- (void)createAnimationDots {
    // 清除现有的动画点
    for (UIView *subview in _animationView.subviews) {
        [subview removeFromSuperview];
    }
    
    // 创建3x3的动画点网格，适配新的容器尺寸24x26
    int dotCount = 0;
    for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
            UIView *dotView = [[UIView alloc] init];
            dotView.frame = CGRectMake(col * 6 + 3, row * 6 + 4, 3, 3);
            dotView.backgroundColor = [UIColor whiteColor];
            dotView.layer.cornerRadius = 1.5;
            dotView.alpha = 0.3;
            dotView.tag = 100 + dotCount; // 标签从100开始
            [_animationView addSubview:dotView];
            dotCount++;
        }
    }
}

- (void)showWithSpeed:(float)speed isLeftSide:(BOOL)isLeftSide {
    self.isLeftSide = isLeftSide;
    
    // 更新速度文本
    _speedLabel.text = [NSString stringWithFormat:@"%.1fx", speed];
    
    // 获取顶层视图控制器
    UIViewController *topVC = [self topViewController];
    if (!topVC || !topVC.view) {
        return;
    }
    
    // 移除之前的视图
    [self removeFromSuperview];
    
    // 计算位置
    CGFloat screenWidth = topVC.view.bounds.size.width;
    CGFloat screenHeight = topVC.view.bounds.size.height;
    CGFloat margin = 20.0;
    CGFloat yPosition = screenHeight * 0.3; // 屏幕30%位置
    
    if (isLeftSide) {
        self.frame = CGRectMake(margin, yPosition, 80, 50);
    } else {
        self.frame = CGRectMake(screenWidth - 80 - margin, yPosition, 80, 50);
    }
    
    // 添加到顶层视图
    [topVC.view addSubview:self];
    
    // 显示动画
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
    
    // 开始动画效果
    [self startAnimation];
    
    // 3秒后自动隐藏
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
    [self performSelector:@selector(hide) withObject:nil afterDelay:3.0];
}

- (void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self stopAnimation];
    }];
}

- (UIViewController *)topViewController {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (void)startAnimation {
    // 移除所有现有Pop动画
    [self.animationView pop_removeAllAnimations];
    
    // 使用Pop库为每个动画点添加流畅的闪烁动画
    for (int i = 100; i <= 108; i++) { // 修正范围为9个点
        UIView *dotView = [self.animationView viewWithTag:i];
        if (dotView) {
            // 创建Pop弹性缩放动画
            POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
            scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.2, 1.2)];
            scaleAnimation.springBounciness = 15.0;
            scaleAnimation.springSpeed = 8.0;
            scaleAnimation.autoreverses = YES;
            scaleAnimation.repeatForever = YES;
            
            // 添加延迟以创建波浪效果
            scaleAnimation.beginTime = CACurrentMediaTime() + (i - 100) * 0.05;
            
            [dotView pop_addAnimation:scaleAnimation forKey:@"pulseAnimation"];
            
            // 添加透明度动画
            POPBasicAnimation *alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
            alphaAnimation.fromValue = @(0.3);
            alphaAnimation.toValue = @(1.0);
            alphaAnimation.duration = 0.8;
            alphaAnimation.autoreverses = YES;
            alphaAnimation.repeatForever = YES;
            alphaAnimation.beginTime = CACurrentMediaTime() + (i - 100) * 0.03;
            
            [dotView pop_addAnimation:alphaAnimation forKey:@"alphaAnimation"];
        }
    }
}

- (void)stopAnimation {
    // 停止所有Pop动画
    [self.animationView pop_removeAllAnimations];
    
    // 重置所有动画点的状态
    for (int i = 100; i <= 108; i++) {
        UIView *dotView = [self.animationView viewWithTag:i];
        if (dotView) {
            dotView.alpha = 0.3;
            dotView.transform = CGAffineTransformIdentity;
        }
    }
}

@end