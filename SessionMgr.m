//
//  SessionMgr.m
//  WeChat++
//
//  会话管理器实现
//  有问题 联系pxx917144686
//

#import "SessionMgr.h"
#import "SessionInfo.h"

@implementation WCPulseSessionMgr

static WCPulseSessionMgr *sharedMgr = nil;

+ (instancetype)shared {
    static WCPulseSessionMgr *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WCPulseSessionMgr alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sessions = [NSMutableDictionary dictionary];
        self.allSessions = @[];
    }
    return self;
}

- (void)startSessionWithId:(NSString *)sessionId {
    SessionInfo *sessionInfo = [[SessionInfo alloc] init];
    sessionInfo.sessionId = sessionId;
    sessionInfo.lastUpdateTime = [NSDate date];
    [self.sessions setObject:sessionInfo forKey:sessionId];
}

- (void)endSessionWithId:(NSString *)sessionId {
    SessionInfo *sessionInfo = [self.sessions objectForKey:sessionId];
    if (sessionInfo) {
        sessionInfo.lastUpdateTime = [NSDate date];
        // 保存会话信息，保存到数据库或文件
        [self.sessions removeObjectForKey:sessionId];
    }
}

- (void)setupDefaultGroups {
    // 设置默认群组
    NSMutableArray *defaultGroups = [NSMutableArray array];
    [defaultGroups addObject:@"全部"];
    [defaultGroups addObject:@"好友"];
    [defaultGroups addObject:@"群聊"];
    [defaultGroups addObject:@"公众号"];
    [defaultGroups addObject:@"企业微信"];
    self.groups = [defaultGroups copy];
}

- (NSArray *)groupList {
    if (!self.groups) {
        [self setupDefaultGroups];
    }
    return self.groups;
}

- (void)reloadSessions {
    // 重新加载会话列表
    self.lastReloadTime = [NSDate date];
    
    // 从微信会话管理器获取实际会话数据
    @try {
        Class ServiceCenterClass = NSClassFromString(@"MMServiceCenter");
        id serviceCenter = [ServiceCenterClass respondsToSelector:@selector(defaultCenter)] ? [ServiceCenterClass defaultCenter] : nil;

        id mainSessionMgr = nil;
        if (serviceCenter && [serviceCenter respondsToSelector:@selector(getService:)]) {
            Class MMNewSessionMgrClass = NSClassFromString(@"MMNewSessionMgr");
            if (MMNewSessionMgrClass) {
                mainSessionMgr = [serviceCenter performSelector:@selector(getService:) withObject:MMNewSessionMgrClass];
            }
            if (!mainSessionMgr) {
                Class MainSessionMgrClass = NSClassFromString(@"MainSessionMgr");
                if (MainSessionMgrClass) {
                    mainSessionMgr = [serviceCenter performSelector:@selector(getService:) withObject:MainSessionMgrClass];
                }
            }
        }

        // 尝试刷新会话列表
        if (mainSessionMgr && [mainSessionMgr respondsToSelector:@selector(reloadMainSessionList)]) {
            [mainSessionMgr performSelector:@selector(reloadMainSessionList)];
        }

        // 获取会话数组
        NSArray *sessionArray = @[];
        if (mainSessionMgr) {
            if ([mainSessionMgr respondsToSelector:@selector(m_arrSession)]) {
                id arr = [mainSessionMgr performSelector:@selector(m_arrSession)];
                if ([arr isKindOfClass:[NSArray class]]) {
                    sessionArray = (NSArray *)arr;
                }
            } else {
                // 尝试 KVC 兜底
                @try {
                    id arr = [mainSessionMgr valueForKey:@"m_arrSession"]; 
                    if ([arr isKindOfClass:[NSArray class]]) {
                        sessionArray = (NSArray *)arr;
                    }
                } @catch (__unused NSException *e) {}
            }
        }

        // 写入 allSessions，保留 sessions 字典用于插件内部追踪
        if ([sessionArray isKindOfClass:[NSArray class]]) {
            self.allSessions = sessionArray;
        } else {
            self.allSessions = @[];
        }
        
        // Sessions reloaded
    } @catch (NSException *exception) {
        // Failed to reload sessions
        // 保持空数组
        self.allSessions = @[];
    }
}
- (NSArray *)filterSessions:(NSArray *)sessions withGroupName:(NSString *)groupName needTop:(BOOL)needTop {
    if (!sessions || sessions.count == 0) {
        return @[];
    }
    
    NSMutableArray *filteredSessions = [NSMutableArray array];
    NSMutableArray *customGroupFilterArray = [NSMutableArray array];
    
    // 使用映射的群组名称以支持别名（如"公众号"/"服务号"）
    Class WCPulseConfigClass = NSClassFromString(@"WCPulseConfig");
    NSString *mappedGroupName = groupName;
    if (WCPulseConfigClass && [WCPulseConfigClass respondsToSelector:@selector(mappedGroupName:)]) {
        mappedGroupName = [WCPulseConfigClass performSelector:@selector(mappedGroupName:) withObject:groupName];
    }
    
    // 检查是否启用过滤重复联系人
    BOOL filterDuplicateContacts = NO;
    if (WCPulseConfigClass && [WCPulseConfigClass respondsToSelector:@selector(filterDuplicateContacts)]) {
        NSNumber *result = [WCPulseConfigClass performSelector:@selector(filterDuplicateContacts)];
        filterDuplicateContacts = [result boolValue];
    }
    
    if (filterDuplicateContacts) {
        // 获取自定义群组列表
        NSArray *customGroupList = nil;
        if (WCPulseConfigClass && [WCPulseConfigClass respondsToSelector:@selector(customGroupList)]) {
            customGroupList = [WCPulseConfigClass performSelector:@selector(customGroupList)];
        }
        if (customGroupList) {
            [customGroupFilterArray addObjectsFromArray:customGroupList];
        }
    }
    
    // 根据映射后的群组名称进行过滤
    if ([mappedGroupName isEqualToString:@"全部"]) {
        // 全部：过滤所有会话
        for (id session in sessions) {
            BOOL shouldAdd = YES;
            
            // 检查是否需要置顶过滤
            if ([session respondsToSelector:@selector(m_bIsTop)]) {
                NSNumber *result = [session performSelector:@selector(m_bIsTop)];
                BOOL isTop = [result boolValue];
                if (isTop != needTop) {
                    shouldAdd = NO;
                }
            }
            
            // 检查是否隐藏
            if (shouldAdd && [session respondsToSelector:@selector(isHidden)]) {
                NSNumber *result = [session performSelector:@selector(isHidden)];
                if ([result boolValue]) {
                    shouldAdd = NO;
                }
            }
            
            if (shouldAdd) {
                [filteredSessions addObject:session];
            }
        }
    } else if ([mappedGroupName isEqualToString:@"群聊"]) {
        // 群聊：包含@chatroom的会话
        for (id session in sessions) {
            BOOL shouldAdd = NO;
            
            if ([session respondsToSelector:@selector(m_nsUserName)]) {
                NSString *userName = [session performSelector:@selector(m_nsUserName)];
                if (userName) {
                    if ([userName hasSuffix:@"@chatroom"] || 
                        [userName isEqualToString:@"chatroom_session_box"]) {
                        shouldAdd = YES;
                    }
                }
            }
            
            if (shouldAdd) {
                // 检查置顶状态
                if ([session respondsToSelector:@selector(m_bIsTop)]) {
                    NSNumber *result = [session performSelector:@selector(m_bIsTop)];
                    BOOL isTop = [result boolValue];
                    if (isTop != needTop) {
                        shouldAdd = NO;
                    }
                }
                
                // 检查是否隐藏
                if (shouldAdd && [session respondsToSelector:@selector(isHidden)]) {
                    NSNumber *result = [session performSelector:@selector(isHidden)];
                    if ([result boolValue]) {
                        shouldAdd = NO;
                    }
                }
            }
            
            if (shouldAdd) {
                [filteredSessions addObject:session];
            }
        }
    } else if ([mappedGroupName isEqualToString:@"好友"]) {
        // 好友：聊天会话，但不包含群聊
        for (id session in sessions) {
            BOOL shouldAdd = NO;
            
            if ([self isChatSession:session]) {
                // 确保不是群聊
                if ([session respondsToSelector:@selector(m_nsUserName)]) {
                    NSString *userName = [session performSelector:@selector(m_nsUserName)];
                    if (userName && 
                        ![userName containsString:@"@chatroom"] && 
                        ![userName isEqualToString:@"chatroom_session_box"]) {
                        shouldAdd = YES;
                    }
                }
            }
            
            if (shouldAdd) {
                // 检查置顶状态
                if ([session respondsToSelector:@selector(m_bIsTop)]) {
                        NSNumber *result = [session performSelector:@selector(m_bIsTop)];
                        BOOL isTop = [result boolValue];
                        if (isTop != needTop) {
                            shouldAdd = NO;
                        }
                    }
                    
                    // 检查是否隐藏
                    if (shouldAdd && [session respondsToSelector:@selector(isHidden)]) {
                        NSNumber *result = [session performSelector:@selector(isHidden)];
                        if ([result boolValue]) {
                            shouldAdd = NO;
                        }
                    }
            }
            
            if (shouldAdd) {
                [filteredSessions addObject:session];
            }
        }
    } else if ([mappedGroupName isEqualToString:@"服务号"] || [mappedGroupName isEqualToString:@"公众号"]) {
        // 服务号：非聊天会话，不包含@chatroom、@openim、@ai.openim
        for (id session in sessions) {
            BOOL shouldAdd = NO;
            
            if (![self isChatSession:session]) {
                if ([session respondsToSelector:@selector(m_nsUserName)]) {
                        NSString *userName = [session performSelector:@selector(m_nsUserName)];
                    if (userName && 
                        ![userName containsString:@"@chatroom"] && 
                        ![userName containsString:@"@openim"] && 
                        ![userName containsString:@"@ai.openim"]) {
                        shouldAdd = YES;
                    }
                }
            }
            
            if (shouldAdd) {
                // 检查置顶状态
                if ([session respondsToSelector:@selector(m_bIsTop)]) {
                    NSNumber *result = [session performSelector:@selector(m_bIsTop)];
                    BOOL isTop = [result boolValue];
                    if (isTop != needTop) {
                        shouldAdd = NO;
                    }
                }
                
                // 检查是否隐藏
                if (shouldAdd && [session respondsToSelector:@selector(isHidden)]) {
                    NSNumber *result = [session performSelector:@selector(isHidden)];
                    if ([result boolValue]) {
                        shouldAdd = NO;
                    }
                }
            }
            
            if (shouldAdd) {
                [filteredSessions addObject:session];
            }
        }
    } else if ([mappedGroupName isEqualToString:@"企业号"] || [mappedGroupName isEqualToString:@"企业微信"]) {
        // 企业号：包含@openim或@ai.openim的会话
        for (id session in sessions) {
            id sessionInfo = session;
            
            // 如果传入的不是会话信息，尝试通过用户名获取会话信息
            if ([session isKindOfClass:[NSString class]]) {
                Class MMServiceCenterClass = NSClassFromString(@"MMServiceCenter");
                if (MMServiceCenterClass) {
                    id serviceCenter = [MMServiceCenterClass defaultCenter];
                    if ([serviceCenter respondsToSelector:@selector(getService:)]) {
                        Class MMNewSessionMgrClass = NSClassFromString(@"MMNewSessionMgr");
                        id sessionMgr = [serviceCenter performSelector:@selector(getService:) withObject:MMNewSessionMgrClass];
                        if ([sessionMgr respondsToSelector:@selector(genSessionInfoByUserName:)]) {
                            sessionInfo = [sessionMgr performSelector:@selector(genSessionInfoByUserName:) withObject:session];
                        }
                    }
                }
            }
            
            BOOL shouldAdd = NO;
            
            if ([sessionInfo respondsToSelector:@selector(m_nsUserName)]) {
                NSString *userName = [sessionInfo performSelector:@selector(m_nsUserName)];
                if (userName && 
                    ([userName hasSuffix:@"@openim"] || [userName hasSuffix:@"@ai.openim"])) {
                    shouldAdd = YES;
                }
            }
            
            if (shouldAdd) {
                // 检查置顶状态
                if ([sessionInfo respondsToSelector:@selector(m_bIsTop)]) {
                    NSNumber *result = [sessionInfo performSelector:@selector(m_bIsTop)];
                    BOOL isTop = [result boolValue];
                    if (isTop != needTop) {
                        shouldAdd = NO;
                    }
                }
                
                // 检查是否隐藏
                if (shouldAdd && [sessionInfo respondsToSelector:@selector(isHidden)]) {
                    NSNumber *result = [sessionInfo performSelector:@selector(isHidden)];
                    if ([result boolValue]) {
                        shouldAdd = NO;
                    }
                }
            }
            
            if (shouldAdd) {
                [filteredSessions addObject:sessionInfo];
            }
        }
    } else {
        // 自定义群组：使用ContactTagMgr进行过滤
        Class ContactTagMgrClass = NSClassFromString(@"ContactTagMgr");
        if (ContactTagMgrClass && [ContactTagMgrClass respondsToSelector:@selector(defaultInstance)]) {
            id tagMgr = [ContactTagMgrClass performSelector:@selector(defaultInstance)];
            if ([tagMgr respondsToSelector:@selector(_dicNameToId)]) {
                NSDictionary *dicNameToId = [tagMgr performSelector:@selector(_dicNameToId)];
                NSArray *allKeys = [dicNameToId allKeys];
                
                if ([tagMgr respondsToSelector:@selector(getDicWithUserNameForAllTag)]) {
                    NSDictionary *tagDictionary = [tagMgr performSelector:@selector(getDicWithUserNameForAllTag)];
                    NSArray *allValues = [tagDictionary allValues];
                    
                    NSUInteger groupIndex = [allKeys indexOfObject:mappedGroupName];
                    if (groupIndex != NSNotFound) {
                        NSArray *groupUserList = [allValues objectAtIndex:groupIndex];
                        
                        for (id session in sessions) {
                            BOOL shouldAdd = NO;
                            
                            if ([session respondsToSelector:@selector(m_nsUserName)]) {
                                NSString *userName = [session performSelector:@selector(m_nsUserName)];
                                if (userName && [groupUserList containsObject:userName] && 
                                    ![customGroupFilterArray containsObject:userName]) {
                                    
                                    // 检查置顶状态
                                    if ([session respondsToSelector:@selector(m_bIsTop)]) {
                                        NSNumber *result = [session performSelector:@selector(m_bIsTop)];
                                        BOOL isTop = [result boolValue];
                                        if (isTop == needTop) {
                                            shouldAdd = YES;
                                        }
                                    }
                                    
                                    // 检查是否隐藏
                                    if (shouldAdd && [session respondsToSelector:@selector(isHidden)]) {
                                        NSNumber *result = [session performSelector:@selector(isHidden)];
                                        if ([result boolValue]) {
                                            shouldAdd = NO;
                                        }
                                    }
                                }
                            }
                            
                            if (shouldAdd) {
                                [filteredSessions addObject:session];
                            }
                        }
                    }
                }
            }
        }
    }
    
    return [filteredSessions copy];
}

- (BOOL)isChatSession:(id)session {
    if (!session) {
        return NO;
    }
    
    // 首先检查会话是否响应isChatSession选择器
    if ([session respondsToSelector:@selector(isChatSession)]) {
        return [(NSNumber *)[session performSelector:@selector(isChatSession)] boolValue];
    }
    
    // 使用isSingleChatSession选择器进行替代检查
    if ([session respondsToSelector:@selector(isSingleChatSession)]) {
        return [(NSNumber *)[session performSelector:@selector(isSingleChatSession)] boolValue];
    }
    
    // 从会话获取联系人
    id contact = nil;
    if ([session respondsToSelector:@selector(m_contact)]) {
        contact = [session performSelector:@selector(m_contact)];
    }
    
    if (contact) {
        // 检查是否为微信单聊联系人
        if ([contact respondsToSelector:@selector(isWeixinSingleContact)]) {
            return [(NSNumber *)[contact performSelector:@selector(isWeixinSingleContact)] boolValue];
        }
    }
    
    // 如果没有可用的联系人，检查基于用户名的逻辑
    NSString *userName = nil;
    if ([session respondsToSelector:@selector(m_nsUserName)]) {
            userName = [session performSelector:@selector(m_nsUserName)];
    }
    
    if (!userName) {
        return NO;
    }
    
    // 使用MMKernelUtil检查是否为联系人
    Class MMKernelUtilClass = NSClassFromString(@"MMKernelUtil");
    if (MMKernelUtilClass && [MMKernelUtilClass respondsToSelector:@selector(IsBrandContact:)]) {
        if ([(NSNumber *)[MMKernelUtilClass performSelector:@selector(IsBrandContact:) withObject:userName] boolValue]) {
            return NO; // 联系人不是聊天会话
        }
    }
    
    // 使用PluginUtil检查是否为插件用户
    Class PluginUtilClass = NSClassFromString(@"PluginUtil");
    if (PluginUtilClass) {
        if ([PluginUtilClass respondsToSelector:@selector(isPluginUserName:)]) {
            if ([(NSNumber *)[PluginUtilClass performSelector:@selector(isPluginUserName:) withObject:userName] boolValue]) {
                return NO; // 插件用户不是聊天会话
            }
        }
        
        if ([PluginUtilClass respondsToSelector:@selector(isOfficialUserName:)]) {
            if ([(NSNumber *)[PluginUtilClass performSelector:@selector(isOfficialUserName:) withObject:userName] boolValue]) {
                // 公众号 - 检查用户名是否包含"brand"
                // 如果包含"brand"，则不是聊天会话
                // 否则是聊天会话
                return ![userName containsString:@"brand"];
            }
        }
    }
    
    // 默认:聊天界面
    return YES;
}

@end