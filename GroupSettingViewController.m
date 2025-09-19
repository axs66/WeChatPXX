//
//  GroupSettingViewController.m
//  WeChat++
//
//  分组设置视图控制器实现
//  有问题 联系pxx917144686
//

#import "GroupSettingViewController.h"
#import "Config.h"
#import <QuartzCore/QuartzCore.h>

// GroupSettingViewController - Google+微软级别高级彩色交互动画分组设置界面
@interface GroupSettingViewController ()
// 私有方法声明
- (void)setupAdvancedBackgroundGradient;
- (void)setupDynamicHeaderView;
- (void)setupCellAnimationLayers;
- (void)startContinuousAnimations;
- (void)stopContinuousAnimations;
- (void)animationTick:(CADisplayLink *)displayLink;
- (NSArray *)createColorfulGradientColors;
- (void)animateCellSelection:(UITableViewCell *)cell;
@end

@implementation GroupSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupWechatColors];
    [self setupAdvancedBackgroundGradient];
    [self setupDynamicHeaderView];
    [self setupTableView];
    [self setupCellAnimationLayers];
    [self loadGroups];
    [self startContinuousAnimations];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopContinuousAnimations];
}

- (void)setupWechatColors {
    // 设置基础背景色为透明，让渐变层显示
    self.view.backgroundColor = [UIColor clearColor];
    
    // 设置导航栏为深色玻璃效果
    if (self.navigationController) {
        self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.95];
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.2 alpha:1.0];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        // 添加导航栏模糊效果
        if (!self.blurEffectView) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.blurEffectView.frame = self.navigationController.navigationBar.bounds;
            self.blurEffectView.alpha = 0.3;
            [self.navigationController.navigationBar insertSubview:self.blurEffectView atIndex:0];
        }
    }
}

- (void)setupAdvancedBackgroundGradient {
    // 创建高级动态渐变背景
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.frame = self.view.bounds;
    
    // 设置渐变方向为对角线
    self.backgroundGradient.startPoint = CGPointMake(0.0, 0.0);
    self.backgroundGradient.endPoint = CGPointMake(1.0, 1.0);
    
    // 初始彩色渐变
    self.backgroundGradient.colors = [self createColorfulGradientColors];
    
    // 添加渐变位置
    self.backgroundGradient.locations = @[@0.0, @0.25, @0.5, @0.75, @1.0];
    
    [self.view.layer insertSublayer:self.backgroundGradient atIndex:0];
}

- (NSArray *)createColorfulGradientColors {
    // Google Material Design + Microsoft Fluent Design 彩色方案
    return @[
        (id)[UIColor colorWithRed:0.26 green:0.35 blue:0.69 alpha:1.0].CGColor,  // Google Blue
        (id)[UIColor colorWithRed:0.31 green:0.68 blue:0.31 alpha:1.0].CGColor,  // Google Green
        (id)[UIColor colorWithRed:1.0 green:0.76 blue:0.03 alpha:1.0].CGColor,   // Google Yellow
        (id)[UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1.0].CGColor,  // Google Red
        (id)[UIColor colorWithRed:0.61 green:0.15 blue:0.69 alpha:1.0].CGColor   // Microsoft Purple
    ];
}

- (void)setupDynamicHeaderView {
    // 创建动态头部视图
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 120)];
    self.headerView.backgroundColor = [UIColor clearColor];
    
    // 创建头部形状层
    self.headerShapeLayer = [CAShapeLayer layer];
    
    // 创建波浪路径
    UIBezierPath *wavePath = [UIBezierPath bezierPath];
    CGFloat width = self.headerView.frame.size.width;
    CGFloat height = self.headerView.frame.size.height;
    
    [wavePath moveToPoint:CGPointMake(0, height * 0.6)];
    [wavePath addCurveToPoint:CGPointMake(width * 0.5, height * 0.4)
                controlPoint1:CGPointMake(width * 0.25, height * 0.3)
                controlPoint2:CGPointMake(width * 0.35, height * 0.5)];
    [wavePath addCurveToPoint:CGPointMake(width, height * 0.7)
                controlPoint1:CGPointMake(width * 0.65, height * 0.3)
                controlPoint2:CGPointMake(width * 0.85, height * 0.8)];
    [wavePath addLineToPoint:CGPointMake(width, height)];
    [wavePath addLineToPoint:CGPointMake(0, height)];
    [wavePath closePath];
    
    self.headerShapeLayer.path = wavePath.CGPath;
    
    // 设置头部渐变
    CAGradientLayer *headerGradient = [CAGradientLayer layer];
    headerGradient.frame = self.headerView.bounds;
    headerGradient.colors = @[
        (id)[UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.8].CGColor,   // Microsoft Blue
        (id)[UIColor colorWithRed:0.5 green:0.0 blue:1.0 alpha:0.6].CGColor    // Microsoft Purple
    ];
    headerGradient.startPoint = CGPointMake(0.0, 0.0);
    headerGradient.endPoint = CGPointMake(1.0, 1.0);
    headerGradient.mask = self.headerShapeLayer;
    
    [self.headerView.layer addSublayer:headerGradient];
    
    // 添加标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, width - 40, 40)];
    titleLabel.text = @"🎨 分组设置";
    titleLabel.font = [UIFont boldSystemFontOfSize:28];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    // 添加文字阴影
    titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    titleLabel.layer.shadowOffset = CGSizeMake(0, 2);
    titleLabel.layer.shadowOpacity = 0.3;
    titleLabel.layer.shadowRadius = 4;
    
    [self.headerView addSubview:titleLabel];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // 设置头部视图
    self.tableView.tableHeaderView = self.headerView;
    
    // 添加圆角和阴影
    self.tableView.layer.cornerRadius = 20;
    self.tableView.layer.masksToBounds = NO;
    self.tableView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tableView.layer.shadowOffset = CGSizeMake(0, 4);
    self.tableView.layer.shadowOpacity = 0.1;
    self.tableView.layer.shadowRadius = 8;
    
    [self.view addSubview:self.tableView];
}

- (void)setupCellAnimationLayers {
    self.cellAnimationLayers = [[NSMutableArray alloc] init];
}

- (void)startContinuousAnimations {
    // 启动显示链接进行连续动画
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(animationTick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // 启动背景渐变动画
    CABasicAnimation *gradientAnimation = [CABasicAnimation animationWithKeyPath:@"colors"];
    gradientAnimation.duration = 8.0;
    gradientAnimation.repeatCount = HUGE_VALF;
    gradientAnimation.autoreverses = YES;
    
    NSArray *alternateColors = @[
        (id)[UIColor colorWithRed:0.96 green:0.26 blue:0.21 alpha:1.0].CGColor,  // Google Red
        (id)[UIColor colorWithRed:0.61 green:0.15 blue:0.69 alpha:1.0].CGColor,  // Microsoft Purple
        (id)[UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0].CGColor,   // Microsoft Blue
        (id)[UIColor colorWithRed:0.31 green:0.68 blue:0.31 alpha:1.0].CGColor,  // Google Green
        (id)[UIColor colorWithRed:1.0 green:0.76 blue:0.03 alpha:1.0].CGColor    // Google Yellow
    ];
    
    gradientAnimation.toValue = alternateColors;
    [self.backgroundGradient addAnimation:gradientAnimation forKey:@"colorShift"];
    
    // 启动头部波浪动画
    if (self.headerShapeLayer) {
        CABasicAnimation *waveAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
        waveAnimation.duration = 3.0;
        waveAnimation.repeatCount = HUGE_VALF;
        waveAnimation.autoreverses = YES;
        waveAnimation.fromValue = @(-10);
        waveAnimation.toValue = @(10);
        [self.headerShapeLayer addAnimation:waveAnimation forKey:@"waveMotion"];
    }
}

- (void)stopContinuousAnimations {
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [self.backgroundGradient removeAllAnimations];
    [self.headerShapeLayer removeAllAnimations];
}

- (void)animationTick:(CADisplayLink *)displayLink {
    // 更新动画进度
    self.animationProgress += 0.02;
    if (self.animationProgress > 2 * M_PI) {
        self.animationProgress = 0;
    }
    
    // 更新渐变位置以创建流动效果
    CGFloat offset = sin(self.animationProgress) * 0.1;
    self.backgroundGradient.locations = @[
        @(0.0 + offset),
        @(0.25 + offset),
        @(0.5 + offset),
        @(0.75 + offset),
        @(1.0 + offset)
    ];
}

- (void)loadGroups {
    NSArray *groupFilterList = [Config groupFilterList];
    self.groups = [groupFilterList mutableCopy];
    if (!self.groups) {
        self.groups = [@[@"🏢 工作", @"👥 朋友", @"👨‍👩‍👧‍👦 家人", @"🎓 学习", @"🎮 娱乐"] mutableCopy];
        [Config setGroupFilterList:self.groups];
    }
    [self.tableView reloadData];
}

- (void)setupSettingsSwitches {
    // 设置开关逻辑
}

- (void)showGroupSelector {
    // 显示分组选择器
}

- (void)showTagSelector {
    // 显示标签选择器
}

- (void)saveGroups {
    [Config setGroupFilterList:self.groups];
}

- (UIColor *)cellBackgroundColor {
    // 返回半透明白色背景
    return [UIColor colorWithWhite:1.0 alpha:0.9];
}

- (void)animateCellSelection:(UITableViewCell *)cell {
    // Google Material Design 涟漪效果
    CAShapeLayer *rippleLayer = [CAShapeLayer layer];
    rippleLayer.frame = cell.bounds;
    rippleLayer.fillColor = [UIColor colorWithRed:0.26 green:0.35 blue:0.69 alpha:0.3].CGColor;
    
    UIBezierPath *startPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(cell.bounds.size.width/2, cell.bounds.size.height/2, 0, 0)];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(cell.bounds, -50, -50)];
    
    rippleLayer.path = startPath.CGPath;
    [cell.layer insertSublayer:rippleLayer atIndex:0];
    
    // 涟漪扩散动画
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.duration = 0.6;
    pathAnimation.toValue = (__bridge id)endPath.CGPath;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = 0.6;
    opacityAnimation.fromValue = @1.0;
    opacityAnimation.toValue = @0.0;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 0.6;
    group.animations = @[pathAnimation, opacityAnimation];
    group.delegate = self;
    
    [rippleLayer addAnimation:group forKey:@"ripple"];
    
    // 单元格缩放动画
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        cell.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:0 animations:^{
            cell.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"GroupCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        // 设置单元格样式
        cell.backgroundColor = [self cellBackgroundColor];
        cell.layer.cornerRadius = 12;
        cell.layer.masksToBounds = NO;
        cell.layer.shadowColor = [UIColor blackColor].CGColor;
        cell.layer.shadowOffset = CGSizeMake(0, 2);
        cell.layer.shadowOpacity = 0.1;
        cell.layer.shadowRadius = 4;
        
        // 添加渐变边框
        CAGradientLayer *borderGradient = [CAGradientLayer layer];
        borderGradient.frame = CGRectInset(cell.bounds, 1, 1);
        borderGradient.colors = @[
            (id)[UIColor colorWithRed:0.26 green:0.35 blue:0.69 alpha:0.5].CGColor,
            (id)[UIColor colorWithRed:0.61 green:0.15 blue:0.69 alpha:0.5].CGColor
        ];
        borderGradient.startPoint = CGPointMake(0, 0);
        borderGradient.endPoint = CGPointMake(1, 1);
        borderGradient.cornerRadius = 12;
        
        [cell.layer insertSublayer:borderGradient atIndex:0];
    }
    
    cell.textLabel.text = self.groups[indexPath.row];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
    cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self animateCellSelection:cell];
    
    // 添加触觉反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [feedbackGenerator impactOccurred];
    }
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    // 清理动画层
    for (CALayer *layer in self.view.layer.sublayers) {
        if ([layer isKindOfClass:[CAShapeLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
}

@end