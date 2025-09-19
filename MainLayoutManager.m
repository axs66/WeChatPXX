//
//  MainLayoutManager.m
//  WeChat++
//
//  微信主界面布局管理器实现
//  有问题 联系pxx917144686
//

#import "MainLayoutManager.h"
#import <QuartzCore/QuartzCore.h>

@interface MainLayoutManager ()
@property (nonatomic, strong) NSMutableDictionary *originalFrames;
@property (nonatomic, assign) CGFloat statusBarHeight;
@property (nonatomic, assign) CGFloat navigationBarHeight;
@end

@implementation MainLayoutManager

+ (instancetype)sharedManager {
    static MainLayoutManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MainLayoutManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _originalFrames = [[NSMutableDictionary alloc] init];
        _searchSectionHeight = 100.0f; // 搜索区域高度
        _tagViewHeight = 44.0f; // 标签视图高度
        _isLayoutActive = NO;
        
        // 获取状态栏和导航栏高度
        _statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        _navigationBarHeight = 44.0f;
        
        // 监听FloatingTagView的标签选择变更
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleTagSelectionChanged:) 
                                                     name:@"FloatingTagViewSelectionChanged" 
                                                   object:nil];
        
        // 监听TagMainFrameItemView的标签选择变更
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleTagMainFrameSelectionChanged:) 
                                                     name:@"TagSelectionChanged" 
                                                   object:nil];
    }
    return self;
}

- (void)initializeLayoutWithMainView:(UIView *)mainView {
    if (!mainView) return;
    
    self.mainContainerView = mainView;
    
    // 保存原始frame
    [self.originalFrames setObject:[NSValue valueWithCGRect:mainView.frame] forKey:@"mainContainer"];
    
    // 创建搜索区域容器
    if (!self.searchSectionView) {
        self.searchSectionView = [[UIView alloc] init];
        self.searchSectionView.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
        self.searchSectionView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.searchSectionView.layer.shadowOffset = CGSizeMake(0, 2);
        self.searchSectionView.layer.shadowOpacity = 0.1;
        self.searchSectionView.layer.shadowRadius = 4;
        [mainView.superview addSubview:self.searchSectionView];
    }
    
    // 创建聊天列表容器
    if (!self.chatListContainer) {
        self.chatListContainer = [[UIView alloc] init];
        self.chatListContainer.backgroundColor = [UIColor whiteColor];
        [mainView.superview addSubview:self.chatListContainer];
    }
}

- (void)createSearchSection:(UIView *)originalSearchBar {
    if (!originalSearchBar || !self.searchSectionView) return;
    
    self.originalSearchBar = originalSearchBar;
    
    // 保存原始搜索栏frame
    [self.originalFrames setObject:[NSValue valueWithCGRect:originalSearchBar.frame] forKey:@"searchBar"];
    
    // 将搜索栏移动到新的搜索区域
    [originalSearchBar removeFromSuperview];
    [self.searchSectionView addSubview:originalSearchBar];
    
    // 创建悬浮标签视图
    if (!self.floatingTagView) {
        self.floatingTagView = [[FloatingTagView alloc] init];
        [self.searchSectionView addSubview:self.floatingTagView];
    }
    
    // 布局搜索区域内的组件
    [self layoutSearchSectionComponents];
}

- (void)layoutSearchSectionComponents {
    if (!self.searchSectionView || !self.originalSearchBar) return;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat topOffset = self.statusBarHeight + self.navigationBarHeight;
    
    // 设置搜索区域frame
    self.searchSectionView.frame = CGRectMake(0, topOffset, screenBounds.size.width, self.searchSectionHeight);
    
    // 布局原始搜索栏
    self.originalSearchBar.frame = CGRectMake(12, 8, screenBounds.size.width - 24, 36);
    
    // 布局悬浮标签视图
    if (self.floatingTagView) {
        CGFloat tagY = CGRectGetMaxY(self.originalSearchBar.frame) + 8;
        self.floatingTagView.frame = CGRectMake(12, tagY, screenBounds.size.width - 24, self.tagViewHeight);
        
        // 设置标签样式
        [self.floatingTagView updateTags:@[@"全部", @"工作", @"朋友", @"家人", @"群聊"]];
        self.floatingTagView.selectedIndex = 0;
    }
}

- (void)adjustChatListPosition:(UIView *)chatListView {
    if (!chatListView || !self.chatListContainer) return;
    
    // 保存原始聊天列表frame
    [self.originalFrames setObject:[NSValue valueWithCGRect:chatListView.frame] forKey:@"chatList"];
    
    // 将聊天列表移动到新容器
    [chatListView removeFromSuperview];
    [self.chatListContainer addSubview:chatListView];
    
    // 重新布局聊天列表
    [self layoutChatListContainer:chatListView];
    
    // 优化MainFrameItemView的显示
    [self optimizeMainFrameItemViews:chatListView];
}

- (void)layoutChatListContainer:(UIView *)chatListView {
    if (!chatListView || !self.chatListContainer) return;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat topOffset = self.statusBarHeight + self.navigationBarHeight + self.searchSectionHeight;
    CGFloat containerHeight = screenBounds.size.height - topOffset;
    
    // 设置聊天列表容器frame
    self.chatListContainer.frame = CGRectMake(0, topOffset, screenBounds.size.width, containerHeight);
    
    // 调整聊天列表frame以适应新容器
    chatListView.frame = CGRectMake(0, 0, screenBounds.size.width, containerHeight);
}

- (void)relayoutAllComponents {
    if (!self.isLayoutActive) return;
    
    [self layoutSearchSectionComponents];
    
    // 重新布局聊天列表
    if (self.chatListContainer.subviews.count > 0) {
        UIView *chatListView = self.chatListContainer.subviews.firstObject;
        [self layoutChatListContainer:chatListView];
    }
}

- (void)activateNewLayout {
    if (self.isLayoutActive) return;
    
    self.isLayoutActive = YES;
    
    // 执行布局动画
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self relayoutAllComponents];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)restoreOriginalLayout {
    if (!self.isLayoutActive) return;
    
    self.isLayoutActive = NO;
    
    // 恢复原始布局
    [UIView animateWithDuration:0.3 animations:^{
        // 恢复搜索栏
        if (self.originalSearchBar) {
            NSValue *originalFrame = [self.originalFrames objectForKey:@"searchBar"];
            if (originalFrame) {
                [self.originalSearchBar removeFromSuperview];
                [self.mainContainerView addSubview:self.originalSearchBar];
                self.originalSearchBar.frame = [originalFrame CGRectValue];
            }
        }
        
        // 恢复聊天列表
        if (self.chatListContainer.subviews.count > 0) {
            UIView *chatListView = self.chatListContainer.subviews.firstObject;
            NSValue *originalFrame = [self.originalFrames objectForKey:@"chatList"];
            if (originalFrame) {
                [chatListView removeFromSuperview];
                [self.mainContainerView addSubview:chatListView];
                chatListView.frame = [originalFrame CGRectValue];
            }
        }
        
        // 隐藏自定义容器
        self.searchSectionView.alpha = 0;
        self.chatListContainer.alpha = 0;
    } completion:^(BOOL finished) {
        [self.searchSectionView removeFromSuperview];
        [self.chatListContainer removeFromSuperview];
        
    }];
}

- (void)updateLayoutWithSearchHeight:(CGFloat)searchHeight tagHeight:(CGFloat)tagHeight {
    self.searchSectionHeight = searchHeight;
    self.tagViewHeight = tagHeight;
    
    if (self.isLayoutActive) {
        [self relayoutAllComponents];
    }
}

- (void)optimizeMainFrameItemViews:(UIView *)containerView {
    // 递归查找并优化所有MainFrameItemView
    [self findAndOptimizeMainFrameItemViewsInView:containerView];
}

- (void)findAndOptimizeMainFrameItemViewsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        
        if ([className isEqualToString:@"MainFrameItemView"]) {
            [self optimizeSingleMainFrameItemView:subview];
        }
        
        // 递归查找子视图
        [self findAndOptimizeMainFrameItemViewsInView:subview];
    }
}

- (void)optimizeSingleMainFrameItemView:(UIView *)itemView {
    @try {
        // 添加现代化的视觉效果
        itemView.layer.cornerRadius = 8;
        itemView.backgroundColor = [UIColor systemBackgroundColor];
        
        // 添加轻微的边框
        itemView.layer.borderWidth = 0.5;
        itemView.layer.borderColor = [UIColor separatorColor].CGColor;
        
        // 添加阴影效果
        itemView.layer.shadowColor = [UIColor blackColor].CGColor;
        itemView.layer.shadowOffset = CGSizeMake(0, 1);
        itemView.layer.shadowOpacity = 0.05;
        itemView.layer.shadowRadius = 3;
        
        // 设置间距
        CGRect frame = itemView.frame;
        frame.origin.x += 8;
        frame.size.width -= 16;
        frame.origin.y += 2;
        frame.size.height -= 4;
        itemView.frame = frame;
        
    } @catch (NSException *exception) {
        // 异常处理
    }
}

- (void)filterMainFrameItemViewsWithTag:(NSString *)tag index:(NSInteger)index {
    if (!tag || [tag isEqualToString:@"全部"]) {
        [self showAllMainFrameItemViews];
        return;
    }
    
    // 根据标签类型进行过滤
    if ([tag isEqualToString:@"工作"]) {
        [self filterMainFrameItemViewsForWork];
    } else if ([tag isEqualToString:@"朋友"]) {
        [self filterMainFrameItemViewsForFriends];
    } else if ([tag isEqualToString:@"家人"]) {
        [self filterMainFrameItemViewsForFamily];
    } else if ([tag isEqualToString:@"群聊"]) {
        [self filterMainFrameItemViewsForGroups];
    } else {
        [self showAllMainFrameItemViews];
    }
}

- (void)showAllMainFrameItemViews {
    // 显示所有聊天项
    [self setMainFrameItemViewsVisibility:YES withAlpha:1.0];
}

- (void)filterMainFrameItemViewsForWork {
    // 过滤显示工作相关聊天
    
    [self applyToAllMainFrameItemViews:^(UIView *itemView) {
        // 简单的工作过滤逻辑 - 可以根据实际需求优化
        BOOL isWorkRelated = [self isWorkRelatedItemView:itemView];
        itemView.hidden = !isWorkRelated;
        itemView.alpha = isWorkRelated ? 1.0 : 0.3;
    }];
    
    [self animateFilterTransition];
}

- (void)filterMainFrameItemViewsForFriends {
    // 过滤显示朋友聊天
    
    [self applyToAllMainFrameItemViews:^(UIView *itemView) {
        BOOL isFriendRelated = [self isFriendRelatedItemView:itemView];
        itemView.hidden = !isFriendRelated;
        itemView.alpha = isFriendRelated ? 1.0 : 0.3;
    }];
    
    [self animateFilterTransition];
}

- (void)filterMainFrameItemViewsForFamily {
    // 过滤显示家人聊天
    
    [self applyToAllMainFrameItemViews:^(UIView *itemView) {
        BOOL isFamilyRelated = [self isFamilyRelatedItemView:itemView];
        itemView.hidden = !isFamilyRelated;
        itemView.alpha = isFamilyRelated ? 1.0 : 0.3;
    }];
    
    [self animateFilterTransition];
}

- (void)filterMainFrameItemViewsForGroups {
    // 过滤显示群聊
    
    [self applyToAllMainFrameItemViews:^(UIView *itemView) {
        BOOL isGroupRelated = [self isGroupRelatedItemView:itemView];
        itemView.hidden = !isGroupRelated;
        itemView.alpha = isGroupRelated ? 1.0 : 0.3;
    }];
    
    [self animateFilterTransition];
}

- (void)setMainFrameItemViewsVisibility:(BOOL)visible withAlpha:(CGFloat)alpha {
    [self applyToAllMainFrameItemViews:^(UIView *itemView) {
        itemView.hidden = !visible;
        itemView.alpha = alpha;
    }];
    
    [self animateFilterTransition];
}

- (void)applyToAllMainFrameItemViews:(void(^)(UIView *itemView))block {
    if (!block || !self.mainContainerView) return;
    
    [self applyToMainFrameItemViewsInView:self.mainContainerView withBlock:block];
}

- (void)applyToMainFrameItemViewsInView:(UIView *)view withBlock:(void(^)(UIView *itemView))block {
    if (!view || !block) return;
    
    for (UIView *subview in view.subviews) {
        // 检查是否是MainFrameItemView
        if ([NSStringFromClass([subview class]) containsString:@"MainFrameItemView"]) {
            block(subview);
        }
        
        // 递归检查子视图
        [self applyToMainFrameItemViewsInView:subview withBlock:block];
    }
}

- (void)collectMainFrameItemViewsInView:(UIView *)view toArray:(NSMutableArray *)array {
    if (!view || !array) return;
    
    for (UIView *subview in view.subviews) {
        // 检查是否是MainFrameItemView
        if ([NSStringFromClass([subview class]) containsString:@"MainFrameItemView"]) {
            [array addObject:subview];
        }
        
        // 递归检查子视图
        [self collectMainFrameItemViewsInView:subview toArray:array];
    }
}

- (void)animateFilterTransition {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.mainContainerView layoutIfNeeded];
    } completion:nil];
}

#pragma mark - 聊天类型判断辅助方法

- (BOOL)isWorkRelatedItemView:(UIView *)itemView {
    // 简单的工作相关判断逻辑
    // 可以根据实际需求检查联系人名称、群名等
    return arc4random() % 3 == 0; // 临时随机逻辑
}

- (BOOL)isFriendRelatedItemView:(UIView *)itemView {
    // 朋友相关判断逻辑
    return arc4random() % 3 == 1; // 临时随机逻辑
}

- (BOOL)isFamilyRelatedItemView:(UIView *)itemView {
    // 家人相关判断逻辑
    return arc4random() % 3 == 2; // 临时随机逻辑
}

- (BOOL)isGroupRelatedItemView:(UIView *)itemView {
    // 群聊相关判断逻辑
    // 可以检查是否包含多个头像等特征
    return arc4random() % 2 == 0; // 临时随机逻辑
}

#pragma mark - FloatingTagView Integration

- (void)handleTagSelectionChanged:(NSNotification *)notification {
    @try {
        NSDictionary *userInfo = notification.userInfo;
        NSString *selectedTag = userInfo[@"selectedTag"];
        NSNumber *selectedIndex = userInfo[@"selectedIndex"];
        
        // 根据选中的标签过滤聊天列表
        [self filterChatListByTag:selectedTag withIndex:[selectedIndex integerValue]];
        
    } @catch (NSException *exception) {
        // 处理FloatingTagView标签选择变化异常
    }
}

- (void)filterChatListByTag:(NSString *)tag withIndex:(NSInteger)index {
    @try {
        if (!self.chatListView) {
            // 聊天列表视图未找到，无法进行标签过滤
            return;
        }
        
        // 获取聊天列表中的所有MainFrameItemView
        NSMutableArray *chatItems = [[NSMutableArray alloc] init];
        [self collectMainFrameItemViewsInView:self.chatListView toArray:chatItems];
        
        for (UIView *itemView in chatItems) {
            BOOL shouldShow = YES;
            
            // 根据标签类型决定是否显示该聊天项
            if (index == 0) {
                // "全部" - 显示所有项
                shouldShow = YES;
            } else if ([tag isEqualToString:@"工作"]) {
                shouldShow = [self isWorkRelatedItemView:itemView];
            } else if ([tag isEqualToString:@"朋友"]) {
                shouldShow = [self isFriendRelatedItemView:itemView];
            } else if ([tag isEqualToString:@"家人"]) {
                shouldShow = [self isFamilyRelatedItemView:itemView];
            } else if ([tag isEqualToString:@"群聊"]) {
                shouldShow = [self isGroupRelatedItemView:itemView];
            }
            
            // 应用过滤效果
            [UIView animateWithDuration:0.3 animations:^{
                itemView.alpha = shouldShow ? 1.0 : 0.3;
                itemView.transform = shouldShow ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.95, 0.95);
            }];
        }
        
        // 已根据标签过滤聊天列表
        
    } @catch (NSException *exception) {
        // 标签过滤异常
    }
}

- (UITableView *)findChatListTableView {
    @try {
        // 递归查找MainFrameTableView
        UIView *currentView = self.mainContainerView;
        if (!currentView) {
            // 尝试从应用主窗口开始查找
            currentView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        }
        
        return [self findTableViewInView:currentView withClassName:@"MainFrameTableView"];
        
    } @catch (NSException *exception) {
        NSLog(@"[MainLayoutManager] 查找聊天列表表格视图异常: %@", exception.reason);
        return nil;
    }
}

- (UITableView *)findTableViewInView:(UIView *)view withClassName:(NSString *)className {
    if (!view || !className) return nil;
    
    // 检查当前视图是否匹配
    if ([NSStringFromClass([view class]) isEqualToString:className] && [view isKindOfClass:[UITableView class]]) {
        return (UITableView *)view;
    }
    
    // 递归查找子视图
    for (UIView *subview in view.subviews) {
        UITableView *result = [self findTableViewInView:subview withClassName:className];
        if (result) {
            return result;
        }
    }
    
    return nil;
}

- (void)insertFloatingTagCellInChatList {
    @try {
        if (!self.mainContainerView || !self.floatingTagCell) {
            return;
        }
        
        // 获取聊天列表表格视图
        UITableView *chatListTableView = [self findChatListTableView];
        if (!chatListTableView) {
            return;
        }
        
        // 将胶囊按钮添加到表格视图的父视图中
        [chatListTableView.superview addSubview:self.floatingTagCell];
        
        // 设置胶囊按钮的位置约束
        [self.floatingTagCell setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.floatingTagCell.topAnchor constraintEqualToAnchor:chatListTableView.topAnchor],
            [self.floatingTagCell.leadingAnchor constraintEqualToAnchor:chatListTableView.leadingAnchor],
            [self.floatingTagCell.trailingAnchor constraintEqualToAnchor:chatListTableView.trailingAnchor],
            [self.floatingTagCell.heightAnchor constraintEqualToConstant:self.tagViewHeight]
        ]];
        
        // 调整表格视图的内容偏移，为胶囊按钮腾出空间
        UIEdgeInsets currentInsets = chatListTableView.contentInset;
        currentInsets.top += self.tagViewHeight;
        chatListTableView.contentInset = currentInsets;
        
        // 同时调整滚动指示器的偏移
        chatListTableView.scrollIndicatorInsets = currentInsets;
        
        NSLog(@"[MainLayoutManager] 胶囊按钮已插入聊天列表，高度: %.2f", self.tagViewHeight);
        
    } @catch (NSException *exception) {
         NSLog(@"[MainLayoutManager] 插入FloatingTagCell异常: %@", exception.reason);
     }
 }

- (void)adaptMessageCellsForFloatingTag {
    @try {
        if (!self.chatListView) return;
        
        // 递归查找并调整所有消息单元格
        [self adjustMessageCellsInView:self.chatListView withOffset:72.0f];
        
    } @catch (NSException *exception) {
        // 消息单元格适配异常
    }
}

- (void)adjustMessageCellsInView:(UIView *)view withOffset:(CGFloat)offset {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        
        // 检查是否为消息单元格相关的视图
         if ([className containsString:@"MessageCell"] || 
             [className isEqualToString:@"MainFrameItemView"]) {
            
            // 调整单元格位置，避免与FloatingTagCell重叠
            CGRect frame = subview.frame;
            if (frame.origin.y < offset) {
                frame.origin.y = MAX(frame.origin.y, offset + 8);
                subview.frame = frame;
            }
            
            // 添加平滑的布局动画
            [UIView animateWithDuration:0.2 animations:^{
                subview.alpha = 1.0;
                subview.transform = CGAffineTransformIdentity;
            }];
        }
        
        // 递归处理子视图
        [self adjustMessageCellsInView:subview withOffset:offset];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end