//
//  WCPulseLoader.m
//  WeChat++
//
//  WCPulse插件加载器实现 - 插件入口点和Hook管理
//  有问题 联系pxx917144686
//

#import "WCPulseLoader.h"
#import "MainLayoutManager.h"
#import "FloatingTagCell.h"
#import "Config.h"
#import <objc/runtime.h>

@implementation WCPulseLoader

+ (instancetype)sharedLoader {
    static WCPulseLoader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WCPulseLoader alloc] init];
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
        NSLog(@"[WCPulseLoader] 插件已加载，跳过重复加载");
        return;
    }
    
    NSLog(@"[WCPulseLoader] 开始加载WCPulse插件");
    
    // 1. 检查微信兼容性
    if (![self checkWeChatCompatibility]) {
        NSLog(@"[WCPulseLoader] 微信版本不兼容，插件加载失败");
        return;
    }
    
    // 2. 初始化核心组件
    [self initializeCoreComponents];
    
    // 3. 安装所有Hooks
    [self installAllHooks];
    
    self.isLoaded = YES;
    NSLog(@"[WCPulseLoader] WCPulse插件加载完成");
}

- (BOOL)checkWeChatCompatibility {
    NSLog(@"[WCPulseLoader] 检查微信兼容性");
    
    // 检查关键类是否存在
    Class MainFrameTableViewClass = objc_getClass("MainFrameTableView");
    Class MMTableViewCellClass = objc_getClass("MMTableViewCell");
    Class CommonMessageCellViewClass = objc_getClass("CommonMessageCellView");
    
    if (!MainFrameTableViewClass) {
        NSLog(@"[WCPulseLoader] MainFrameTableView类未找到");
        return NO;
    }
    
    if (!MMTableViewCellClass) {
        NSLog(@"[WCPulseLoader] MMTableViewCell类未找到");
        return NO;
    }
    
    if (!CommonMessageCellViewClass) {
        NSLog(@"[WCPulseLoader] CommonMessageCellView类未找到");
        return NO;
    }
    
    NSLog(@"[WCPulseLoader] 微信兼容性检查通过");
    return YES;
}

- (void)initializeCoreComponents {
    NSLog(@"[WCPulseLoader] 初始化核心组件");
    
    @try {
        // 初始化MainLayoutManager
        MainLayoutManager *layoutManager = [MainLayoutManager sharedManager];
        if (!layoutManager) {
            NSLog(@"[WCPulseLoader] MainLayoutManager初始化失败");
            return;
        }
        
        // 初始化FloatingTagCell
        FloatingTagCell *tagCell = [FloatingTagCell sharedInstance];
        if (!tagCell) {
            NSLog(@"[WCPulseLoader] FloatingTagCell初始化失败");
            return;
        }
        
        // 初始化Config
        [Config sharedConfig];
        
        NSLog(@"[WCPulseLoader] 核心组件初始化完成");
        
    } @catch (NSException *exception) {
        NSLog(@"[WCPulseLoader] 核心组件初始化异常: %@", exception.reason);
    }
}

- (void)installAllHooks {
    if (self.hooksInstalled) {
        NSLog(@"[WCPulseLoader] Hooks已安装，跳过重复安装");
        return;
    }
    
    NSLog(@"[WCPulseLoader] 开始安装所有Hooks");
    
    // 1. 安装消息相关Hook
    [self hookMessageMethods];
    
    // 2. 安装视频相关Hook  
    [self hookVideoMethods];
    
    // 3. 安装会话相关Hook
    [self hookSessionMethods];
    
    self.hooksInstalled = YES;
    NSLog(@"[WCPulseLoader] 所有Hooks安装完成");
}

- (void)hookMessageMethods {
    NSLog(@"[WCPulseLoader] 安装消息相关Hook");
    // Hook逻辑已在Tweak.xm中实现
}

- (void)hookVideoMethods {
    NSLog(@"[WCPulseLoader] 安装视频相关Hook");
    // 预留视频相关Hook
}

- (void)hookSessionMethods {
    NSLog(@"[WCPulseLoader] 安装会话相关Hook");
    // 预留会话相关Hook
}

@end

// 动态库构造函数，插件加载时自动调用
__attribute__((constructor))
static void WCPulsePluginEntry() {
    NSLog(@"[WCPulseLoader] WCPulse插件入口点被调用");
    
    // 确保在主线程中初始化
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WCPulseLoader sharedLoader] loadPlugin];
    });
}