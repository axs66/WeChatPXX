//
//  FloatingTagCell.h
//  WeChat++
//
//  微信主界面胶囊按钮Cell - 作为NewMainFrameCell嵌入聊天列表
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>

@class FloatingTagCell;

@protocol FloatingTagCellDelegate <NSObject>
@optional
/**
 * 胶囊按钮被点击时调用
 * @param tagCell 胶囊按钮实例
 * @param index 选中的索引
 */
- (void)floatingTagCell:(FloatingTagCell *)tagCell didSelectIndex:(NSInteger)index;

/**
 * 胶囊按钮状态改变时调用
 * @param tagCell 胶囊按钮实例
 * @param state 新的状态字典
 */
- (void)floatingTagCell:(FloatingTagCell *)tagCell didChangeToState:(NSDictionary *)state;

@end

@interface FloatingTagCell : UIView

// Cell基本属性
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) NSMutableArray<UIView *> *capsuleViews;
@property (nonatomic, strong) UIView *separatorLine;

// 胶囊按钮相关
// @property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *capsuleContainer;
@property (nonatomic, strong) NSMutableArray *capsuleButtons;
@property (nonatomic, strong) UILabel *capsuleLabel;
@property (nonatomic, strong) UIImageView *capsuleIcon;
@property (nonatomic, strong) CAGradientLayer *capsuleGradient;

// 状态管理
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSArray<NSDictionary *> *capsuleStates;
@property (nonatomic, assign) NSInteger currentStateIndex;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, weak) id<FloatingTagCellDelegate> delegate;

// 交互属性
@property (nonatomic, assign) BOOL isHighlighted;
@property (nonatomic, assign) BOOL enableScrolling;
@property (nonatomic, assign) CGFloat capsuleSpacing;
@property (nonatomic, assign) CGFloat capsuleHeight;
// userInteractionEnabled已由UIView提供，无需重复声明

/**
 * 获取单例实例
 */
+ (instancetype)sharedInstance;

/**
 * 初始化Cell
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 * 设置Cell数据
 * @param states 胶囊状态数组
 */
- (void)updateWithStates:(NSArray *)states;

/**
 * 设置选中状态
 * @param index 选中索引
 * @param animated 是否动画
 */
- (void)setSelectedIndex:(NSInteger)index animated:(BOOL)animated;

/**
 * 显示Cell
 */
- (void)show;

/**
 * 隐藏Cell
 */
- (void)hide;

/**
 * 刷新Cell外观
 */
- (void)refreshAppearance;

/**
 * 添加胶囊按钮
 * @param title 按钮标题
 * @param index 插入位置
 */
- (void)addCapsuleWithTitle:(NSString *)title atIndex:(NSInteger)index;

/**
 * 移除胶囊按钮
 * @param index 移除位置
 */
- (void)removeCapsuleAtIndex:(NSInteger)index;

/**
 * 滚动到指定胶囊
 * @param index 目标索引
 * @param animated 是否动画
 */
- (void)scrollToCapsuleAtIndex:(NSInteger)index animated:(BOOL)animated;

/**
 * 更新胶囊按钮样式
 */
- (void)updateCapsuleStyles;

@end
