//
//  DataManager.m
//  WeChat++
//
//  微信数据管理器实现 - 使用FMDB进行数据存储
//  有问题 联系pxx917144686
//

#import "DataManager.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation WeChatDataManager

static WeChatDataManager *_sharedManager = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeDatabase];
    }
    return self;
}

- (BOOL)initializeDatabase {
    // 获取Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:@"WeChatPlus.db"];
    
    // 创建数据库实例
    self.database = [FMDatabase databaseWithPath:databasePath];
    
    // 打开数据库
    if (![self.database open]) {
        // 数据库打开失败
        return NO;
    }
    
    // 创建数据库队列
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
    
    // 创建表结构
    return [self createTables];
}

- (BOOL)createTables {
    BOOL success = YES;
    
    // 创建用户设置表
    NSString *userSettingsSQL = @"CREATE TABLE IF NOT EXISTS user_settings (id INTEGER PRIMARY KEY AUTOINCREMENT, setting_key TEXT UNIQUE NOT NULL, setting_value TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)";
    
    if (![self.database executeUpdate:userSettingsSQL]) {
        // 创建用户设置表失败
        success = NO;
    }
    
    // 创建聊天过滤设置表
    NSString *chatFiltersSQL = @"CREATE TABLE IF NOT EXISTS chat_filters (id INTEGER PRIMARY KEY AUTOINCREMENT, filter_name TEXT UNIQUE NOT NULL, is_enabled INTEGER DEFAULT 1, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)";
    
    if (![self.database executeUpdate:chatFiltersSQL]) {
        // 创建聊天过滤表失败
        success = NO;
    }
    
    // 创建标签配置表
    NSString *tagConfigSQL = @"CREATE TABLE IF NOT EXISTS tag_configuration (id INTEGER PRIMARY KEY AUTOINCREMENT, tags_json TEXT NOT NULL, selected_index INTEGER DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)";
    
    if (![self.database executeUpdate:tagConfigSQL]) {
        // 创建标签配置表失败
        success = NO;
    }
    
    // 创建布局设置表
    NSString *layoutSettingsSQL = @"CREATE TABLE IF NOT EXISTS layout_settings (id INTEGER PRIMARY KEY AUTOINCREMENT, layout_key TEXT UNIQUE NOT NULL, frame_x REAL DEFAULT 0, frame_y REAL DEFAULT 0, frame_width REAL DEFAULT 0, frame_height REAL DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)";
    
    if (![self.database executeUpdate:layoutSettingsSQL]) {
        // 创建布局设置表失败
        success = NO;
    }
    
    // 创建索引提高查询性能
    [self.database executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_user_settings_key ON user_settings(setting_key)"];
    [self.database executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_chat_filters_name ON chat_filters(filter_name)"];
    [self.database executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_layout_settings_key ON layout_settings(layout_key)"];
    
    return success;
}

#pragma mark - 用户设置管理

- (BOOL)saveUserSetting:(NSString *)key value:(NSString *)value {
    if (!key) return NO;
    
    NSString *sql = @"INSERT OR REPLACE INTO user_settings (setting_key, setting_value, updated_at) VALUES (?, ?, datetime('now'))";
    return [self.database executeUpdate:sql, key, value];
}

- (NSString *)getUserSetting:(NSString *)key {
    if (!key) return nil;
    
    NSString *sql = @"SELECT setting_value FROM user_settings WHERE setting_key = ?";
    FMResultSet *resultSet = [self.database executeQuery:sql, key];
    
    NSString *value = nil;
    if ([resultSet next]) {
        value = [resultSet stringForColumn:@"setting_value"];
    }
    [resultSet close];
    
    return value;
}

- (BOOL)removeUserSetting:(NSString *)key {
    if (!key) return NO;
    
    NSString *sql = @"DELETE FROM user_settings WHERE setting_key = ?";
    return [self.database executeUpdate:sql, key];
}

#pragma mark - 聊天过滤设置

- (BOOL)saveChatFilter:(NSString *)filterName isEnabled:(BOOL)enabled {
    if (!filterName) return NO;
    
    NSString *sql = @"INSERT OR REPLACE INTO chat_filters (filter_name, is_enabled, updated_at) VALUES (?, ?, datetime('now'))";
    return [self.database executeUpdate:sql, filterName, @(enabled ? 1 : 0)];
}

- (BOOL)getChatFilterStatus:(NSString *)filterName {
    if (!filterName) return NO;
    
    NSString *sql = @"SELECT is_enabled FROM chat_filters WHERE filter_name = ?";
    FMResultSet *resultSet = [self.database executeQuery:sql, filterName];
    
    BOOL isEnabled = NO;
    if ([resultSet next]) {
        isEnabled = [resultSet boolForColumn:@"is_enabled"];
    }
    [resultSet close];
    
    return isEnabled;
}

- (NSArray *)getAllChatFilters {
    NSString *sql = @"SELECT filter_name, is_enabled FROM chat_filters ORDER BY created_at";
    FMResultSet *resultSet = [self.database executeQuery:sql];
    
    NSMutableArray *filters = [NSMutableArray array];
    while ([resultSet next]) {
        NSDictionary *filter = @{
            @"name": [resultSet stringForColumn:@"filter_name"],
            @"enabled": @([resultSet boolForColumn:@"is_enabled"])
        };
        [filters addObject:filter];
    }
    [resultSet close];
    
    return [filters copy];
}

#pragma mark - 标签配置管理

- (BOOL)saveTagConfiguration:(NSArray *)tags selectedIndex:(NSInteger)selectedIndex {
    if (!tags) return NO;
    
    // 将标签数组转换为JSON字符串
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tags options:0 error:&error];
    if (error) {
        // 标签序列化失败
        return NO;
    }
    
    NSString *tagsJSON = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // 删除旧配置
    [self.database executeUpdate:@"DELETE FROM tag_configuration"];
    
    // 插入新配置
    NSString *sql = @"INSERT INTO tag_configuration (tags_json, selected_index) VALUES (?, ?)";
    return [self.database executeUpdate:sql, tagsJSON, @(selectedIndex)];
}

- (NSDictionary *)getTagConfiguration {
    NSString *sql = @"SELECT tags_json, selected_index FROM tag_configuration ORDER BY created_at DESC LIMIT 1";
    FMResultSet *resultSet = [self.database executeQuery:sql];
    
    NSDictionary *config = nil;
    if ([resultSet next]) {
        NSString *tagsJSON = [resultSet stringForColumn:@"tags_json"];
        NSInteger selectedIndex = [resultSet intForColumn:@"selected_index"];
        
        // 解析JSON
        NSData *jsonData = [tagsJSON dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSArray *tags = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        
        if (!error && tags) {
            config = @{
                @"tags": tags,
                @"selectedIndex": @(selectedIndex)
            };
        }
    }
    [resultSet close];
    
    return config;
}

#pragma mark - 布局设置管理

- (BOOL)saveLayoutSetting:(NSString *)layoutKey frame:(CGRect)frame {
    if (!layoutKey) return NO;
    
    NSString *sql = @"INSERT OR REPLACE INTO layout_settings (layout_key, frame_x, frame_y, frame_width, frame_height, updated_at) VALUES (?, ?, ?, ?, ?, datetime('now'))";
    return [self.database executeUpdate:sql, layoutKey, @(frame.origin.x), @(frame.origin.y), @(frame.size.width), @(frame.size.height)];
}

- (CGRect)getLayoutSetting:(NSString *)layoutKey {
    if (!layoutKey) return CGRectZero;
    
    NSString *sql = @"SELECT frame_x, frame_y, frame_width, frame_height FROM layout_settings WHERE layout_key = ?";
    FMResultSet *resultSet = [self.database executeQuery:sql, layoutKey];
    
    CGRect frame = CGRectZero;
    if ([resultSet next]) {
        CGFloat x = [resultSet doubleForColumn:@"frame_x"];
        CGFloat y = [resultSet doubleForColumn:@"frame_y"];
        CGFloat width = [resultSet doubleForColumn:@"frame_width"];
        CGFloat height = [resultSet doubleForColumn:@"frame_height"];
        frame = CGRectMake(x, y, width, height);
    }
    [resultSet close];
    
    return frame;
}

#pragma mark - 数据库维护

- (BOOL)cleanupOldData:(NSInteger)daysToKeep {
    NSString *cutoffDate = [NSString stringWithFormat:@"datetime('now', '-%ld days')", (long)daysToKeep];
    
    // 清理旧的用户设置记录（保留最新的）
    NSString *cleanupSQL = [NSString stringWithFormat:@"DELETE FROM user_settings WHERE updated_at < %@", cutoffDate];
    
    return [self.database executeUpdate:cleanupSQL];
}

- (BOOL)vacuumDatabase {
    return [self.database executeUpdate:@"VACUUM"];
}

- (NSInteger)getDatabaseSize {
    NSString *sql = @"SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()";
    FMResultSet *resultSet = [self.database executeQuery:sql];
    
    NSInteger size = 0;
    if ([resultSet next]) {
        size = [resultSet longLongIntForColumn:@"size"];
    }
    [resultSet close];
    
    return size;
}

- (void)dealloc {
    [self.database close];
    [self.databaseQueue close];
}

@end