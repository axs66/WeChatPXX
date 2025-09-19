//
//  MainLayoutManager.h
//  WeChat++
//
//  微信主界面布局管理器 - 重新设计搜索栏+悬浮标签+聊天列表布局
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>
#import "FloatingTagView.h"
#import "FloatingTagCell.h"

@interface MainLayoutManager : NSObject

@property (nonatomic, strong) UIView *mainContainerView;
@property (nonatomic, strong) UIView *searchSectionView;
@property (nonatomic, strong) UIView *originalSearchBar;
@property (nonatomic, strong) FloatingTagView *floatingTagView;
@property (nonatomic, strong) FloatingTagCell *floatingTagCell;
@property (nonatomic, strong) UIView *chatListContainer;
@property (nonatomic, strong) UIView *chatListView;
@property (nonatomic, assign) CGFloat searchSectionHeight;
@property (nonatomic, assign) CGFloat tagViewHeight;
@property (nonatomic, assign) BOOL isLayoutActive;

/**
 * 获取单例实例
 */
+ (instancetype)sharedManager;

/**
 * 初始化主界面布局重构
 * @param mainView 微信主视图容器
 */
- (void)initializeLayoutWithMainView:(UIView *)mainView;

/**
 * 创建独立的搜索区域
 * @param originalSearchBar 原始搜索栏
 */
- (void)createSearchSection:(UIView *)originalSearchBar;

/**
 * 调整聊天列表位置
 * @param chatListView 聊天列表视图
 */
- (void)adjustChatListPosition:(UIView *)chatListView;

/**
 * 重新布局所有组件
 */
- (void)relayoutAllComponents;

/**
 * 激活新布局
 */
- (void)activateNewLayout;

/**
 * 恢复原始布局
 */
- (void)restoreOriginalLayout;

/**
 * 动态调整布局参数
 * @param searchHeight 搜索区域高度
 * @param tagHeight 标签区域高度
 */
- (void)updateLayoutWithSearchHeight:(CGFloat)searchHeight tagHeight:(CGFloat)tagHeight;

/**
 * MainFrameItemView优化
 */
- (void)optimizeMainFrameItemViews:(UIView *)containerView;
- (void)findAndOptimizeMainFrameItemViewsInView:(UIView *)view;
- (void)optimizeSingleMainFrameItemView:(UIView *)itemView;

/**
 * MainFrameItemView过滤
 */
- (void)handleTagSelectionChanged:(NSNotification *)notification;
- (void)filterMainFrameItemViewsWithTag:(NSString *)tag index:(NSInteger)index;
- (void)showAllMainFrameItemViews;
- (void)filterMainFrameItemViewsForWork;
- (void)filterMainFrameItemViewsForFriends;
- (void)filterMainFrameItemViewsForFamily;
- (void)filterMainFrameItemViewsForGroups;
- (void)setMainFrameItemViewsVisibility:(BOOL)visible withAlpha:(CGFloat)alpha;
- (void)applyToAllMainFrameItemViews:(void(^)(UIView *itemView))block;
- (void)applyToMainFrameItemViewsInView:(UIView *)view withBlock:(void(^)(UIView *itemView))block;
- (void)animateFilterTransition;

/**
 * FloatingTagCell集成
 */
- (void)insertFloatingTagCellInChatList;
- (void)filterChatListByTag:(NSString *)tag withIndex:(NSInteger)index;

@end