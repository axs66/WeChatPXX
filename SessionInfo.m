//
//  SessionInfo.m
//  WeChat++
//
//  会话信息管理实现
//  有问题 联系pxx917144686
//

#import "SessionInfo.h"

@implementation SessionInfo

- (instancetype)initWithGroupName:(NSString *)groupName {
    self = [super init];
    if (self) {
        _groupName = [groupName copy];
        _contactList = [[NSMutableArray alloc] init];
        _messageCount = 0;
        _lastUpdateTime = [NSDate date];
    }
    return self;
}

- (void)addContact:(NSString *)contactId {
    if (contactId && ![self containsContact:contactId]) {
        NSMutableArray *mutableContacts = [self.contactList mutableCopy];
        [mutableContacts addObject:contactId];
        self.contactList = [mutableContacts copy];
        self.lastUpdateTime = [NSDate date];
    }
}

- (void)removeContact:(NSString *)contactId {
    if (contactId && [self containsContact:contactId]) {
        NSMutableArray *mutableContacts = [self.contactList mutableCopy];
        [mutableContacts removeObject:contactId];
        self.contactList = [mutableContacts copy];
        self.lastUpdateTime = [NSDate date];
    }
}

- (BOOL)containsContact:(NSString *)contactId {
    return contactId && [self.contactList containsObject:contactId];
}

@end