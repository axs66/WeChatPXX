//
//  FloatingTagCell.m
//  WeChat
//
//  Created by Assistant on 2024/12/16.
//  修改：修复类型不匹配、补全缺失方法，实现单例与UI基本逻辑
//

#import "FloatingTagCell.h"
#import "MainLayoutManager.h"
#import <UIKit/UIKit.h>

@interface FloatingTagCell ()
@property (nonatomic, strong) UIGestureRecognizer *tapGesture;
@end

@implementation FloatingTagCell

+ (instancetype)sharedInstance {
    static FloatingTagCell *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 使用 frame 为 CGRectZero 的初始化，实际布局在 layoutSubviews 中处理
        sharedInstance = [[self alloc] initWithFrame:CGRectZero];
    });
    return sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];

        // 初始化默认状态（使用字典数组以兼容 header 中声明的 NSDictionary 类型）
        self.capsuleStates = @[
            @{@"title": @"默认"},
            @{@"title": @"状态1"},
            @{@"title": @"状态2"}
        ];
        self.selectedIndex = 0;
        self.isVisible = NO;

        NSLog(@"[FloatingTagCell] 初始化完成");
    }
    return self;
}

- (void)setupUI {
    // 使用真实的 UIView/UIScrollView/UIView 以避免类型不匹配
    self.containerView = [[UIView alloc] init];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.containerView];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.alwaysBounceHorizontal = YES;
    [self.containerView addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    // 初始化胶囊视图数组
    self.capsuleViews = [[NSMutableArray alloc] init];

    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.tapGesture = tap;
    [self addGestureRecognizer:tap];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // 布局容器、滚动视图和内容视图（简单实现，按需可替换为 AutoLayout）
    self.containerView.frame = self.bounds;

    CGFloat margin = 10.0;
    CGFloat width = self.bounds.size.width - 2 * margin;
    CGFloat height = self.bounds.size.height - 2 * margin;
    if (height < 1) height = 44.0; // 默认高度保护

    self.scrollView.frame = CGRectMake(margin, margin, width, height);
    // contentView 的宽度将在 createCapsuleViews 中设置
    // self.contentView.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.frame.size.height);

    // 刷新胶囊视图布局
    [self createCapsuleViews];
}

- (void)setupConstraints {
    // 如果使用 AutoLayout，可在这里添加约束。目前我们使用 frame 布局，故留空
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (selectedIndex >= 0 && selectedIndex < self.capsuleStates.count) {
        _selectedIndex = selectedIndex;
        [self refreshAppearance];

        // 通知代理状态改变，保持与原逻辑兼容：delegate 收到 NSDictionary 包含 title 与 index
        if ([self.delegate respondsToSelector:@selector(floatingTagCell:didChangeToState:)]) {
            NSDictionary *stateDict = self.capsuleStates[selectedIndex];
            if (![stateDict isKindOfClass:[NSDictionary class]]) {
                stateDict = @{@"title": (stateDict ?: @""), @"index": @(selectedIndex)};
            } else {
                // 确保包含 index 字段
                NSMutableDictionary *mutable = [stateDict mutableCopy];
                mutable[@"index"] = @(selectedIndex);
                stateDict = [mutable copy];
            }
            [self.delegate floatingTagCell:self didChangeToState:stateDict];
        }

        if (animated) {
            [self performShowAnimation];
        }
    }
}

- (void)handleTap:(id)gesture {
    // 切换到下一个状态
    NSInteger nextIndex = (self.selectedIndex + 1) % MAX(1, self.capsuleStates.count);
    [self setSelectedIndex:nextIndex animated:YES];

    // 通知代理
    if ([self.delegate respondsToSelector:@selector(floatingTagCell:didSelectIndex:)]) {
        [self.delegate floatingTagCell:self didSelectIndex:nextIndex];
    }

    // 记录用户交互
    NSLog(@"[FloatingTagCell] 用户点击胶囊按钮，切换到索引: %ld", (long)nextIndex);
}

- (void)show {
    self.isVisible = YES;
    self.hidden = NO;
    NSLog(@"[FloatingTagCell] 胶囊按钮显示完成");
}

- (void)hide {
    self.isVisible = NO;
    self.hidden = YES;
    NSLog(@"[FloatingTagCell] 胶囊按钮隐藏完成");
}

- (void)refreshAppearance {
    [self createCapsuleViews];
    NSLog(@"[FloatingTagCell] 刷新外观，胶囊数量: %lu", (unsigned long)self.capsuleStates.count);
}

- (void)createCapsuleViews {
    // 清除现有胶囊视图
    for (UIView *caps in self.capsuleViews) {
        [caps removeFromSuperview];
    }
    [self.capsuleViews removeAllObjects];

    CGFloat capsuleWidth = 80.0;
    CGFloat capsuleHeight = CGRectGetHeight(self.scrollView.bounds) > 0 ? CGRectGetHeight(self.scrollView.bounds) : 30.0;
    CGFloat spacing = 10.0;
    CGFloat totalWidth = 0;

    // 创建每个胶囊按钮（使用 UIView + UILabel 的简单实现）
    for (NSInteger i = 0; i < self.capsuleStates.count; i++) {
        id stateObj = self.capsuleStates[i];
        NSString *stateTitle = nil;
        if ([stateObj isKindOfClass:[NSDictionary class]]) {
            stateTitle = stateObj[@"title"];
        } else if ([stateObj isKindOfClass:[NSString class]]) {
            stateTitle = stateObj;
        } else {
            stateTitle = [NSString stringWithFormat:@"胶囊%ld", (long)i];
        }

        CGFloat x = totalWidth;
        CGRect capsuleFrame = CGRectMake(x, 0, capsuleWidth, capsuleHeight);
        UIView *capsuleView = [[UIView alloc] initWithFrame:capsuleFrame];
        capsuleView.layer.cornerRadius = capsuleHeight / 2.0;
        capsuleView.clipsToBounds = YES;
        capsuleView.tag = i;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:capsuleView.bounds];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        titleLabel.text = stateTitle ?: @"";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:12.0];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [capsuleView addSubview:titleLabel];

        // 高亮选中状态
        if (i == self.selectedIndex) {
            capsuleView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8];
        } else {
            capsuleView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
        }

        [self.contentView addSubview:capsuleView];
        [self.capsuleViews addObject:capsuleView];

        totalWidth += capsuleWidth + spacing;
    }

    // 更新内容视图与滚动视图的 contentSize
    CGFloat contentW = MAX(totalWidth - spacing, CGRectGetWidth(self.scrollView.bounds));
    self.contentView.frame = CGRectMake(0, 0, contentW, capsuleHeight);
    self.scrollView.contentSize = CGSizeMake(contentW, capsuleHeight);

    [self updateCapsuleStyles];
}

- (void)performShowAnimation {
    NSLog(@"[FloatingTagCell] 执行显示动画");
}

#pragma mark - 新增/补全的方法（与 header 声明对应）

- (void)updateWithStates:(NSArray *)states {
    // 归一化：允许传入 NSString 数组或 NSDictionary 数组，内部统一存 NSDictionary（包含 title）
    NSMutableArray *normalized = [NSMutableArray array];
    for (id item in states) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            [normalized addObject:item];
        } else if ([item isKindOfClass:[NSString class]]) {
            [normalized addObject:@{@"title": item}];
        } else {
            // 忽略不支持类型
        }
    }
    self.capsuleStates = [normalized copy];
    // 重建 UI
    [self refreshAppearance];
}

- (void)addCapsuleWithTitle:(NSString *)title atIndex:(NSInteger)index {
    NSMutableArray *mutable = [self.capsuleStates mutableCopy];
    if (!mutable) mutable = [NSMutableArray array];
    NSDictionary *dict = @{@"title": title ?: @""};
    if (index < 0) index = 0;
    if (index > mutable.count) index = mutable.count;
    [mutable insertObject:dict atIndex:index];
    self.capsuleStates = [mutable copy];
    [self refreshAppearance];
}

- (void)removeCapsuleAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.capsuleStates.count) return;
    NSMutableArray *mutable = [self.capsuleStates mutableCopy];
    [mutable removeObjectAtIndex:index];
    self.capsuleStates = [mutable copy];

    // 调整 selectedIndex 避免越界
    if (self.selectedIndex >= self.capsuleStates.count) {
        _selectedIndex = MAX(0, (int)self.capsuleStates.count - 1);
    }
    [self refreshAppearance];
}

- (void)scrollToCapsuleAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= self.capsuleViews.count) return;
    UIView *capsule = self.capsuleViews[index];
    // 试图把 capsule 调整为 scrollView 可见区域的左侧（带一点 padding）
    CGFloat padding = 10.0;
    CGFloat targetX = MAX(0, CGRectGetMinX(capsule.frame) - padding);
    CGPoint offset = CGPointMake(targetX, 0);
    [self.scrollView setContentOffset:offset animated:animated];
}

- (void)updateCapsuleStyles {
    // 简单样式更新：高亮选中项，其他项为默认样式
    for (NSInteger i = 0; i < self.capsuleViews.count; i++) {
        UIView *capsule = self.capsuleViews[i];
        if (i == self.selectedIndex) {
            capsule.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.9];
            // 标题放大一点（如果存在）
            for (UIView *sub in capsule.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    UILabel *lbl = (UILabel *)sub;
                    lbl.font = [UIFont boldSystemFontOfSize:13.0];
                }
            }
        } else {
            capsule.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
            for (UIView *sub in capsule.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    UILabel *lbl = (UILabel *)sub;
                    lbl.font = [UIFont systemFontOfSize:12.0];
                }
            }
        }
    }
}

@end
