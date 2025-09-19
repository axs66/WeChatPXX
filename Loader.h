//
//  Loader.h
//  WeChat Enhancement
//
//  有问题 联系pxx917144686
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Loader : NSObject

/**
 * 获取共享加载器实例
 */
+ (instancetype)sharedLoader;

/**
 * 加载插件
 */
- (void)loadPlugin;

/**
 * 安装所有Hook
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

/**
 * 检查微信版本兼容性
 */
- (BOOL)checkWeChatCompatibility;

/**
 * 初始化核心组件
 */
- (void)initializeCoreComponents;

@end

/**
 * 插件入口点 - 动态库构造函数
 */
__attribute__((constructor))
static void WCPulsePluginEntry(void);