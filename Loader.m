//
//  Loader.m
//  WeChat Enhancement
//
//  有问题 联系pxx917144686
//

#import "Loader.h"
#import "MainLayoutManager.h"
#import "FloatingTagCell.h"
#import "FloatingTagView.h"
#import "Config.h"
#import <objc/runtime.h>
#import <substrate.h>

// MSHookMessageEx函数声明
extern void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

@interface Loader ()
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL hooksInstalled;
@end

@implementation Loader

+ (instancetype)sharedLoader {
    static Loader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Loader alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isLoaded = NO;
        _hooksInstalled = NO;
    }
    return self;
}

- (void)loadPlugin {
    if (self.isLoaded) {
        NSLog(@"[Loader] 插件已经加载，跳过重复加载");
        return;
    }
    
    NSLog(@"[Loader] 开始加载WCPulse插件");
    
    @try {
        // 1. 检查微信版本兼容性
        if (![self checkWeChatCompatibility]) {
            NSLog(@"[Loader] 微信版本不兼容，停止加载");
            return;
        }
        
        // 2. 初始化核心组件
        [self initializeCoreComponents];
        
        // 3. 安装所有Hook
        [self installAllHooks];
        
        // 4. 标记为已加载
        self.isLoaded = YES;
        
        NSLog(@"[Loader] WCPulse插件加载完成");
        
    } @catch (NSException *exception) {
        NSLog(@"[Loader] 插件加载失败: %@", exception.reason);
    }
}

- (BOOL)checkWeChatCompatibility {
    // 获取微信版本信息
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *version = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSLog(@"[Loader] 检测到微信版本: %@", version ?: @"未知");
    
    // 检查关键类是否存在
    Class mainFrameTableViewClass = objc_getClass("MainFrameTableView");
    Class mmTableViewCellClass = objc_getClass("MMTableViewCell");
    Class newMainFrameViewControllerClass = objc_getClass("NewMainFrameViewController");
    
    if (!mainFrameTableViewClass) {
        NSLog(@"[Loader] 警告: MainFrameTableView类未找到");
        return NO;
    }
    
    if (!mmTableViewCellClass) {
        NSLog(@"[Loader] 警告: MMTableViewCell类未找到");
        return NO;
    }
    
    if (!newMainFrameViewControllerClass) {
        NSLog(@"[Loader] 警告: NewMainFrameViewController类未找到");
        return NO;
    }
    
    NSLog(@"[Loader] 微信版本兼容性检查通过");
    return YES;
}

- (void)initializeCoreComponents {
    NSLog(@"[Loader] 初始化核心组件");
    
    @try {
        // 初始化MainLayoutManager
        MainLayoutManager *layoutManager = [MainLayoutManager sharedManager];
        if (layoutManager) {
            NSLog(@"[Loader] MainLayoutManager初始化成功");
        }
        
        // 初始化FloatingTagCell
        FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
        if (tagCell) {
            NSLog(@"[Loader] FloatingTagCell初始化成功");
        }
        
        // 初始化配置管理
        if ([Config class]) {
            NSLog(@"[Loader] Config类可用");
        }
        
    } @catch (NSException *exception) {
        NSLog(@"[Loader] 核心组件初始化失败: %@", exception.reason);
    }
}

- (void)installAllHooks {
    if (self.hooksInstalled) {
        NSLog(@"[Loader] Hook已安装，跳过重复安装");
        return;
    }
    
    NSLog(@"[Loader] 开始安装所有Hooks");
    
    @try {
        // 1. 安装消息相关Hook
        [self hookMessageMethods];
        
        // 2. 安装视频相关Hook
        [self hookVideoMethods];
        
        // 3. 安装会话相关Hook
        [self hookSessionMethods];
        
        self.hooksInstalled = YES;
        NSLog(@"[Loader] 所有Hooks安装完成");
        
    } @catch (NSException *exception) {
        NSLog(@"[Loader] Hook安装失败: %@", exception.reason);
    }
}

- (void)hookMessageMethods {
    NSLog(@"[Loader] 安装消息相关Hook");
    
    // 这里的Hook实现已经在Tweak.xm中完成
    // 主要包括MainFrameTableView的相关方法
    Class mainFrameTableViewClass = objc_getClass("MainFrameTableView");
    if (mainFrameTableViewClass) {
        NSLog(@"[Loader] MainFrameTableView Hook目标类找到");
    }
}

- (void)hookVideoMethods {
    NSLog(@"[Loader] 安装视频相关Hook");
    
    // 视频相关Hook可以在这里扩展
    // 目前主要关注聊天列表的胶囊按钮功能
}

- (void)hookSessionMethods {
    NSLog(@"[Loader] 安装会话相关Hook");
    
    // 会话相关Hook可以在这里扩展
    // 目前主要关注聊天列表的胶囊按钮功能
}

@end

#pragma mark - Plugin Entry Point

/**
 * 插件入口点 - 动态库构造函数
 * 当插件被加载时自动调用
 */
__attribute__((constructor))
static void WCPulsePluginEntry(void) {
    NSLog(@"[Loader] WCPulse插件入口点被调用");
    
    // 确保在主线程中初始化
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [[Loader sharedLoader] loadPlugin];
        }
    });
}