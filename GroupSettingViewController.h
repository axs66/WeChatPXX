//
//  GroupSettingViewController.h
//  WeChat++
//
//  分组设置界面头文件 - Google+微软 高级彩色交互动画
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface GroupSettingViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CAAnimationDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSMutableArray *availableGroups;
@property (nonatomic, strong) NSMutableDictionary *groupsByCategory;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, assign) BOOL isSettingsSectionExpanded;

// 高级动画和视觉效果属性
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) CAShapeLayer *headerShapeLayer;
@property (nonatomic, strong) NSMutableArray *cellAnimationLayers;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat animationProgress;

/**
 * 设置微信主题色彩
 */
- (void)setupWechatColors;

/**
 * 设置表格视图
 */
- (void)setupTableView;

/**
 * 加载分组数据
 */
- (void)loadGroups;

/**
 * 设置开关控件
 */
- (void)setupSettingsSwitches;

/**
 * 显示分组选择器
 */
- (void)showGroupSelector;

/**
 * 显示标签选择器
 */
- (void)showTagSelector;

/**
 * 保存分组设置
 */
- (void)saveGroups;

/**
 * 获取单元格背景色
 */
- (UIColor *)cellBackgroundColor;

/**
 * 设置高级背景渐变动画
 */
- (void)setupAdvancedBackgroundGradient;

/**
 * 设置动态头部视图
 */
- (void)setupDynamicHeaderView;

/**
 * 创建单元格动画层
 */
- (void)setupCellAnimationLayers;

/**
 * 启动连续动画效果
 */
- (void)startContinuousAnimations;

/**
 * 停止连续动画效果
 */
- (void)stopContinuousAnimations;

/**
 * 动画更新回调
 */
- (void)animationTick:(CADisplayLink *)displayLink;

/**
 * 创建彩色渐变色彩数组
 */
- (NSArray *)createColorfulGradientColors;

/**
 * 单元格点击动画效果
 */
- (void)animateCellSelection:(UITableViewCell *)cell;

@end