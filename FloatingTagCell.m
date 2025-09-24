#import "FloatingTagCell.h"
#import "MainLayoutManager.h"
#import <Foundation/Foundation.h>

@interface FloatingTagCell ()
@property (nonatomic, strong) id tapGesture;
@end

@implementation FloatingTagCell

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
        
        // 初始化默认状态（字典数组）
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
    self.containerView = [[NSObject alloc] init];
    self.scrollView = [[NSObject alloc] init];
    self.contentView = [[NSObject alloc] init];
    self.capsuleViews = [[NSMutableArray alloc] init];
    self.tapGesture = [[NSObject alloc] init];
}

- (void)setupConstraints {
    // 禁用自动布局转换
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self createCapsuleViews];
}

#pragma mark - 状态选择

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (selectedIndex >= 0 && selectedIndex < self.capsuleStates.count) {
        _selectedIndex = selectedIndex;
        [self refreshAppearance];
        
        if ([self.delegate respondsToSelector:@selector(floatingTagCell:didChangeToState:)]) {
            NSDictionary *stateDict = self.capsuleStates[selectedIndex];
            [self.delegate floatingTagCell:self didChangeToState:stateDict];
        }
        
        if (animated) {
            [self performShowAnimation];
        }
    }
}

- (void)handleTap:(id)gesture {
    NSInteger nextIndex = (self.selectedIndex + 1) % self.capsuleStates.count;
    [self setSelectedIndex:nextIndex animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(floatingTagCell:didSelectIndex:)]) {
        [self.delegate floatingTagCell:self didSelectIndex:nextIndex];
    }
    
    NSLog(@"[FloatingTagCell] 用户点击胶囊按钮，切换到索引: %ld", (long)nextIndex);
}

#pragma mark - 显示/隐藏

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

#pragma mark - 胶囊管理

- (void)refreshAppearance {
    [self createCapsuleViews];
    NSLog(@"[FloatingTagCell] 刷新外观，胶囊数量: %lu", (unsigned long)self.capsuleStates.count);
}

- (void)createCapsuleViews {
    [self.capsuleViews removeAllObjects];
    
    CGFloat capsuleWidth = 80.0;
    CGFloat capsuleHeight = 30.0;
    CGFloat spacing = 10.0;
    CGFloat totalWidth = 0;
    
    for (NSInteger i = 0; i < self.capsuleStates.count; i++) {
        NSDictionary *stateDict = self.capsuleStates[i];
        NSString *stateTitle = stateDict[@"title"];
        
        id capsuleView = [[NSObject alloc] init];
        id titleLabel = [[NSObject alloc] init];
        
        [self.capsuleViews addObject:capsuleView];
        totalWidth += capsuleWidth + spacing;
    }
    
    // 使用 totalWidth，消除未使用警告
    self.scrollView.contentSize = CGSizeMake(totalWidth - spacing, capsuleHeight);
}

- (void)performShowAnimation {
    NSLog(@"[FloatingTagCell] 执行显示动画");
}

#pragma mark - 实现 .h 声明方法

- (void)updateWithStates:(NSArray *)states {
    self.capsuleStates = states;
    [self updateCapsuleStyles];
}

- (void)addCapsuleWithTitle:(NSString *)title atIndex:(NSInteger)index {
    // TODO: 添加胶囊逻辑
}

- (void)removeCapsuleAtIndex:(NSInteger)index {
    // TODO: 移除胶囊逻辑
}

- (void)scrollToCapsuleAtIndex:(NSInteger)index animated:(BOOL)animated {
    // TODO: 滚动到指定胶囊逻辑
}

- (void)updateCapsuleStyles {
    // TODO: 更新胶囊样式逻辑
}

+ (instancetype)sharedInstance {
    static FloatingTagCell *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FloatingTagCell alloc] init];
    });
    return instance;
}

@end
