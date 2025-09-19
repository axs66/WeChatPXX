//
//  Tweak.xm
//  WeChat++
//
//  微信插件主文件 - Hook实现
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <substrate.h>
#import "WCPulseLoader.h"
#import "SpeedFloatView.h"
#import "Config.h"
#import "CustomGroupVC.h"
#import "FloatingTagView.h"
#import "FloatingTagCell.h"
#import "GroupSettingViewController.h"
#import "SessionInfo.h"
#import "MainLayoutManager.h"
#import "SessionMgr.h"


// MSHookMessageEx函数声明
extern "C" void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

// 全局变量
static IMP orig_MainFrameTableView_willDisplayCell = NULL;
static IMP orig_MainFrameTableView_initWithFrame = NULL;
static IMP orig_MainFrameTableView_setTableHeaderView = NULL;
static IMP orig_MMTableViewCell_layoutSubviews = NULL;
static IMP orig_CommonMessageCellView_layoutSubviews = NULL;
static IMP orig_WCPulseBadgeView_updateAllBadgeViews = NULL;

// 微信核心类声明
@interface MainFrameTableView : UITableView
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style;
- (void)setTableHeaderView:(UIView *)tableHeaderView;
@end

@interface MMTableViewCell : UITableViewCell
- (void)layoutSubviews;
@end

@interface CommonMessageCellView : UIView
- (void)layoutSubviews;
@end

// 微信主界面控制器
@interface NewMainFrameViewController : UIViewController
- (UIView *)findSearchBarInMainView:(UIView *)view;
- (UIView *)findChatListInMainView:(UIView *)view;
@end

// 微信主界面项目视图 - 核心聊天列表项
@interface MainFrameItemView : UIView
@property (nonatomic, strong) UIView *m_frameHeadView;
@property (nonatomic, strong) UIView *m_unreadCountView;
@property (nonatomic, strong) UILabel *m_nameLabel;
@property (nonatomic, strong) UILabel *m_greenLabel;
@property (nonatomic, strong) UILabel *m_timeLabel;
@property (nonatomic, strong) UILabel *m_messageLabel;
@property (nonatomic, strong) UIView *m_statusView;
@property (nonatomic, strong) UIView *m_liveStatusView;
@property (nonatomic, strong) UIView *separatorLine;
- (void)updateWithCellData:(id)cellData;
- (void)setM_frameHeadView:(UIView *)frameHeadView;
- (void)setM_nameLabel:(UILabel *)nameLabel;
- (void)setM_messageLabel:(UILabel *)messageLabel;
@end

@interface UIViewController (WeChatModern) <UIPopoverPresentationControllerDelegate>

// 核心UI方法
- (void)wechat_setupModernUI;
- (void)wechat_installViewSelector;
- (void)wechat_resetLayoutIfNeeded;
- (void)wechat_handleViewModeChange:(UISegmentedControl *)sender;

// 视图查找方法
- (UIView *)findSearchBarInMainView:(UIView *)view;
- (UIView *)findChatListInMainView:(UIView *)view;

// 视图模式切换
- (void)wechat_enableCategoryView;
- (void)wechat_enableListView;

// 用户交互
- (void)wechat_showGroupSelectionMenu;
- (void)wechat_showGroupManagementMenu;
- (void)wechat_showCreateGroupDialog;
- (void)wechat_showEditGroupDialog;
- (void)wechat_showRenameGroupDialog:(NSString *)oldName;
- (void)wechat_showDeleteGroupDialog;
- (void)wechat_confirmDeleteGroup:(NSString *)groupName;
- (void)wechat_showSettingsMenu;
- (void)wechat_showToast:(NSString *)message;
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller;
@end

// 微信主界面
%hook NewMainFrameViewController

- (void)viewDidLoad {
    %orig;
    
    // 全局布局保护机制
    static BOOL globalLayoutProtection = NO;
    if (globalLayoutProtection) {
        return;
    }
    globalLayoutProtection = YES;
    
    // 延迟设置UI，确保界面完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [(UIViewController *)self wechat_setupModernUI];
        [(UIViewController *)self wechat_installViewSelector];
        
        // 集成FloatingTagCell到聊天列表
        [[MainLayoutManager sharedManager] insertFloatingTagCellInChatList];
        
        // 设置定时检查机制，防止布局被破坏
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(wechat_periodicLayoutCheck) userInfo:nil repeats:YES];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    // 重置布局并确保悬浮标签正确显示
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 先执行布局重置检查
        [self wechat_resetLayoutIfNeeded];
        
        // 只在标签被隐藏时才重新显示，避免重复操作
        UIView *searchBar = [self findSearchBarInMainView:self.view];
        if (searchBar && searchBar.superview) {
            FloatingTagView *existingTagView = nil;
            for (UIView *subview in searchBar.superview.subviews) {
                if ([subview isKindOfClass:[FloatingTagView class]]) {
                    existingTagView = (FloatingTagView *)subview;
                    break;
                }
            }
            
            // 只有当标签存在且被隐藏时才重新显示
            if (existingTagView && (existingTagView.hidden || existingTagView.alpha < 0.1)) {
                [UIView animateWithDuration:0.2 animations:^{
                    existingTagView.hidden = NO;
                    existingTagView.alpha = 1.0;
                }];
            }
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    
    // 清理可能的重复标签
    UIView *searchBar = [self findSearchBarInMainView:self.view];
    if (searchBar && searchBar.superview) {
        NSMutableArray *tagsToRemove = [NSMutableArray array];
        for (UIView *subview in searchBar.superview.subviews) {
            if ([subview isKindOfClass:[FloatingTagView class]]) {
                [tagsToRemove addObject:subview];
            }
        }
        
        // 保留第一个，移除其他重复的
        for (NSInteger i = 1; i < tagsToRemove.count; i++) {
            [tagsToRemove[i] removeFromSuperview];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // viewDidAppear中不再重复创建按钮，避免重复
}

%new
- (UIView *)findSearchBarInMainView:(UIView *)view {
    // 递归查找微信搜索栏，基于类名和frame特征
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        
        // 查找微信特有的搜索栏类名
        if ([className containsString:@"Search"] || 
            [className containsString:@"TextField"] ||
            [className containsString:@"Bar"]) {
            
            // 进一步验证是否为搜索栏（通常在顶部且宽度较大）
             if (subview.frame.origin.y < 200 && subview.bounds.size.width > 200) {
                 return subview;
             }
        }
        
        // 递归查找子视图
        UIView *found = [self findSearchBarInMainView:subview];
        if (found) return found;
    }
    return nil;
}

%new
- (void)wechat_periodicLayoutCheck {
    // 定期检查布局状态，确保界面正常
    @try {
        NSString *className = NSStringFromClass([self class]);
        if (![className containsString:@"MainFrame"]) {
            return;
        }
        
        // 检查悬浮标签是否存在且可见
        UIView *searchBar = [self findSearchBarInMainView:self.view];
        if (searchBar && searchBar.superview) {
            FloatingTagView *tagView = nil;
            for (UIView *subview in searchBar.superview.subviews) {
                if ([subview isKindOfClass:[FloatingTagView class]]) {
                    tagView = (FloatingTagView *)subview;
                    break;
                }
            }
            
            // 如果标签不存在或不可见，触发布局重置
            if (!tagView || tagView.alpha < 0.1 || tagView.hidden) {
                [self wechat_resetLayoutIfNeeded];
            }
        }
        
        // 检查聊天列表是否正常显示
        UIView *chatListView = [self findChatListInMainView:self.view];
        if (chatListView) {
            CGRect frame = chatListView.frame;
            CGFloat screenHeight = self.view.bounds.size.height;
            
            // 如果聊天列表位置异常，触发修复
            if (frame.origin.y > screenHeight * 0.7 || 
                frame.size.height < screenHeight * 0.2 || 
                chatListView.alpha < 0.1) {
                [self wechat_resetLayoutIfNeeded];
            }
        }
    } @catch (NSException *exception) {
        // 静默处理异常
    }
}

%new
- (void)wechat_resetLayoutIfNeeded {
    // 增强的布局保护和修复方法
    UIView *searchBar = [self findSearchBarInMainView:self.view];
    if (searchBar && searchBar.superview) {
        // 检查并清理重复的悬浮标签
        NSMutableArray *floatingTags = [NSMutableArray array];
        for (UIView *subview in searchBar.superview.subviews) {
            if ([subview isKindOfClass:[FloatingTagView class]]) {
                [floatingTags addObject:subview];
            }
        }
        
        // 移除多余的标签，保留第一个
        if (floatingTags.count > 1) {
            for (NSInteger i = 1; i < floatingTags.count; i++) {
                [floatingTags[i] removeFromSuperview];
            }
        }
        
        // 检查并修复聊天列表布局异常
        UIView *chatListView = [self findChatListInMainView:self.view];
        if (chatListView) {
            CGRect currentFrame = chatListView.frame;
            CGFloat screenHeight = self.view.bounds.size.height;
            FloatingTagView *tagView = floatingTags.firstObject;
            
            // 检测异常情况：位置过低、高度过小、或完全不可见
            BOOL positionTooLow = currentFrame.origin.y > screenHeight * 0.6;
            BOOL heightTooSmall = currentFrame.size.height < screenHeight * 0.3;
            BOOL notVisible = chatListView.alpha < 0.1 || chatListView.hidden;
            BOOL frameInvalid = CGRectIsEmpty(currentFrame) || currentFrame.size.width < 100;
            
            if (positionTooLow || heightTooSmall || notVisible || frameInvalid) {
                // 计算修复后的合理位置
                CGFloat newY = tagView ? CGRectGetMaxY(tagView.frame) + 8 : 120;
                CGFloat availableHeight = screenHeight - newY - 100;
                CGFloat minHeight = screenHeight * 0.4;
                
                // 确保有足够的空间
                if (availableHeight >= minHeight) {
                    [UIView animateWithDuration:0.3 animations:^{
                        chatListView.frame = CGRectMake(
                            currentFrame.origin.x > 0 ? currentFrame.origin.x : 0,
                            newY,
                            currentFrame.size.width > 100 ? currentFrame.size.width : self.view.bounds.size.width,
                            availableHeight
                        );
                        chatListView.alpha = 1.0;
                        chatListView.hidden = NO;
                    }];
                }
            }
        }
    }
}

%new
- (UIView *)findChatListInMainView:(UIView *)view {
    // 递归查找微信聊天列表，使用更精确的查找策略
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        
        // 优先查找UITableView类型的聊天列表
        if ([className isEqualToString:@"UITableView"] || [className containsString:@"TableView"]) {
            // 验证是否为主要的聊天列表（高度占屏幕大部分且位置合理）
            CGRect frame = subview.frame;
            CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
            
            if (frame.size.height > screenHeight * 0.4 && 
                frame.origin.y < screenHeight * 0.5 &&
                frame.size.width > 200) {
                return subview;
            }
        }
        
        // 查找其他可能的聊天列表容器
        if ([className containsString:@"MainFrame"] && 
            ![className containsString:@"Controller"] &&
            subview.bounds.size.height > 300) {
            return subview;
        }
        
        // 递归查找子视图，但限制递归深度避免性能问题
        if (subview.subviews.count > 0 && subview.subviews.count < 20) {
            UIView *found = [self findChatListInMainView:subview];
            if (found) return found;
        }
    }
    return nil;
}

// Hook函数实现
static void hooked_MainFrameTableView_willDisplayCell(id self, SEL _cmd, UITableView *tableView, UITableViewCell *cell, NSIndexPath *indexPath) {
    // 添加参数安全检查
    if (!self || !indexPath) {
        // 参数无效，静默返回
        return;
    }
    
    
    // 调用原始方法
    if (orig_MainFrameTableView_willDisplayCell) {
        @try {
            ((void(*)(id, SEL, UITableView *, UITableViewCell *, NSIndexPath *))orig_MainFrameTableView_willDisplayCell)(self, _cmd, tableView, cell, indexPath);
        } @catch (NSException *exception) {
            // 原始方法异常，静默处理
        }
    }
    
    // 设置MainLayoutManager的chatListView属性
    @try {
        MainLayoutManager *layoutManager = [MainLayoutManager sharedManager];
        if (layoutManager && !layoutManager.chatListView && tableView) {
            layoutManager.chatListView = tableView;
            // 设置 chatListView
        }
        
        // 自定义逻辑：在第一行插入胶囊按钮cell
        if (indexPath.section == 0 && indexPath.row == 0) {
            // 确保FloatingTagCell正确显示
            FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
            if (tagCell && !tagCell.superview && layoutManager && [layoutManager respondsToSelector:@selector(insertFloatingTagCellInChatList)]) {
                // 插入 FloatingTagCell
                [layoutManager insertFloatingTagCellInChatList];
            }
        }
    } @catch (NSException *exception) {
        // 自定义逻辑异常，静默处理
    }
}

static id hooked_MainFrameTableView_initWithFrame(id self, SEL _cmd, CGRect frame, UITableViewStyle style) {
    // 调用原始方法
    id result = nil;
    if (orig_MainFrameTableView_initWithFrame) {
        @try {
            result = ((id(*)(id, SEL, CGRect, UITableViewStyle))orig_MainFrameTableView_initWithFrame)(self, _cmd, frame, style);
        } @catch (NSException *exception) {
            // 原始方法异常，静默处理
            return nil;
        }
    }
    
    // 自定义逻辑：初始化时设置表格属性
    if (result) {
        @try {
            UITableView *tableView = (UITableView *)result;
            // 设置表格样式以适应胶囊按钮
            if ([tableView isKindOfClass:[UITableView class]]) {
                tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                tableView.backgroundColor = [UIColor systemBackgroundColor];
            }
        } @catch (NSException *exception) {
            // 自定义逻辑异常，静默处理
        }
    }
    
    return result;
}

static void hooked_MainFrameTableView_setTableHeaderView(id self, SEL _cmd, UIView *tableHeaderView) {
    // 调用原始方法
    if (orig_MainFrameTableView_setTableHeaderView) {
        @try {
            ((void(*)(id, SEL, UIView *))orig_MainFrameTableView_setTableHeaderView)(self, _cmd, tableHeaderView);
        } @catch (NSException *exception) {
            // 原始方法异常，静默处理
        }
    }
    
    // 自定义逻辑：在设置表格头部时插入胶囊列表
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            MainLayoutManager *layoutManager = [MainLayoutManager sharedManager];
            if (layoutManager && [layoutManager respondsToSelector:@selector(insertFloatingTagCellInChatList)]) {
                [layoutManager insertFloatingTagCellInChatList];
            }
        } @catch (NSException *exception) {
            // 自定义逻辑异常，静默处理
        }
    });
}

static void hooked_MMTableViewCell_layoutSubviews(id self, SEL _cmd) {
    // 调用原始方法
    if (orig_MMTableViewCell_layoutSubviews) {
        @try {
            ((void(*)(id, SEL))orig_MMTableViewCell_layoutSubviews)(self, _cmd);
        } @catch (NSException *exception) {
            // 原始方法异常，静默处理
        }
    }
    
    // 自定义逻辑：调整单元格布局以适应胶囊按钮
    @try {
        UITableViewCell *cell = (UITableViewCell *)self;
        if (cell && [cell isKindOfClass:[UITableViewCell class]] && cell.superview) {
            // 检查是否需要为胶囊按钮让出空间
            FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
            if (tagCell && tagCell.superview == cell.superview) {
                // 调整单元格位置，为胶囊按钮预留空间
                CGRect frame = cell.frame;
                if (frame.origin.y < 80) { // 如果单元格在胶囊按钮区域
                    frame.origin.y = MAX(frame.origin.y, 72); // 胶囊按钮高度
                    cell.frame = frame;
                }
            }
        }
    } @catch (NSException *exception) {
        // 自定义逻辑异常，静默处理
    }
}

static void hooked_CommonMessageCellView_layoutSubviews(id self, SEL _cmd) {
    // 调用原始方法
    if (orig_CommonMessageCellView_layoutSubviews) {
        @try {
            ((void(*)(id, SEL))orig_CommonMessageCellView_layoutSubviews)(self, _cmd);
        } @catch (NSException *exception) {
            // 原始方法异常，静默处理
        }
    }
    
    // 自定义逻辑：确保消息单元格不与胶囊按钮重叠
    @try {
        UIView *cellView = (UIView *)self;
        if (cellView && [cellView isKindOfClass:[UIView class]] && cellView.superview) {
            CGRect frame = cellView.frame;
            if (frame.origin.y < 80) {
                frame.origin.y = MAX(frame.origin.y, 72);
                cellView.frame = frame;
            }
        }
    } @catch (NSException *exception) {
        // 自定义逻辑异常，静默处理
    }
}

static void hooked_WCPulseBadgeView_updateAllBadgeViews(id self, SEL _cmd) {
    // 调用原始方法
    if (orig_WCPulseBadgeView_updateAllBadgeViews) {
        @try {
            ((void(*)(id, SEL))orig_WCPulseBadgeView_updateAllBadgeViews)(self, _cmd);
        } @catch (NSException *exception) {
            // 原始方法异常，静默处理
        }
    }
    
    // 自定义逻辑：更新浮动标签视图
    @try {
        [[FloatingTagCell sharedInstance] refreshAppearance];
    } @catch (NSException *exception) {
        // 自定义逻辑异常，静默处理
    }
}

%end

// WCPulseConfig前向声明
@class WCPulseConfig;

// 运行时添加的方法实现
static void wechat_insertFloatingTagCell_implementation(id self, SEL _cmd) {
    [[MainLayoutManager sharedManager] insertFloatingTagCellInChatList];
}

static void wechat_updateFloatingTagCellLayout_implementation(id self, SEL _cmd) {
    FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
    if (tagCell) {
        [tagCell setNeedsLayout];
        [tagCell layoutIfNeeded];
    }
}

#pragma mark - MSHookMessageEx初始化

%ctor {
    @autoreleasepool {
        // 获取微信核心类
        Class MainFrameTableViewClass = objc_getClass("MainFrameTableView");
        Class MMTableViewCellClass = objc_getClass("MMTableViewCell");
        Class CommonMessageCellViewClass = objc_getClass("CommonMessageCellView");
        
        // Core classes status check removed
        
        if (MainFrameTableViewClass) {
            // Hook MainFrameTableView的关键方法 - 添加方法存在性检查
            if ([MainFrameTableViewClass instancesRespondToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
                MSHookMessageEx(MainFrameTableViewClass, 
                               @selector(tableView:willDisplayCell:forRowAtIndexPath:), 
                               (IMP)hooked_MainFrameTableView_willDisplayCell, 
                               &orig_MainFrameTableView_willDisplayCell);
                // Successfully hooked tableView:willDisplayCell:forRowAtIndexPath:
            } else {
                // WARNING: tableView:willDisplayCell:forRowAtIndexPath: method not found
            }
            
            if ([MainFrameTableViewClass instancesRespondToSelector:@selector(initWithFrame:style:)]) {
                MSHookMessageEx(MainFrameTableViewClass, 
                               @selector(initWithFrame:style:), 
                               (IMP)hooked_MainFrameTableView_initWithFrame, 
                               &orig_MainFrameTableView_initWithFrame);
                // Successfully hooked initWithFrame:style:
            } else {
                // WARNING: initWithFrame:style: method not found
            }
            
            if ([MainFrameTableViewClass instancesRespondToSelector:@selector(setTableHeaderView:)]) {
                MSHookMessageEx(MainFrameTableViewClass, 
                               @selector(setTableHeaderView:), 
                               (IMP)hooked_MainFrameTableView_setTableHeaderView, 
                               &orig_MainFrameTableView_setTableHeaderView);
                // Successfully hooked setTableHeaderView:
            } else {
                // WARNING: setTableHeaderView: method not found
            }
        }
        
        if (MMTableViewCellClass) {
            // Hook MMTableViewCell的layoutSubviews方法 - 添加方法存在性检查
            if ([MMTableViewCellClass instancesRespondToSelector:@selector(layoutSubviews)]) {
                MSHookMessageEx(MMTableViewCellClass, 
                               @selector(layoutSubviews), 
                               (IMP)hooked_MMTableViewCell_layoutSubviews, 
                               &orig_MMTableViewCell_layoutSubviews);
                // Successfully hooked MMTableViewCell layoutSubviews
            }
        }
        
        if (CommonMessageCellViewClass) {
            // Hook CommonMessageCellView的layoutSubviews方法 - 添加方法存在性检查
            if ([CommonMessageCellViewClass instancesRespondToSelector:@selector(layoutSubviews)]) {
                MSHookMessageEx(CommonMessageCellViewClass, 
                               @selector(layoutSubviews), 
                               (IMP)hooked_CommonMessageCellView_layoutSubviews, 
                               &orig_CommonMessageCellView_layoutSubviews);
            }
        }
        
        // Hook WCPulseBadgeView的updateAllBadgeViews方法 - 添加安全检查
        Class WCPulseBadgeViewClass = objc_getClass("WCPulseBadgeView");
        if (WCPulseBadgeViewClass) {
            if ([WCPulseBadgeViewClass instancesRespondToSelector:@selector(updateAllBadgeViews)]) {
                MSHookMessageEx(WCPulseBadgeViewClass, 
                               @selector(updateAllBadgeViews), 
                               (IMP)hooked_WCPulseBadgeView_updateAllBadgeViews, 
                               &orig_WCPulseBadgeView_updateAllBadgeViews);
            }
        }
        
        // 添加运行时方法到现有类
        Class UIViewControllerClass = [UIViewController class];
        if (UIViewControllerClass) {
            // 添加胶囊按钮相关方法
            class_addMethod(UIViewControllerClass, 
                           @selector(wechat_insertFloatingTagCell), 
                           (IMP)wechat_insertFloatingTagCell_implementation, 
                           "v@:");
            
            class_addMethod(UIViewControllerClass, 
                           @selector(wechat_updateFloatingTagCellLayout), 
                           (IMP)wechat_updateFloatingTagCellLayout_implementation, 
                           "v@:");
        }
        
        // 初始化配置管理系统 - 添加安全检查
        Class configClass = objc_getClass("WCPulseConfig");
        if (configClass && [configClass respondsToSelector:@selector(sharedConfig)]) {
            @try {
                [configClass performSelector:@selector(sharedConfig)];
                // WCPulseConfig initialized successfully
            } @catch (NSException *exception) {
                // ERROR: Failed to initialize WCPulseConfig
            }
        }
        
        // 初始化WCPulseSessionMgr - 添加安全检查
        Class WCPulseSessionMgrClass = objc_getClass("WCPulseSessionMgr");
        if (WCPulseSessionMgrClass && [WCPulseSessionMgrClass respondsToSelector:@selector(shared)]) {
            @try {
                id sessionMgr = [WCPulseSessionMgrClass performSelector:@selector(shared)];
                if (sessionMgr) {
                    // WCPulseSessionMgr initialized successfully
                    
                    // 设置默认分组 - 添加方法检查
                    if ([sessionMgr respondsToSelector:@selector(setupDefaultGroups)]) {
                        [sessionMgr performSelector:@selector(setupDefaultGroups)];
                    }
                    
                    // 初始加载会话数据 - 添加方法检查
                    if ([sessionMgr respondsToSelector:@selector(reloadSessions)]) {
                        [sessionMgr performSelector:@selector(reloadSessions)];
                    }
                }
            } @catch (NSException *exception) {
            }
        }
        
        // 注册标签选择变更通知监听
        [[NSNotificationCenter defaultCenter] addObserverForName:@"TagSelectionChanged" 
                                                          object:nil 
                                                           queue:[NSOperationQueue mainQueue] 
                                                      usingBlock:^(NSNotification *note) {
            // 标签选择变更时的处理
            NSDictionary *userInfo = note.userInfo;
            NSString *selectedTag = userInfo[@"selectedTag"];
            NSNumber *selectedIndex = userInfo[@"selectedIndex"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // 通知会话管理器更新过滤 - 添加安全检查
                @try {
                    Class WCPulseSessionMgrClass = objc_getClass("WCPulseSessionMgr");
                    if (WCPulseSessionMgrClass && [WCPulseSessionMgrClass respondsToSelector:@selector(shared)]) {
                        id sessionMgr = [WCPulseSessionMgrClass performSelector:@selector(shared)];
                        if (sessionMgr) {
                            if ([sessionMgr respondsToSelector:@selector(setCurrentSelectGroup:)]) {
                                [sessionMgr performSelector:@selector(setCurrentSelectGroup:) withObject:selectedTag];
                            }
                            
                            // 重新加载会话数据以应用过滤
                            if ([sessionMgr respondsToSelector:@selector(reloadSessions)]) {
                                [sessionMgr performSelector:@selector(reloadSessions)];
                            }
                        }
                    }
                } @catch (NSException *exception) {
                    // ERROR: Exception in tag selection handler
                }
                
                // Tag selection changed
            });
        }];
        
        // 注册配置变更通知监听
        [[NSNotificationCenter defaultCenter] addObserverForName:@"WCPulseBadgeConfigChanged" 
                                                          object:nil 
                                                           queue:[NSOperationQueue mainQueue] 
                                                      usingBlock:^(NSNotification *note) {
            // 徽章配置变更时的处理
            dispatch_async(dispatch_get_main_queue(), ^{
                // 更新所有徽章视图 - 添加安全检查
                @try {
                    Class badgeViewClass = objc_getClass("WCPulseBadgeView");
                    if (badgeViewClass && [badgeViewClass respondsToSelector:@selector(sharedInstance)]) {
                        id sharedBadgeView = [badgeViewClass performSelector:@selector(sharedInstance)];
                        if (sharedBadgeView && [sharedBadgeView respondsToSelector:@selector(updateAllBadgeViews)]) {
                            [sharedBadgeView performSelector:@selector(updateAllBadgeViews)];
                        }
                    }
                } @catch (NSException *exception) {
                    // ERROR: Exception in badge config handler
                }
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"WCPulseFloatingTagCellConfigChanged" 
                                                          object:nil 
                                                           queue:[NSOperationQueue mainQueue] 
                                                      usingBlock:^(NSNotification *note) {
            // 胶囊按钮显示配置变更时的处理
            BOOL shouldShow = [note.object boolValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                // 胶囊按钮显示配置变更处理 - 添加安全检查
                @try {
                    FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
                    if (tagCell) {
                        tagCell.hidden = !shouldShow;
                        if (shouldShow) {
                            MainLayoutManager *layoutManager = [MainLayoutManager sharedManager];
                            if (layoutManager && [layoutManager respondsToSelector:@selector(insertFloatingTagCellInChatList)]) {
                                [layoutManager insertFloatingTagCellInChatList];
                            }
                        } else {
                            [tagCell removeFromSuperview];
                        }
                    }
                } @catch (NSException *exception) {
                    // ERROR: Exception in floating tag config handler
                }
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"WCPulseGroupConfigChanged" 
                                                          object:nil 
                                                           queue:[NSOperationQueue mainQueue] 
                                                      usingBlock:^(NSNotification *note) {
            // 分组配置变更时的处理
            NSArray *configurations = note.object;
            dispatch_async(dispatch_get_main_queue(), ^{
                // 更新胶囊按钮的分组显示 - 添加安全检查
                @try {
                    FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
                    if (tagCell && [tagCell respondsToSelector:@selector(updateGroupConfigurations:)]) {
                        [tagCell performSelector:@selector(updateGroupConfigurations:) withObject:configurations];
                    }
                } @catch (NSException *exception) {
                    // ERROR: Exception in group config handler
                }
            });
        }];
    }
}


#pragma mark - UIViewController扩展

%hook UIViewController

%new
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

%new
- (void)wechat_installViewSelector {
    @try {
        NSString *className = NSStringFromClass([self class]);
        
        // 只对微信主界面生效
        if (![className containsString:@"MainFrame"]) {
            return;
        }
        
        static BOOL installed = NO;
        if (installed) {
            return;
        }
        installed = YES;
                
        // 检查导航栏是否存在
        if (!self.navigationController || !self.navigationController.navigationBar) {
            return;
        }
        
        // 创建汉堡菜单按钮
        UINavigationItem *navItem = self.navigationItem;
        NSMutableArray *rightItems = [navItem.rightBarButtonItems mutableCopy] ?: [NSMutableArray array];
        
        // 检查是否已存在汉堡菜单按钮
        BOOL hasMoreButton = NO;
        for (UIBarButtonItem *item in rightItems) {
            if (item.customView && [item.customView isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)item.customView;
                // 检查按钮是否有我们的target-action
                NSArray *targets = [button allTargets].allObjects;
                for (id target in targets) {
                    if ([target respondsToSelector:@selector(wechat_showGroupSelectionMenu)]) {
                        hasMoreButton = YES;
                        break;
                    }
                }
                if (hasMoreButton) break;
            }
        }
        
        if (!hasMoreButton) {
            // 创建自定义汉堡菜单按钮，使用三条横线样式
            UIButton *customMoreButton = [UIButton buttonWithType:UIButtonTypeSystem];
            customMoreButton.frame = CGRectMake(0, 0, 44, 44);
            
            // 创建三条长短不一的横线图层
            CAShapeLayer *menuLayer = [CAShapeLayer layer];
            menuLayer.frame = CGRectMake(12, 12, 20, 20);
            menuLayer.fillColor = [UIColor systemBlueColor].CGColor;
            
            // 绘制三条长短不一的横线路径
            UIBezierPath *menuPath = [UIBezierPath bezierPath];
            // 第一条线（最长）
            [menuPath moveToPoint:CGPointMake(0, 3)];
            [menuPath addLineToPoint:CGPointMake(20, 3)];
            [menuPath addLineToPoint:CGPointMake(20, 5)];
            [menuPath addLineToPoint:CGPointMake(0, 5)];
            [menuPath closePath];
            
            // 第二条线（中等长度）
            [menuPath moveToPoint:CGPointMake(4, 10)];
            [menuPath addLineToPoint:CGPointMake(20, 10)];
            [menuPath addLineToPoint:CGPointMake(20, 12)];
            [menuPath addLineToPoint:CGPointMake(4, 12)];
            [menuPath closePath];
            
            // 第三条线（最短）
            [menuPath moveToPoint:CGPointMake(8, 17)];
            [menuPath addLineToPoint:CGPointMake(20, 17)];
            [menuPath addLineToPoint:CGPointMake(20, 19)];
            [menuPath addLineToPoint:CGPointMake(8, 19)];
            [menuPath closePath];
            
            menuLayer.path = menuPath.CGPath;
            [customMoreButton.layer addSublayer:menuLayer];
            
            // 设置按钮颜色
            customMoreButton.tintColor = [UIColor systemBlueColor];
            [customMoreButton addTarget:self action:@selector(wechat_showGroupSelectionMenu) forControlEvents:UIControlEventTouchUpInside];
            
            // 创建UIBarButtonItem包装自定义按钮
            UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithCustomView:customMoreButton];
            
            // 将按钮插入到最前面，使其在微信+按钮左边
            [rightItems insertObject:moreButton atIndex:0];
            navItem.rightBarButtonItems = rightItems;
        }
        
    } @catch (NSException *exception) {
        // 异常处理
    }
}

%new
- (void)wechat_handleViewModeChange:(UISegmentedControl *)sender {
    @try {
        NSInteger selectedIndex = sender.selectedSegmentIndex;        
        switch (selectedIndex) {
            case 0: // 类别模式
                [self wechat_enableCategoryView];
                break;
            case 1: // 列表模式
                [self wechat_enableListView];
                break;
            default:
            break;
        }
    } @catch (NSException *exception) {
        // 异常处理已移除日志
    }
}

#pragma mark - UI交互

%new
- (void)wechat_showGroupSelectionMenu {
    @try {        
        UIViewController *menuVC = [[UIViewController alloc] init];
        menuVC.modalPresentationStyle = UIModalPresentationPopover;
        
        // 根据屏幕尺寸自适应弹窗大小 - 进一步缩小
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat popoverWidth = MIN(240, screenWidth * 0.6);   // 最大240，或屏幕宽度的60%
        CGFloat popoverHeight = MIN(280, screenHeight * 0.38); // 最大280，或屏幕高度的38%
        
        menuVC.preferredContentSize = CGSizeMake(popoverWidth, popoverHeight);
        menuVC.view.backgroundColor = [UIColor whiteColor];
        menuVC.view.layer.cornerRadius = 16;
        menuVC.view.layer.masksToBounds = YES;
        
        // 中间手机图标 - 类别模式（选中状态）- 相对定位
        CGFloat containerWidth = 80;
        CGFloat containerX = (popoverWidth - containerWidth * 2) / 3; // 左侧容器位置
        UIView *categoryContainer = [[UIView alloc] initWithFrame:CGRectMake(containerX, 20, containerWidth, 120)];
        [menuVC.view addSubview:categoryContainer];
        
        // 高级彩色手机图标背景 - 渐变效果
        UIView *categoryPhoneBg = [[UIView alloc] initWithFrame:CGRectMake(15, 10, 50, 80)];
        
        // 创建渐变层
        CAGradientLayer *phoneGradient = [CAGradientLayer layer];
        phoneGradient.frame = categoryPhoneBg.bounds;
        phoneGradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:1.0].CGColor
        ];
        phoneGradient.startPoint = CGPointMake(0, 0);
        phoneGradient.endPoint = CGPointMake(1, 1);
        phoneGradient.cornerRadius = 10;
        [categoryPhoneBg.layer addSublayer:phoneGradient];
        
        // 添加阴影效果
        categoryPhoneBg.layer.shadowColor = [UIColor blackColor].CGColor;
        categoryPhoneBg.layer.shadowOffset = CGSizeMake(0, 3);
        categoryPhoneBg.layer.shadowOpacity = 0.3;
        categoryPhoneBg.layer.shadowRadius = 5;
        categoryPhoneBg.layer.cornerRadius = 10;
        [categoryContainer addSubview:categoryPhoneBg];
        
        // 超清手机屏幕内容 - 模拟分类界面
        UIView *categoryScreen = [[UIView alloc] initWithFrame:CGRectMake(18, 15, 44, 70)];
        categoryScreen.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:1.0 alpha:1.0];
        categoryScreen.layer.cornerRadius = 6;
        categoryScreen.layer.borderWidth = 0.5;
        categoryScreen.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        [categoryContainer addSubview:categoryScreen];
        
        // 顶部状态栏模拟
        UIView *statusBar = [[UIView alloc] initWithFrame:CGRectMake(20, 17, 40, 3)];
        statusBar.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
        statusBar.layer.cornerRadius = 1.5;
        [categoryContainer addSubview:statusBar];
        
        // 顶部彩色导航条
        UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(20, 22, 40, 10)];
        CAGradientLayer *topBarGradient = [CAGradientLayer layer];
        topBarGradient.frame = topBar.bounds;
        topBarGradient.colors = @[
            (id)[UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0].CGColor
        ];
        topBarGradient.startPoint = CGPointMake(0, 0);
        topBarGradient.endPoint = CGPointMake(1, 0);
        topBarGradient.cornerRadius = 2;
        [topBar.layer addSublayer:topBarGradient];
        topBar.layer.cornerRadius = 2;
        [categoryContainer addSubview:topBar];
        
        // 彩色分类方块 - 主要
        UIView *block1 = [[UIView alloc] initWithFrame:CGRectMake(22, 36, 10, 10)];
        CAGradientLayer *block1Gradient = [CAGradientLayer layer];
        block1Gradient.frame = block1.bounds;
        block1Gradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:1.0].CGColor
        ];
        block1Gradient.cornerRadius = 3;
        [block1.layer addSublayer:block1Gradient];
        block1.layer.cornerRadius = 3;
        block1.layer.shadowColor = [UIColor systemBlueColor].CGColor;
        block1.layer.shadowOffset = CGSizeMake(0, 1);
        block1.layer.shadowOpacity = 0.4;
        block1.layer.shadowRadius = 2;
        [categoryContainer addSubview:block1];
        
        // 彩色分类方块 - 交易
        UIView *block2 = [[UIView alloc] initWithFrame:CGRectMake(35, 36, 10, 10)];
        CAGradientLayer *block2Gradient = [CAGradientLayer layer];
        block2Gradient.frame = block2.bounds;
        block2Gradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.1 green:0.6 blue:0.3 alpha:1.0].CGColor
        ];
        block2Gradient.cornerRadius = 3;
        [block2.layer addSublayer:block2Gradient];
        block2.layer.cornerRadius = 3;
        block2.layer.shadowColor = [UIColor systemGreenColor].CGColor;
        block2.layer.shadowOffset = CGSizeMake(0, 1);
        block2.layer.shadowOpacity = 0.4;
        block2.layer.shadowRadius = 2;
        [categoryContainer addSubview:block2];
        
        // 彩色分类方块 - 更新
        UIView *block3 = [[UIView alloc] initWithFrame:CGRectMake(48, 36, 10, 10)];
        CAGradientLayer *block3Gradient = [CAGradientLayer layer];
        block3Gradient.frame = block3.bounds;
        block3Gradient.colors = @[
            (id)[UIColor colorWithRed:0.8 green:0.4 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:1.0].CGColor
        ];
        block3Gradient.cornerRadius = 3;
        [block3.layer addSublayer:block3Gradient];
        block3.layer.cornerRadius = 3;
        block3.layer.shadowColor = [UIColor systemPurpleColor].CGColor;
        block3.layer.shadowOffset = CGSizeMake(0, 1);
        block3.layer.shadowOpacity = 0.4;
        block3.layer.shadowRadius = 2;
        [categoryContainer addSubview:block3];
        
        // 彩色分类方块 - 推广
        UIView *block4 = [[UIView alloc] initWithFrame:CGRectMake(22, 49, 10, 10)];
        CAGradientLayer *block4Gradient = [CAGradientLayer layer];
        block4Gradient.frame = block4.bounds;
        block4Gradient.colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.5 blue:0.2 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:1.0].CGColor
        ];
        block4Gradient.cornerRadius = 3;
        [block4.layer addSublayer:block4Gradient];
        block4.layer.cornerRadius = 3;
        block4.layer.shadowColor = [UIColor systemOrangeColor].CGColor;
        block4.layer.shadowOffset = CGSizeMake(0, 1);
        block4.layer.shadowOpacity = 0.4;
        block4.layer.shadowRadius = 2;
        [categoryContainer addSubview:block4];
        
        // 添加细节装饰线条
        UIView *detailLine1 = [[UIView alloc] initWithFrame:CGRectMake(35, 50, 13, 2)];
        detailLine1.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        detailLine1.layer.cornerRadius = 1;
        [categoryContainer addSubview:detailLine1];
        
        UIView *detailLine2 = [[UIView alloc] initWithFrame:CGRectMake(22, 62, 26, 2)];
        detailLine2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        detailLine2.layer.cornerRadius = 1;
        [categoryContainer addSubview:detailLine2];
        
        UIView *detailLine3 = [[UIView alloc] initWithFrame:CGRectMake(22, 67, 18, 2)];
         detailLine3.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
         detailLine3.layer.cornerRadius = 1;
         [categoryContainer addSubview:detailLine3];
        
        // 蓝色区域
        UIView *blueArea = [[UIView alloc] initWithFrame:CGRectMake(20, 50, 40, 25)];
        blueArea.backgroundColor = [UIColor colorWithRed:0.7 green:0.85 blue:1.0 alpha:1.0];
        blueArea.layer.cornerRadius = 2;
        [categoryContainer addSubview:blueArea];
        
        // 右侧手机图标 - 列表模式（未选中状态）- 相对定位
        CGFloat listContainerX = containerX + containerWidth + (popoverWidth - containerWidth * 2) / 3;
        UIView *listContainer = [[UIView alloc] initWithFrame:CGRectMake(listContainerX, 20, containerWidth, 120)];
        [menuVC.view addSubview:listContainer];
        
        // 高级彩色手机图标背景 - 渐变效果
        UIView *listPhoneBg = [[UIView alloc] initWithFrame:CGRectMake(15, 10, 50, 80)];
        
        // 创建渐变层
        CAGradientLayer *listPhoneGradient = [CAGradientLayer layer];
        listPhoneGradient.frame = listPhoneBg.bounds;
        listPhoneGradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:1.0].CGColor
        ];
        listPhoneGradient.startPoint = CGPointMake(0, 0);
        listPhoneGradient.endPoint = CGPointMake(1, 1);
        listPhoneGradient.cornerRadius = 10;
        [listPhoneBg.layer addSublayer:listPhoneGradient];
        
        // 添加阴影效果
        listPhoneBg.layer.shadowColor = [UIColor blackColor].CGColor;
        listPhoneBg.layer.shadowOffset = CGSizeMake(0, 3);
        listPhoneBg.layer.shadowOpacity = 0.3;
        listPhoneBg.layer.shadowRadius = 5;
        listPhoneBg.layer.cornerRadius = 10;
        [listContainer addSubview:listPhoneBg];
        
        // 超清手机屏幕内容 - 模拟列表界面
        UIView *listScreen = [[UIView alloc] initWithFrame:CGRectMake(18, 15, 44, 70)];
        listScreen.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:1.0 alpha:1.0];
        listScreen.layer.cornerRadius = 6;
        listScreen.layer.borderWidth = 0.5;
        listScreen.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        [listContainer addSubview:listScreen];
        
        // 顶部状态栏模拟
        UIView *listStatusBar = [[UIView alloc] initWithFrame:CGRectMake(20, 17, 40, 3)];
        listStatusBar.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
        listStatusBar.layer.cornerRadius = 1.5;
        [listContainer addSubview:listStatusBar];
        
        // 顶部彩色导航条
        UIView *listTopBar = [[UIView alloc] initWithFrame:CGRectMake(20, 22, 40, 10)];
        CAGradientLayer *listTopBarGradient = [CAGradientLayer layer];
        listTopBarGradient.frame = listTopBar.bounds;
        listTopBarGradient.colors = @[
            (id)[UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0].CGColor
        ];
        listTopBarGradient.startPoint = CGPointMake(0, 0);
        listTopBarGradient.endPoint = CGPointMake(1, 0);
        listTopBarGradient.cornerRadius = 2;
        [listTopBar.layer addSublayer:listTopBarGradient];
        listTopBar.layer.cornerRadius = 2;
        [listContainer addSubview:listTopBar];
        
        // 彩色列表项模拟 - 主要
        UIView *listItem1 = [[UIView alloc] initWithFrame:CGRectMake(22, 36, 36, 8)];
        CAGradientLayer *item1Gradient = [CAGradientLayer layer];
        item1Gradient.frame = listItem1.bounds;
        item1Gradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.8].CGColor,
            (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:0.8].CGColor
        ];
        item1Gradient.startPoint = CGPointMake(0, 0);
        item1Gradient.endPoint = CGPointMake(1, 0);
        item1Gradient.cornerRadius = 2;
        [listItem1.layer addSublayer:item1Gradient];
        listItem1.layer.cornerRadius = 2;
        [listContainer addSubview:listItem1];
        
        // 彩色列表项模拟 - 交易
        UIView *listItem2 = [[UIView alloc] initWithFrame:CGRectMake(22, 47, 36, 8)];
        CAGradientLayer *item2Gradient = [CAGradientLayer layer];
        item2Gradient.frame = listItem2.bounds;
        item2Gradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:0.8].CGColor,
            (id)[UIColor colorWithRed:0.1 green:0.6 blue:0.3 alpha:0.8].CGColor
        ];
        item2Gradient.startPoint = CGPointMake(0, 0);
        item2Gradient.endPoint = CGPointMake(1, 0);
        item2Gradient.cornerRadius = 2;
        [listItem2.layer addSublayer:item2Gradient];
        listItem2.layer.cornerRadius = 2;
        [listContainer addSubview:listItem2];
        
        // 彩色列表项模拟 - 更新
        UIView *listItem3 = [[UIView alloc] initWithFrame:CGRectMake(22, 58, 36, 8)];
        CAGradientLayer *item3Gradient = [CAGradientLayer layer];
        item3Gradient.frame = listItem3.bounds;
        item3Gradient.colors = @[
            (id)[UIColor colorWithRed:0.8 green:0.4 blue:1.0 alpha:0.8].CGColor,
            (id)[UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:0.8].CGColor
        ];
        item3Gradient.startPoint = CGPointMake(0, 0);
        item3Gradient.endPoint = CGPointMake(1, 0);
        item3Gradient.cornerRadius = 2;
        [listItem3.layer addSublayer:item3Gradient];
        listItem3.layer.cornerRadius = 2;
        [listContainer addSubview:listItem3];
        
        // 彩色列表项模拟 - 推广
        UIView *listItem4 = [[UIView alloc] initWithFrame:CGRectMake(22, 69, 36, 8)];
        CAGradientLayer *item4Gradient = [CAGradientLayer layer];
        item4Gradient.frame = listItem4.bounds;
        item4Gradient.colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.5 blue:0.2 alpha:0.8].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.8].CGColor
        ];
        item4Gradient.startPoint = CGPointMake(0, 0);
        item4Gradient.endPoint = CGPointMake(1, 0);
        item4Gradient.cornerRadius = 2;
        [listItem4.layer addSublayer:item4Gradient];
        listItem4.layer.cornerRadius = 2;
        [listContainer addSubview:listItem4];
        
        // 底部选择圆圈 - 相对定位
        UIImageView *categoryCheck = [[UIImageView alloc] initWithFrame:CGRectMake(containerX + containerWidth/2 - 10, 150, 20, 20)];
        categoryCheck.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        categoryCheck.tintColor = [UIColor systemBlueColor];
        [menuVC.view addSubview:categoryCheck];
        
        UIImageView *listCheck = [[UIImageView alloc] initWithFrame:CGRectMake(listContainerX + containerWidth/2 - 10, 150, 20, 20)];
        listCheck.image = [UIImage systemImageNamed:@"circle"];
        listCheck.tintColor = [UIColor systemGray3Color];
        [menuVC.view addSubview:listCheck];
        
        // 标签 - 相对定位
        CGFloat labelY = popoverHeight * 0.70; // 相对于弹窗高度的70%位置，下移一些
        UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(containerX, labelY, containerWidth, 20)];
        categoryLabel.text = @"类别";
        categoryLabel.textAlignment = NSTextAlignmentCenter;
        categoryLabel.font = [UIFont systemFontOfSize:14];
        categoryLabel.textColor = [UIColor blackColor];
        [menuVC.view addSubview:categoryLabel];
        
        UILabel *listLabel = [[UILabel alloc] initWithFrame:CGRectMake(listContainerX, labelY, containerWidth, 20)];
        listLabel.text = @"列表视图";
        listLabel.textAlignment = NSTextAlignmentCenter;
        listLabel.font = [UIFont systemFontOfSize:14];
        listLabel.textColor = [UIColor blackColor];
        [menuVC.view addSubview:listLabel];
        
        // 分隔线 - 相对定位
        CGFloat separatorY = popoverHeight * 0.87;
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16, separatorY, popoverWidth - 32, 0.5)];
        separator.backgroundColor = [UIColor systemGray4Color];
        [menuVC.view addSubview:separator];
        
        // 关于类别标题 - 相对定位
        CGFloat aboutY = separatorY + 15;
        UILabel *aboutLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, aboutY, popoverWidth - 50, 20)];
        aboutLabel.text = @"关于类别";
        aboutLabel.font = [UIFont boldSystemFontOfSize:16];
        aboutLabel.textColor = [UIColor blackColor];
        [menuVC.view addSubview:aboutLabel];
        
        // 信息图标 - 相对定位，添加点击事件
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeSystem];
        infoButton.frame = CGRectMake(popoverWidth - 32, aboutY + 2, 16, 16);
        [infoButton setImage:[UIImage systemImageNamed:@"info.circle"] forState:UIControlStateNormal];
        infoButton.tintColor = [UIColor systemGray2Color];
        [infoButton addTarget:self action:@selector(wechat_showHelpInterface) forControlEvents:UIControlEventTouchUpInside];
        [menuVC.view addSubview:infoButton];
        
        // 功能说明标签也添加点击事件
        UITapGestureRecognizer *aboutTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wechat_showHelpInterface)];
        aboutLabel.userInteractionEnabled = YES;
        [aboutLabel addGestureRecognizer:aboutTap];
        
        
        // 添加点击事件 - 相对定位
        UIButton *categoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        categoryButton.frame = CGRectMake(containerX, 60, containerWidth, 180);
        [categoryButton addTarget:self action:@selector(wechat_selectCategoryMode) forControlEvents:UIControlEventTouchUpInside];
        [menuVC.view addSubview:categoryButton];
        
        UIButton *listButton = [UIButton buttonWithType:UIButtonTypeCustom];
        listButton.frame = CGRectMake(listContainerX, 60, containerWidth, 180);
        [listButton addTarget:self action:@selector(wechat_selectListMode) forControlEvents:UIControlEventTouchUpInside];
        [menuVC.view addSubview:listButton];
        
        UIButton *groupToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat toggleButtonY = popoverHeight - 50; // 距离底部50像素
        groupToggleButton.frame = CGRectMake(16, toggleButtonY, popoverWidth - 32, 40);
        [groupToggleButton addTarget:self action:@selector(wechat_toggleGroupOption) forControlEvents:UIControlEventTouchUpInside];
        [menuVC.view addSubview:groupToggleButton];
        
        UIPopoverPresentationController *popover = menuVC.popoverPresentationController;
        popover.delegate = self;
        
        // 找到三个点按钮作为弹出源
        UIBarButtonItem *moreButtonItem = nil;
        for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
            if ([item.customView isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)item.customView;
                if ([button.titleLabel.text isEqualToString:@"⋯"]) {
                    moreButtonItem = item;
                    break;
                }
            }
        }
        
        if (moreButtonItem && moreButtonItem.customView) {
            // 使用三个点按钮作为弹出源
            popover.barButtonItem = moreButtonItem;
        } else {
            // 备用方案：使用导航栏右侧第一个按钮的位置
            popover.sourceView = self.view;
            popover.sourceRect = CGRectMake(self.view.bounds.size.width - 80, 44, 44, 44);
        }
        
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
        
        [self presentViewController:menuVC animated:YES completion:nil];
        
    } @catch (NSException *exception) {
        
    }
}

%new
- (void)wechat_selectCategoryMode {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wechat_enableCategoryView];
    }];
}

%new
- (void)wechat_selectListMode {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wechat_enableListView];
    }];
}

%new
- (void)wechat_showHelpInterface {
    // 先关闭当前弹窗
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 创建功能说明界面
        UIViewController *helpVC = [[UIViewController alloc] init];
        helpVC.modalPresentationStyle = UIModalPresentationPageSheet;
        helpVC.view.backgroundColor = [UIColor systemBackgroundColor];
        
        // 导航栏
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:helpVC];
        helpVC.navigationItem.title = @"关于类别";
        
        // 创建关闭按钮
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:strongSelf action:@selector(wechat_closeHelpInterface)];
        helpVC.navigationItem.rightBarButtonItem = closeButton;
        
        // 为helpVC添加关闭方法
        objc_setAssociatedObject(helpVC, "navController", navController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 滚动视图
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:helpVC.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [helpVC.view addSubview:scrollView];
        
        CGFloat yOffset = 20;
        CGFloat margin = 16;
        CGFloat screenWidth = helpVC.view.bounds.size.width;
        
        // 顶部说明文字
        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 60)];
        topLabel.text = @"微信的聊天界面分组功能，模仿iOS18邮件类别分组，自动将聊天内容按类型整理分类。";
        topLabel.font = [UIFont systemFontOfSize:14];
        topLabel.textColor = [UIColor secondaryLabelColor];
        topLabel.numberOfLines = 0;
        [scrollView addSubview:topLabel];
        yOffset += 80;
        
        // 主要分类
        UIView *mainSection = [[UIView alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 120)];
        mainSection.backgroundColor = [UIColor secondarySystemBackgroundColor];
        mainSection.layer.cornerRadius = 12;
        [scrollView addSubview:mainSection];
        
        UILabel *mainIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 24, 24)];
        mainIcon.text = @"⭐️";
        mainIcon.font = [UIFont systemFontOfSize:18];
        [mainSection addSubview:mainIcon];
        
        UILabel *mainTitle = [[UILabel alloc] initWithFrame:CGRectMake(50, 16, screenWidth - 2*margin - 66, 24)];
        mainTitle.text = @"主要";
        mainTitle.font = [UIFont boldSystemFontOfSize:16];
        mainTitle.textColor = [UIColor labelColor];
        [mainSection addSubview:mainTitle];
        
        UILabel *mainDesc = [[UILabel alloc] initWithFrame:CGRectMake(50, 40, screenWidth - 2*margin - 66, 20)];
        mainDesc.text = @"重要的聊天对话";
        mainDesc.font = [UIFont systemFontOfSize:14];
        mainDesc.textColor = [UIColor secondaryLabelColor];
        [mainSection addSubview:mainDesc];
        
        UILabel *mainDetail = [[UILabel alloc] initWithFrame:CGRectMake(50, 65, screenWidth - 2*margin - 66, 40)];
        mainDetail.text = @"包含重要联系人的对话，如家人、密友、工作重要联系人等优先级较高的聊天。";
        mainDetail.font = [UIFont systemFontOfSize:12];
        mainDetail.textColor = [UIColor tertiaryLabelColor];
        mainDetail.numberOfLines = 0;
        [mainSection addSubview:mainDetail];
        yOffset += 140;
        
        // 交易分类
        UIView *tradeSection = [[UIView alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 120)];
        tradeSection.backgroundColor = [UIColor secondarySystemBackgroundColor];
        tradeSection.layer.cornerRadius = 12;
        [scrollView addSubview:tradeSection];
        
        UILabel *tradeIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 24, 24)];
        tradeIcon.text = @"💬";
        tradeIcon.font = [UIFont systemFontOfSize:18];
        [tradeSection addSubview:tradeIcon];
        
        UILabel *tradeTitle = [[UILabel alloc] initWithFrame:CGRectMake(50, 16, screenWidth - 2*margin - 66, 24)];
        tradeTitle.text = @"交易";
        tradeTitle.font = [UIFont boldSystemFontOfSize:16];
        tradeTitle.textColor = [UIColor labelColor];
        [tradeSection addSubview:tradeTitle];
        
        UILabel *tradeDesc = [[UILabel alloc] initWithFrame:CGRectMake(50, 40, screenWidth - 2*margin - 66, 20)];
        tradeDesc.text = @"支付相关对话";
        tradeDesc.font = [UIFont systemFontOfSize:14];
        tradeDesc.textColor = [UIColor secondaryLabelColor];
        [tradeSection addSubview:tradeDesc];
        
        UILabel *tradeDetail = [[UILabel alloc] initWithFrame:CGRectMake(50, 65, screenWidth - 2*margin - 66, 40)];
        tradeDetail.text = @"自动识别包含购物、支付、订单等交易相关内容的聊天对话。";
        tradeDetail.font = [UIFont systemFontOfSize:12];
        tradeDetail.textColor = [UIColor tertiaryLabelColor];
        tradeDetail.numberOfLines = 0;
        [tradeSection addSubview:tradeDetail];
        yOffset += 140;
        
        // 更新分类
        UIView *updateSection = [[UIView alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 120)];
        updateSection.backgroundColor = [UIColor secondarySystemBackgroundColor];
        updateSection.layer.cornerRadius = 12;
        [scrollView addSubview:updateSection];
        
        UILabel *updateIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 24, 24)];
        updateIcon.text = @"🎨";
        updateIcon.font = [UIFont systemFontOfSize:18];
        [updateSection addSubview:updateIcon];
        
        UILabel *updateTitle = [[UILabel alloc] initWithFrame:CGRectMake(50, 16, screenWidth - 2*margin - 66, 24)];
        updateTitle.text = @"新闻";
        updateTitle.font = [UIFont boldSystemFontOfSize:16];
        updateTitle.textColor = [UIColor labelColor];
        [updateSection addSubview:updateTitle];
        
        UILabel *updateDesc = [[UILabel alloc] initWithFrame:CGRectMake(50, 40, screenWidth - 2*margin - 66, 20)];
        updateDesc.text = @"通知、资讯类对话";
        updateDesc.font = [UIFont systemFontOfSize:14];
        updateDesc.textColor = [UIColor secondaryLabelColor];
        [updateSection addSubview:updateDesc];
        
        UILabel *updateDetail = [[UILabel alloc] initWithFrame:CGRectMake(50, 65, screenWidth - 2*margin - 66, 40)];
        updateDetail.text = @"包含系统通知、新闻资讯、订阅号消息等信息更新类的聊天内容。";
        updateDetail.font = [UIFont systemFontOfSize:12];
        updateDetail.textColor = [UIColor tertiaryLabelColor];
        updateDetail.numberOfLines = 0;
        [updateSection addSubview:updateDetail];
        yOffset += 140;
        
        // 推广分类
        UIView *promoSection = [[UIView alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 120)];
        promoSection.backgroundColor = [UIColor secondarySystemBackgroundColor];
        promoSection.layer.cornerRadius = 12;
        [scrollView addSubview:promoSection];
        
        UILabel *promoIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 24, 24)];
        promoIcon.text = @"⚡️";
        promoIcon.font = [UIFont systemFontOfSize:18];
        [promoSection addSubview:promoIcon];
        
        UILabel *promoTitle = [[UILabel alloc] initWithFrame:CGRectMake(50, 16, screenWidth - 2*margin - 66, 24)];
        promoTitle.text = @"推广";
        promoTitle.font = [UIFont boldSystemFontOfSize:16];
        promoTitle.textColor = [UIColor labelColor];
        [promoSection addSubview:promoTitle];
        
        UILabel *promoDesc = [[UILabel alloc] initWithFrame:CGRectMake(50, 40, screenWidth - 2*margin - 66, 20)];
        promoDesc.text = @"营销、广告类对话";
        promoDesc.font = [UIFont systemFontOfSize:14];
        promoDesc.textColor = [UIColor secondaryLabelColor];
        [promoSection addSubview:promoDesc];
        
        UILabel *promoDetail = [[UILabel alloc] initWithFrame:CGRectMake(50, 65, screenWidth - 2*margin - 66, 40)];
        promoDetail.text = @"自动识别包含营销推广、广告宣传、促销活动等商业推广内容的聊天。";
        promoDetail.font = [UIFont systemFontOfSize:12];
        promoDetail.textColor = [UIColor tertiaryLabelColor];
        promoDetail.numberOfLines = 0;
        [promoSection addSubview:promoDetail];
        yOffset += 140;
        
        // 底部说明
        UIView *bottomSection = [[UIView alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 60)];
        bottomSection.backgroundColor = [UIColor secondarySystemBackgroundColor];
        bottomSection.layer.cornerRadius = 12;
        [scrollView addSubview:bottomSection];
        
        UILabel *infoIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 20, 20)];
        infoIcon.text = @"ℹ️";
        infoIcon.font = [UIFont systemFontOfSize:16];
        [bottomSection addSubview:infoIcon];
        
        UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 16, screenWidth - 2*margin - 66, 28)];
        bottomLabel.text = @"智能分组功能会自动学习您的聊天习惯，持续优化分类准确性。";
        bottomLabel.font = [UIFont systemFontOfSize:14];
        bottomLabel.textColor = [UIColor secondaryLabelColor];
        bottomLabel.numberOfLines = 0;
        [bottomSection addSubview:bottomLabel];
        yOffset += 80;
        
        // 分组管理
        UILabel *restoreTitle = [[UILabel alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 30)];
        restoreTitle.text = @"分组管理";
        restoreTitle.font = [UIFont boldSystemFontOfSize:16];
        restoreTitle.textColor = [UIColor labelColor];
        [scrollView addSubview:restoreTitle];
        yOffset += 40;
        
        UILabel *restoreDesc = [[UILabel alloc] initWithFrame:CGRectMake(margin, yOffset, screenWidth - 2*margin, 40)];
        restoreDesc.text = @"可以手动调整聊天分组，长按对话可重新分类或移动到其他组别。";
        restoreDesc.font = [UIFont systemFontOfSize:14];
        restoreDesc.textColor = [UIColor secondaryLabelColor];
        restoreDesc.numberOfLines = 0;
        [scrollView addSubview:restoreDesc];
        yOffset += 60;
        
        // 设置滚动视图内容大小
        scrollView.contentSize = CGSizeMake(screenWidth, yOffset);
        
        [self presentViewController:navController animated:YES completion:nil];
    }];
}

%new
- (void)wechat_dismissHelpInterface {
    UINavigationController *navController = objc_getAssociatedObject(self, "helpNavController");
    if (navController) {
        [navController dismissViewControllerAnimated:YES completion:nil];
        objc_setAssociatedObject(self, "helpNavController", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

%new
- (void)wechat_closeHelpInterface {
    UINavigationController *navController = objc_getAssociatedObject(self, "navController");
    if (navController) {
        [navController dismissViewControllerAnimated:YES completion:nil];
        objc_setAssociatedObject(self, "navController", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end

#pragma mark - MainFrameItemView Hook

// Hook MainFrameItemView 聊天列表项的显示
%hook MainFrameItemView

- (void)updateWithCellData:(id)cellData {
    %orig;
    
    // 在更新数据后进行UI优化
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(optimizeItemViewLayout) withObject:nil afterDelay:0.1];
    });
}

- (void)setFrame:(CGRect)frame {
    %orig;
    
    // 当frame改变时，重新优化布局
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(optimizeItemViewLayout) withObject:nil afterDelay:0.1];
    });
}

%end
