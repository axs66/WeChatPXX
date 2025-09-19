//
//  Config.h
//  WeChat++
//
//  分组配置管理类头文件
//  有问题 联系pxx917144686
//

#import <Foundation/Foundation.h>

@interface Config : NSObject

/// 单例访问入口
+ (instancetype)sharedConfig;

/**
 * 获取分组过滤列表
 * @return 分组过滤数组
 */
+ (NSArray *)groupFilterList;

/**
 * 设置分组过滤列表
 * @param filterList 分组过滤数组
 */
+ (void)setGroupFilterList:(NSArray *)filterList;

/**
 * 获取配置字典
 * @return 配置字典
 */
+ (NSDictionary *)configDictionary;

/**
 * 保存配置字典
 * @param config 配置字典
 */
+ (void)saveConfigDictionary:(NSDictionary *)config;

@end

@interface WeChatSessionMgr : NSObject

@property (nonatomic, strong) NSMutableDictionary *groupList;

/**
 * 获取单例实例
 */
+ (instancetype)sharedInstance;

/**
 * 设置默认分组
 */
- (void)setupDefaultGroups;

/**
 * 重新加载会话
 */
- (void)reloadSessions;

/**
 * 获取分组列表
 */
- (NSMutableDictionary *)groupList;

@end
