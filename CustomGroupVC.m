// WeChatCustomGroupVC - 自定义分组视图控制器
// 有问题 联系pxx917144686


#import "CustomGroupVC.h"


@interface CustomGroupVC ()

- (instancetype)initWithGroupName:(NSString *)groupName;
- (void)setupUI;
- (void)loadExistingGroupData;
- (void)showContactSelector;
- (void)cancelButtonTapped;
- (void)saveButtonTapped;
- (void)clearButtonTapped:(id)sender;
- (void)showAlert:(NSString *)title message:(NSString *)message;
@end

@implementation CustomGroupVC

- (instancetype)initWithGroupName:(NSString *)groupName {
    self = [super init];
    if (self) {
        self.groupName = [groupName copy];
        self.isEditMode = (groupName != nil);
        self.selectedContacts = [NSMutableArray array];
        self.selectedContactNames = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置标题
    self.title = self.isEditMode ? @"编辑自定义分组" : @"新建自定义分组";
    
    // 设置背景色
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    // 设置导航栏按钮
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonTapped)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonTapped)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // 如果是编辑模式，加载现有数据
    if (self.isEditMode) {
        [self loadExistingGroupData];
    }
    
    [self setupUI];
}

- (void)setupUI {
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 13.0, *)) {
        self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor whiteColor];
    }
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 注册cell类型
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"GroupNameCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MemberCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AddMemberCell"];
    
    [self.view addSubview:self.tableView];
}

- (void)loadExistingGroupData {
    // 从配置中加载现有分组数据
    // 这里可以根据实际需求实现数据加载逻辑
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // 分组名称 + 成员列表
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1; // 分组名称输入框
    } else {
        return self.selectedContacts.count + 1; // 已选成员 + 添加成员按钮
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"分组名称" : @"分组成员";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // 分组名称输入cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupNameCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (!self.groupNameField) {
            self.groupNameField = [[UITextField alloc] initWithFrame:CGRectMake(15, 0, cell.contentView.frame.size.width - 30, 44)];
            self.groupNameField.placeholder = @"请输入分组名称";
            self.groupNameField.delegate = self;
            self.groupNameField.text = self.groupName;
            self.groupNameField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [cell.contentView addSubview:self.groupNameField];
        }
        
        return cell;
    } else {
        // 成员列表cell
        if (indexPath.row < self.selectedContacts.count) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberCell" forIndexPath:indexPath];
            cell.textLabel.text = self.selectedContactNames[indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            return cell;
        } else {
            // 添加成员cell
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddMemberCell" forIndexPath:indexPath];
            cell.textLabel.text = @"添加成员";
            cell.textLabel.textColor = [UIColor systemBlueColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    }
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == self.selectedContacts.count) {
        // 点击添加成员
        [self showContactSelector];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row < self.selectedContacts.count) {
        // 删除成员
        [self.selectedContacts removeObjectAtIndex:indexPath.row];
        [self.selectedContactNames removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (void)showContactSelector {
    // 显示联系人选择器
    // 这里可以集成微信的联系人选择界面
    [self showAlert:@"提示" message:@"联系人选择功能待实现"];
}

- (void)cancelButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveButtonTapped {
    NSString *groupName = self.groupNameField.text.length > 0 ? self.groupNameField.text : nil;
    
    if (!groupName || groupName.length == 0) {
        [self showAlert:@"错误" message:@"请输入分组名称"];
        return;
    }
    
    if (self.selectedContacts.count == 0) {
        [self showAlert:@"错误" message:@"请至少添加一个成员"];
        return;
    }
    
    // 保存分组数据
    if (self.saveCompletionBlock) {
        self.saveCompletionBlock(groupName, [self.selectedContacts copy]);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clearButtonTapped:(id)sender {
    [self.selectedContacts removeAllObjects];
    [self.selectedContactNames removeAllObjects];
    [self.tableView reloadData];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end