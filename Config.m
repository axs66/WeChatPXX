//
//  Config.m
//  WeChat++
//
//  微信配置管理实现
//  有问题 联系pxx917144686
//

#import "Config.h"
#import "SessionInfo.h"

// Config - 分组配置管理类
@interface Config ()
@end

@implementation Config

static NSMutableDictionary *_configDict = nil;

+ (instancetype)sharedConfig {
    static Config *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)initialize {
    if (self == [Config class]) {
        _configDict = [[NSMutableDictionary alloc] init];
    }
}

+ (NSDictionary *)configDictionary {
    return _configDict;
}

+ (void)saveConfigDictionary:(NSDictionary *)config {
    [_configDict setDictionary:config];
}

+ (NSArray *)groupFilterList {
    NSArray *filterList = [_configDict objectForKey:@"groupFilterList"];
    if (!filterList) {
        // 默认分组列表
        filterList = @[@"工作", @"朋友", @"家人", @"同学"];
        [self setGroupFilterList:filterList];
    }
    return filterList;
}

+ (void)setGroupFilterList:(NSArray *)filterList {
    [_configDict setObject:filterList forKey:@"groupFilterList"];
    [self saveConfigDictionary:_configDict];
}

@end


// WeChatSessionMgr - 分组会话管理器
@interface WeChatSessionMgr ()
@end

@implementation WeChatSessionMgr

static WeChatSessionMgr *_sessionMgrInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sessionMgrInstance = [[self alloc] init];
    });
    return _sessionMgrInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.groupList = [NSMutableDictionary dictionary];
        [self setupDefaultGroups];
    }
    return self;
}

- (void)setupDefaultGroups {
    NSArray *filterList = [Config groupFilterList];
    if (!filterList || filterList.count == 0) {
        filterList = @[@"工作", @"朋友", @"家人", @"同学"];
    }
    
    for (NSString *groupName in filterList) {
        SessionInfo *sessionInfo = [[SessionInfo alloc] initWithGroupName:groupName];
        [self.groupList setObject:sessionInfo forKeyedSubscript:groupName];
    }
}

- (void)reloadSessions {
    // 重新加载会话数据
    [self setupDefaultGroups];
}

- (NSMutableDictionary *)groupList {
    if (!_groupList) {
        _groupList = [[NSMutableDictionary alloc] init];
    }
    return _groupList;
}

@end
