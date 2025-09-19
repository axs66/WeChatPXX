//
//  WCPulseLoader.h
//  WeChat++
//
//  WCPulse插件加载器 - 插件入口点和Hook管理
//  有问题 联系pxx917144686
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WCPulseLoader : NSObject

@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL hooksInstalled;

/**
 * 获取单例实例
 */
+ (instancetype)sharedLoader;

/**
 * 加载插件
 */
- (void)loadPlugin;

/**
 * 检查微信兼容性
 */
- (BOOL)checkWeChatCompatibility;

/**
 * 初始化核心组件
 */
- (void)initializeCoreComponents;

/**
 * 安装所有Hooks
 */
- (void)installAllHooks;

/**
 * 安装消息相关Hook
 */
- (void)hookMessageMethods;

/**
 * 安装视频相关Hook
 */
- (void)hookVideoMethods;

/**
 * 安装会话相关Hook
 */
- (void)hookSessionMethods;

@end

// 插件入口点声明
__attribute__((constructor))
static void WCPulsePluginEntry(void);