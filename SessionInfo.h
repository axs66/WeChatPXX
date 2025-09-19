//
//  SessionInfo.h
//  WeChat++
//
//  会话信息管理头文件
//  有问题 联系pxx917144686
//

#import <Foundation/Foundation.h>

@interface SessionInfo : NSObject

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, strong) NSArray *contactList;
@property (nonatomic, assign) NSInteger messageCount;
@property (nonatomic, strong) NSDate *lastUpdateTime;

- (instancetype)initWithGroupName:(NSString *)groupName;
- (void)addContact:(NSString *)contactId;
- (void)removeContact:(NSString *)contactId;
- (BOOL)containsContact:(NSString *)contactId;

@end