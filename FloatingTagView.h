//
//  FloatingTagView.h
//  WeChat++
//
//  微信主界面悬浮标签视图头文件 - 搜索栏下方长条卡片样式
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>

@class FloatingTagView;

@protocol FloatingTagViewDelegate <NSObject>
@optional
- (void)floatingTagView:(FloatingTagView *)tagView didSelectTagAtIndex:(NSInteger)index;
@end

@interface FloatingTagView : UIView

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *tagButtons;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAShapeLayer *shadowLayer;
@property (nonatomic, strong) CABasicAnimation *gradientAnimation;
@property (nonatomic, strong) CASpringAnimation *bounceAnimation;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) NSTimer *autoScrollTimer;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSArray *capsuleStates;
@property (nonatomic, assign) NSInteger currentStateIndex;
@property (nonatomic, weak) id<FloatingTagViewDelegate> delegate;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, copy) void (^onTagSelected)(NSString *tag);

/**
 * 获取单例实例
 */
+ (instancetype)sharedInstance;

/**
 * 将标签嵌入到微信搜索栏内部
 * @param searchBar 搜索栏视图
 */
- (void)embedInSearchBar:(UIView *)searchBar;

/**
 * 在指定视图中显示悬浮标签（搜索栏下方）- 已弃用
 * @param parentView 父视图
 */
- (void)showInView:(UIView *)parentView DEPRECATED_MSG_ATTRIBUTE("Use embedInSearchBar: instead");

/**
 * 隐藏悬浮标签（带高级动画）
 */
- (void)hide;

/**
 * 更新标签内容
 * @param tags 标签数组
 */
- (void)updateTags:(NSArray *)tags;

/**
 * 创建标签按钮
 * @param tagName 标签名称
 * @param index 按钮索引
 */
- (void)createTagButton:(NSString *)tagName atIndex:(NSInteger)index;

/**
 * 重新创建适合搜索栏的标签按钮
 */
- (void)recreateTagsForSearchBar;

/**
 * Apple风格UI方法
 */
- (void)createAppleStyleIcons:(UIView *)container;
- (void)setupAppleStyleAnimations;
- (void)iconButtonTapped:(UIButton *)sender;
- (void)iconButtonTouchDown:(UIButton *)sender;
- (void)iconButtonTouchUp:(UIButton *)sender;
- (void)updateCapsuleForIndex:(NSInteger)index;

/**
 * 设置高级动画效果
 */
- (void)setupAdvancedAnimations;

/**
 * 动画切换到指定索引
 * @param index 目标索引
 */
- (void)animateSelectionToIndex:(NSInteger)index;

/**
 * 开始自动滚动动画
 */
- (void)startAutoScrollAnimation;

/**
 * 停止自动滚动动画
 */
- (void)stopAutoScrollAnimation;

@end