//
//  CustomGroupVC.h
//  WeChat++
//
//  自定义分组视图控制器头文件
//  有问题 联系pxx917144686
//

#import <UIKit/UIKit.h>

@interface CustomGroupVC : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, strong) UITextField *groupNameField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (nonatomic, strong) NSMutableArray *selectedContactNames;
@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, copy) void(^saveCompletionBlock)(NSString *groupName, NSArray *contacts);

/**
 * 初始化方法
 * @param groupName 分组名称，nil表示新建模式
 */
- (instancetype)initWithGroupName:(NSString *)groupName;

/**
 * 设置用户界面
 */
- (void)setupUI;

/**
 * 加载现有分组数据
 */
- (void)loadExistingGroupData;

/**
 * 显示联系人选择器
 */
- (void)showContactSelector;

/**
 * 取消按钮点击事件
 */
- (void)cancelButtonTapped;

/**
 * 保存按钮点击事件
 */
- (void)saveButtonTapped;

/**
 * 清除按钮点击事件
 */
- (void)clearButtonTapped:(id)sender;

/**
 * 显示提示框
 * @param title 标题
 * @param message 消息内容
 */
- (void)showAlert:(NSString *)title message:(NSString *)message;

@end