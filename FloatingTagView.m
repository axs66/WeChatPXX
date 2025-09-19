//
//  FloatingTagView.m
//  WeChat++
//
//  微信主界面悬浮标签视图实现 - 搜索栏下方标签视图
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>
#import "FloatingTagView.h"
#import "masonry/Masonry.h"
#import "pop/POP.h"
#import "SessionInfo.h"

@interface FloatingTagView ()
@property (nonatomic, strong) UIView *parentView;
- (UIView *)findSearchBarInView:(UIView *)view;
- (void)autoScrollToNext;
- (void)tagButtonTouchDown:(UIButton *)sender;
- (void)tagButtonTouchUp:(UIButton *)sender;
- (void)notifyMainFrameItemViewFiltering:(NSInteger)selectedIndex;
- (void)updateCapsuleText:(NSString *)tagName;
@end

@implementation FloatingTagView

+ (instancetype)sharedInstance {
    static FloatingTagView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FloatingTagView alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.alpha = 0.0;
        self.selectedIndex = -1;
        self.isVisible = NO;
        
        // 设置胶囊按钮基本样式
        self.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
        
        // 胶囊内的文字标签（只显示文字）
        UILabel *capsuleLabel = [[UILabel alloc] init];
        capsuleLabel.textColor = [UIColor blackColor];
        capsuleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        capsuleLabel.textAlignment = NSTextAlignmentCenter;
        capsuleLabel.tag = 1001;
        [self addSubview:capsuleLabel];
        
        // 使用Masonry设置标签约束
        [capsuleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        // 初始化胶囊状态数组
        self.capsuleStates = @[
            @{@"title": @"主要", @"color": [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0], @"icon": @"person.fill"},
            @{@"title": @"交易", @"color": [UIColor colorWithRed:0.2 green:0.78 blue:0.35 alpha:1.0], @"icon": @"creditcard.fill"},
            @{@"title": @"更新", @"color": [UIColor colorWithRed:0.69 green:0.32 blue:0.87 alpha:1.0], @"icon": @"arrow.clockwise"},
            @{@"title": @"推广", @"color": [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0], @"icon": @"megaphone.fill"},
            @{@"title": @"所有内容", @"color": [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.9], @"icon": @"envelope.fill"}
        ];
        
        self.currentStateIndex = 0;
        
        // 设置初始状态
        [self updateCapsuleToState:0 animated:NO];
        
        // 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(capsuleTapped:)];
        [self.selectionIndicator addGestureRecognizer:tapGesture];
        
        // 初始化标签按钮数组
        self.tagButtons = [[NSMutableArray alloc] init];
        
        // 设置Apple风格动画
        [self setupAppleStyleAnimations];
        
        // 初始化完成
    }
    return self;
}

// 更新胶囊按钮到指定状态
- (void)updateCapsuleToState:(NSInteger)stateIndex animated:(BOOL)animated {
    if (stateIndex >= self.capsuleStates.count) return;
    
    NSDictionary *state = self.capsuleStates[stateIndex];
    UIColor *newColor = state[@"color"];
    NSString *newTitle = state[@"title"];
    NSString *iconName = state[@"icon"];
    
    UILabel *capsuleLabel = [self.selectionIndicator viewWithTag:1001];
    UIImageView *capsuleIcon = [self.selectionIndicator viewWithTag:1000];
    
    if (animated) {
        // 使用Core Animation实现平滑过渡
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.selectionIndicator.backgroundColor = newColor;
            capsuleLabel.text = newTitle;
            if (@available(iOS 13.0, *)) {
                capsuleIcon.image = [UIImage systemImageNamed:iconName];
            }
        } completion:nil];
    } else {
        self.selectionIndicator.backgroundColor = newColor;
        capsuleLabel.text = newTitle;
        if (@available(iOS 13.0, *)) {
            capsuleIcon.image = [UIImage systemImageNamed:iconName];
        }
    }
}

// 胶囊按钮点击事件
- (void)capsuleTapped:(UITapGestureRecognizer *)gesture {
    self.currentStateIndex = (self.currentStateIndex + 1) % self.capsuleStates.count;
    [self updateCapsuleToState:self.currentStateIndex animated:YES];
}

- (void)setupAppleStyleAnimations {
    // 创建弹跳动画 - 使用CASpringAnimation替代POPSpringAnimation
    if (@available(iOS 9.0, *)) {
        CASpringAnimation *bounceAnimation = [CASpringAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.fromValue = @0.8;
        bounceAnimation.toValue = @1.0;
        bounceAnimation.mass = 1.0;
        bounceAnimation.stiffness = 300.0;
        bounceAnimation.damping = 15.0;
        bounceAnimation.duration = 0.6;
        self.bounceAnimation = bounceAnimation;
    }
    
    // 创建渐变层
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[
        (id)[UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.98 green:0.98 blue:1.0 alpha:1.0].CGColor
    ];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    [self.containerView.layer insertSublayer:self.gradientLayer atIndex:0];
    
    // 创建阴影层
    self.shadowLayer = [CAShapeLayer layer];
    self.shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowLayer.shadowOffset = CGSizeMake(0, 2);
    self.shadowLayer.shadowOpacity = 0.1;
    self.shadowLayer.shadowRadius = 8;
    [self.containerView.layer insertSublayer:self.shadowLayer atIndex:0];
}

- (void)setupAdvancedAnimations {
    // 兼容旧代码 - 调用新的Apple风格动画设置
    [self setupAppleStyleAnimations];
}

- (void)embedInSearchBar:(UIView *)searchBar {
    if (!searchBar) {
        // 搜索栏为空，无法嵌入
        return;
    }
    
    // 移除之前的视图
    [self removeFromSuperview];
    
    // 直接添加到搜索栏内部
    [searchBar addSubview:self];
    
    // 设置约束，嵌入搜索栏右侧内部
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(searchBar).offset(-12);
        make.centerY.equalTo(searchBar);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(28);
    }];
    
    // 容器视图已简化，不需要额外约束
    
    // 调整胶囊按钮样式以适应搜索栏内部
    self.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    self.layer.cornerRadius = 14;
    self.layer.masksToBounds = YES;
    
    // 成功嵌入搜索栏内部
}

- (void)showInView:(UIView *)parentView {
    if (self.isVisible) return;
    
    // 首先尝试嵌入搜索栏
    UIView *searchBar = [self findSearchBarInView:parentView];
    if (searchBar) {
        [self embedInSearchBar:searchBar];
        return;
    }
    
    // Apple风格独立显示方式
    [parentView addSubview:self];
    
    // 计算顶部偏移
    CGFloat topOffset = 0;
    if (@available(iOS 11.0, *)) {
        topOffset = parentView.safeAreaInsets.top + 10;
    } else {
        topOffset = 30;
    }
    
    self.frame = CGRectMake(0, topOffset, parentView.bounds.size.width, 80);
    
    // Apple风格显示动画 - 从上方优雅滑入
    self.transform = CGAffineTransformMakeTranslation(0, -80);
    self.alpha = 0.0;
    
    self.isVisible = YES;
    
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (finished) {
            // 添加Apple风格弹性动画
            [self.containerView.layer addAnimation:self.bounceAnimation forKey:@"appleStyleBounce"];
        }
    }];
}

- (void)updateTags:(NSArray *)tags {
    if (!tags || tags.count == 0) {
        // 标签数组为空
        return;
    }
    
    self.tags = tags;
    
    // 清除现有按钮
    for (UIButton *button in self.tagButtons) {
        [button removeFromSuperview];
    }
    [self.tagButtons removeAllObjects];
    
    // 创建新的标签按钮
    CGFloat buttonWidth = 80;
    CGFloat buttonHeight = 32;
    CGFloat spacing = 12;
    
    for (NSInteger i = 0; i < tags.count; i++) {
        NSString *tagName = tags[i];
        [self createTagButton:tagName atIndex:i];
    }
    
    // 设置滚动视图内容大小
    CGFloat contentWidth = tags.count * (buttonWidth + spacing) - spacing + 24;
    self.scrollView.contentSize = CGSizeMake(contentWidth, buttonHeight + 16);
    
    // 更新了标签
}

- (void)createTagButton:(NSString *)tagName atIndex:(NSInteger)index {
    UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat buttonWidth = 80;
    CGFloat buttonHeight = 32;
    CGFloat spacing = 12;
    
    tagButton.frame = CGRectMake(index * (buttonWidth + spacing), 8, buttonWidth, buttonHeight);
    tagButton.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    tagButton.layer.cornerRadius = 16;
    tagButton.tag = index;
    
    [tagButton setTitle:tagName forState:UIControlStateNormal];
    [tagButton setTitleColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
    [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    tagButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    
    // 添加触摸事件
    [tagButton addTarget:self action:@selector(tagButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [tagButton addTarget:self action:@selector(tagButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [tagButton addTarget:self action:@selector(tagButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [tagButton addTarget:self action:@selector(tagButtonTouchUp:) forControlEvents:UIControlEventTouchCancel];
    
    [self.scrollView addSubview:tagButton];
    [self.tagButtons addObject:tagButton];
}

- (void)recreateTagsForSearchBar {
    // 清除现有标签
    for (UIButton *button in self.tagButtons) {
        [button removeFromSuperview];
    }
    [self.tagButtons removeAllObjects];
    
    // 创建适合搜索栏的小尺寸标签
    NSArray *tags = @[@"全部", @"群聊", @"公众号", @"重要"];
    CGFloat xOffset = 6;
    
    for (NSInteger i = 0; i < tags.count; i++) {
        NSString *tagName = tags[i];
        UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [tagButton setTitle:tagName forState:UIControlStateNormal];
        tagButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium]; // 更小字体
        tagButton.tag = i;
        
        // 计算小尺寸按钮宽度
        CGSize textSize = [tagName sizeWithAttributes:@{NSFontAttributeName: tagButton.titleLabel.font}];
        CGFloat buttonWidth = MAX(textSize.width + 14, 36); // 更紧凑适配
        tagButton.frame = CGRectMake(xOffset, 1, buttonWidth, 18); // 适配22pt容器高度
        
        // 设置搜索栏内部按钮样式
        tagButton.backgroundColor = [UIColor clearColor];
        [tagButton setTitleColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
        [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        tagButton.layer.cornerRadius = 9;
        tagButton.layer.masksToBounds = YES;
        
        // 更细的边框
        tagButton.layer.borderWidth = 0.3;
        tagButton.layer.borderColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.6].CGColor;
        
        // 添加点击事件
        [tagButton addTarget:self action:@selector(tagButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [tagButton addTarget:self action:@selector(tagButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [tagButton addTarget:self action:@selector(tagButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [tagButton addTarget:self action:@selector(tagButtonTouchUp:) forControlEvents:UIControlEventTouchCancel];
        
        [self.scrollView addSubview:tagButton];
        [self.tagButtons addObject:tagButton];
        
        xOffset += buttonWidth + 8; // 更小间距
    }
    
    // 更新滚动视图内容大小
    self.scrollView.contentSize = CGSizeMake(MAX(xOffset, self.scrollView.frame.size.width + 12), 22);
    
    // 调整选择指示器尺寸
    self.selectionIndicator.frame = CGRectMake(0, 0, 36, 18);
    self.selectionIndicator.layer.cornerRadius = 9;
    
    // 初始选中第一个标签
    if (tags.count > 0) {
        [self animateSelectionToIndex:0];
    }
}

- (void)createAppleStyleIcons:(UIView *)container {
    // Apple风格圆形图标数据
    NSArray *iconData = @[
        @{@"icon": @"👤", @"title": @"联系人"},
        @{@"icon": @"🛒", @"title": @"购物"},
        @{@"icon": @"💬", @"title": @"消息"},
        @{@"icon": @"📢", @"title": @"通知"}
    ];
    
    CGFloat iconSize = 40;
    CGFloat spacing = 8;
    
    for (int i = 0; i < iconData.count; i++) {
        NSDictionary *data = iconData[i];
        
        // 创建圆形按钮容器
        UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
        iconButton.frame = CGRectMake(i * (iconSize + spacing), 0, iconSize, iconSize);
        iconButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.92 alpha:1.0];
        iconButton.layer.cornerRadius = iconSize / 2;
        iconButton.tag = i;
        
        // Apple风格阴影
        iconButton.layer.shadowColor = [UIColor blackColor].CGColor;
        iconButton.layer.shadowOffset = CGSizeMake(0, 1);
        iconButton.layer.shadowOpacity = 0.05;
        iconButton.layer.shadowRadius = 2;
        iconButton.layer.masksToBounds = NO;
        
        // 图标标签
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, iconSize, iconSize)];
        iconLabel.text = data[@"icon"];
        iconLabel.font = [UIFont systemFontOfSize:18];
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.userInteractionEnabled = NO;
        [iconButton addSubview:iconLabel];
        
        // 添加点击事件
        [iconButton addTarget:self action:@selector(iconButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Apple风格点击动画
        [iconButton addTarget:self action:@selector(iconButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [iconButton addTarget:self action:@selector(iconButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        
        [container addSubview:iconButton];
        [self.tagButtons addObject:iconButton];
    }
}

- (void)iconButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    
    // Apple风格选择动画
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        sender.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 更新右侧胶囊按钮文字
    [self updateCapsuleForIndex:index];
    
    // 触觉反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [feedbackGenerator impactOccurred];
    }
    
    // 通知代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingTagView:didSelectTagAtIndex:)]) {
        [self.delegate floatingTagView:self didSelectTagAtIndex:index];
    }
}

- (void)iconButtonTouchDown:(UIButton *)sender {
    // Apple风格按下动画
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
        sender.alpha = 0.8;
    }];
}

- (void)iconButtonTouchUp:(UIButton *)sender {
    // Apple风格释放动画
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        sender.transform = CGAffineTransformIdentity;
        sender.alpha = 1.0;
    } completion:nil];
}

- (void)updateCapsuleForIndex:(NSInteger)index {
    // 根据选择的图标更新右侧胶囊按钮
    NSArray *capsuleTexts = @[@"👤 联系人", @"🛒 购物车", @"💬 消息", @"📢 通知"];
    
    UILabel *capsuleLabel = self.selectionIndicator.subviews.firstObject;
     if ([capsuleLabel isKindOfClass:[UILabel class]] && index < capsuleTexts.count) {
         [UIView transitionWithView:capsuleLabel duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
             capsuleLabel.text = capsuleTexts[index];
         } completion:nil];
     }
}

- (void)tagButtonTouchDown:(UIButton *)sender {
    // 按下时的动画效果
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
        sender.alpha = 0.8;
    }];
}

- (void)tagButtonTouchUp:(UIButton *)sender {
    // 松开时的动画效果
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        sender.transform = CGAffineTransformIdentity;
        sender.alpha = 1.0;
    } completion:nil];
    
    // 更新选中状态
    NSInteger selectedIndex = sender.tag;
    [self animateSelectionToIndex:selectedIndex];
}

- (void)animateSelectionToIndex:(NSInteger)index {
    if (index < 0 || index >= self.tagButtons.count) return;
    
    self.selectedIndex = index;
    UIButton *selectedButton = self.tagButtons[index];
    
    // 根据当前模式调整选择指示器
    CGRect newFrame;
    if (self.frame.size.height <= 30) {
        // 搜索栏内部模式 - 小尺寸
        newFrame = CGRectMake(selectedButton.frame.origin.x - 1, selectedButton.frame.origin.y - 1, selectedButton.frame.size.width + 2, selectedButton.frame.size.height + 2);
    } else {
        // 传统模式 - 大尺寸
        newFrame = CGRectMake(selectedButton.frame.origin.x - 2, selectedButton.frame.origin.y - 2, selectedButton.frame.size.width + 4, selectedButton.frame.size.height + 4);
    }
    
    // 现代化选择动画
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.selectionIndicator.frame = newFrame;
        self.selectionIndicator.alpha = 1.0;
        
        // 更新按钮状态
        for (NSInteger i = 0; i < self.tagButtons.count; i++) {
            UIButton *button = self.tagButtons[i];
            if (i == index) {
                button.selected = YES;
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                button.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // iOS蓝色
                button.layer.borderColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0].CGColor;
            } else {
                button.selected = NO;
                button.backgroundColor = [UIColor clearColor];
                button.layer.borderColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.87 alpha:0.6].CGColor;
                [button setTitleColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
            }
        }
    } completion:nil];
    
    // 自动滚动到选中项
    CGFloat offsetX = selectedButton.center.x - self.scrollView.frame.size.width / 2;
    offsetX = MAX(0, MIN(offsetX, self.scrollView.contentSize.width - self.scrollView.frame.size.width));
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.scrollView setContentOffset:CGPointMake(offsetX, 0) animated:NO];
    } completion:nil];
    
    // 通知过滤
    [self notifyMainFrameItemViewFiltering:index];
}

- (void)hide {
    if (!self.isVisible) {
        return;
    }
    
    self.isVisible = NO;
    
    // 停止自动滚动
    [self stopAutoScrollAnimation];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        // 隐藏完成
    }];
}

- (void)startAutoScrollAnimation {
    [self stopAutoScrollAnimation];
    
    // 每5秒自动切换到下一个标签
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(autoScrollToNext) userInfo:nil repeats:YES];
}

- (void)stopAutoScrollAnimation {
    if (self.autoScrollTimer) {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
}

- (void)autoScrollToNext {
    if (self.tagButtons.count <= 1) {
        return;
    }
    
    NSInteger nextIndex = (self.selectedIndex + 1) % self.tagButtons.count;
    [self animateSelectionToIndex:nextIndex];
}

- (UIView *)findSearchBarInView:(UIView *)view {
    if (!view) {
        return nil;
    }
    
    // 检查当前视图是否是搜索栏
    if ([view isKindOfClass:[UISearchBar class]]) {
        return view;
    }
    
    // 递归查找子视图
    for (UIView *subview in view.subviews) {
        UIView *searchBar = [self findSearchBarInView:subview];
        if (searchBar) {
            return searchBar;
        }
    }
    
    return nil;
}

- (void)notifyMainFrameItemViewFiltering:(NSInteger)selectedIndex {
    if (selectedIndex < 0 || selectedIndex >= self.tags.count) {
        // 无效的标签索引
        return;
    }
    
    // 更新胶囊按钮显示的文本
    [self updateCapsuleText:self.tags[selectedIndex]];
    
    // 发送通知给MainLayoutManager进行过滤
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FloatingTagSelectionChanged"
                                                        object:self
                                                      userInfo:@{
                                                          @"selectedTag": self.tags[selectedIndex],
                                                          @"selectedIndex": @(selectedIndex)
                                                      }];
    
    // 发送过滤通知
}

- (void)updateCapsuleText:(NSString *)tagName {
    UILabel *capsuleLabel = [self.selectionIndicator viewWithTag:1001];
    if (capsuleLabel && [capsuleLabel isKindOfClass:[UILabel class]]) {
        capsuleLabel.text = tagName;
    }
}

@end