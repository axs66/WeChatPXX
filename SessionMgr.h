//
//  SessionMgr.h
//  WeChat++
//
//  会话管理器头文件
//  有问题 联系pxx917144686
//

#import <Foundation/Foundation.h>

@interface WCPulseSessionMgr : NSObject

@property (nonatomic, strong) NSMutableDictionary *sessions; // 插件内部的会话跟踪（按sessionId）
@property (nonatomic, strong) NSArray *allSessions; // 从微信获取的主会话列表（只读使用）
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSString *currentSelectGroup;
@property (nonatomic, strong) NSDate *lastReloadTime;

+ (instancetype)shared;
- (void)setupDefaultGroups;
- (NSArray *)groupList;
- (void)reloadSessions;
- (NSArray *)filterSessions:(NSArray *)sessions withGroupName:(NSString *)groupName needTop:(BOOL)needTop;
- (BOOL)isChatSession:(id)session;
- (void)startSessionWithId:(NSString *)sessionId;
- (void)endSessionWithId:(NSString *)sessionId;

@end