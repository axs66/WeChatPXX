//
//  WeChatDataManager.h
//  WeChat++
//
//  微信数据管理器 - 使用FMDB进行数据存储
//  有问题 联系pxx917144686
//

#import <Foundation/Foundation.h>
#import "fmdb/FMDB.h"

@interface WeChatDataManager : NSObject

@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

/**
 * 获取单例实例
 */
+ (instancetype)sharedManager;

/**
 * 初始化数据库
 */
- (BOOL)initializeDatabase;

/**
 * 保存用户设置
 */
- (BOOL)saveUserSetting:(NSString *)key value:(NSString *)value;
- (NSString *)getUserSetting:(NSString *)key;
- (BOOL)removeUserSetting:(NSString *)key;

/**
 * 保存聊天记录过滤设置
 */
- (BOOL)saveChatFilter:(NSString *)filterName isEnabled:(BOOL)enabled;
- (BOOL)getChatFilterStatus:(NSString *)filterName;
- (NSArray *)getAllChatFilters;

/**
 * 保存悬浮标签配置
 */
- (BOOL)saveTagConfiguration:(NSArray *)tags selectedIndex:(NSInteger)selectedIndex;
- (NSDictionary *)getTagConfiguration;

/**
 * 保存界面布局设置
 */
- (BOOL)saveLayoutSetting:(NSString *)layoutKey frame:(CGRect)frame;
- (CGRect)getLayoutSetting:(NSString *)layoutKey;

/**
 * 清理过期数据
 */
- (BOOL)cleanupOldData:(NSInteger)daysToKeep;

/**
 * 数据库维护
 */
- (BOOL)vacuumDatabase;
- (NSInteger)getDatabaseSize;

@end