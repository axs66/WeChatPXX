//
//  FloatingTagCell.m
//  WeChat
//
//  Created by Assistant on 2024/12/16.
//

#import "FloatingTagCell.h"
#import "MainLayoutManager.h"
#import <Foundation/Foundation.h>

@interface FloatingTagCell ()
@property (nonatomic, strong) id tapGesture;
@end

@implementation FloatingTagCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
        
        // 初始化默认状态
        self.capsuleStates = @[@"默认", @"状态1", @"状态2"];
        self.selectedIndex = 0;
        self.isVisible = NO;
        
        NSLog(@"[FloatingTagCell] 初始化完成");
    }
    return self;
}

- (void)setupUI {
    // 创建容器视图
    self.containerView = [[NSObject alloc] init];
    
    // 创建滚动视图
    self.scrollView = [[NSObject alloc] init];
    
    // 创建内容视图
    self.contentView = [[NSObject alloc] init];
    
    // 初始化胶囊视图数组
    self.capsuleViews = [[NSMutableArray alloc] init];
    
    // 添加点击手势
    self.tapGesture = [[NSObject alloc] init];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 设置容器视图框架
    // self.containerView.frame = self.bounds;
    
    // 设置滚动视图框架
    CGFloat margin = 10.0;
    // self.scrollView.frame = CGRectMake(margin, margin, 
    //                                   self.bounds.size.width - 2 * margin, 
    //                                   self.bounds.size.height - 2 * margin);
    
    // 设置内容视图框架
    // self.contentView.frame = CGRectMake(0, 0, 
    //                                    self.scrollView.contentSize.width, 
    //                                    self.scrollView.frame.size.height);
    
    // 刷新胶囊视图布局
    [self createCapsuleViews];
}

- (void)setupConstraints {
    // 禁用自动布局转换
    // self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    // self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    // self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (selectedIndex >= 0 && selectedIndex < self.capsuleStates.count) {
        _selectedIndex = selectedIndex;
        [self refreshAppearance];
        
        // 通知代理状态改变
        if ([self.delegate respondsToSelector:@selector(floatingTagCell:didChangeToState:)]) {
            NSString *currentState = self.capsuleStates[selectedIndex];
            NSDictionary *stateDict = @{@"title": currentState, @"index": @(selectedIndex)};
            [self.delegate floatingTagCell:self didChangeToState:stateDict];
        }
        
        if (animated) {
            [self performShowAnimation];
        }
    }
}

- (void)handleTap:(id)gesture {
    // 切换到下一个状态
    NSInteger nextIndex = (self.selectedIndex + 1) % self.capsuleStates.count;
    [self setSelectedIndex:nextIndex animated:YES];
    
    // 通知代理
    if ([self.delegate respondsToSelector:@selector(floatingTagCell:didSelectIndex:)]) {
        [self.delegate floatingTagCell:self didSelectIndex:nextIndex];
    }
    
    // 触觉反馈 (iOS 10.0+)
    // if (@available(iOS 10.0, *)) {
    //     UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    //     [feedback impactOccurred];
    // }
    
    // 记录用户交互
    NSLog(@"[FloatingTagCell] 用户点击胶囊按钮，切换到索引: %ld", (long)nextIndex);
}

- (void)show {
    self.isVisible = YES;
    // self.alpha = 0.0;
    self.hidden = NO;
    // self.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    // 添加弹性动画效果
    // [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
    //     self.alpha = 1.0;
    //     self.transform = CGAffineTransformIdentity;
    // } completion:^(BOOL finished) {
    //     // 添加轻微的脉冲效果
    //     [UIView animateWithDuration:0.2 animations:^{
    //         self.transform = CGAffineTransformMakeScale(1.05, 1.05);
    //     } completion:^(BOOL finished) {
    //         [UIView animateWithDuration:0.2 animations:^{
    //             self.transform = CGAffineTransformIdentity;
    //         }];
    //     }];
    //     
    //     NSLog(@"[FloatingTagCell] 胶囊按钮显示动画完成");
    // }];
    
    NSLog(@"[FloatingTagCell] 胶囊按钮显示完成");
}

- (void)hide {
    // [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
    //     self.alpha = 0.0;
    //     self.transform = CGAffineTransformMakeScale(0.8, 0.8);
    // } completion:^(BOOL finished) {
    //     self.isVisible = NO;
    //     self.hidden = YES;
    //     self.transform = CGAffineTransformIdentity; // 重置变换
    //     NSLog(@"[FloatingTagCell] 胶囊按钮隐藏动画完成");
    // }];
    
    self.isVisible = NO;
    self.hidden = YES;
    NSLog(@"[FloatingTagCell] 胶囊按钮隐藏完成");
}

- (void)refreshAppearance {
    [self createCapsuleViews];
    NSLog(@"[FloatingTagCell] 刷新外观，胶囊数量: %lu", (unsigned long)self.capsuleStates.count);
}

- (void)createCapsuleViews {
    // 清除现有胶囊视图
    for (id capsuleView in self.capsuleViews) {
        // [capsuleView removeFromSuperview];
    }
    [self.capsuleViews removeAllObjects];
    
    CGFloat capsuleWidth = 80.0;
    CGFloat capsuleHeight = 30.0;
    CGFloat spacing = 10.0;
    CGFloat totalWidth = 0;
    
    // 创建每个胶囊按钮
    for (NSInteger i = 0; i < self.capsuleStates.count; i++) {
        NSString *stateTitle = self.capsuleStates[i];
        
        id capsuleView = [[NSObject alloc] init];
        // capsuleView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
        // capsuleView.layer.cornerRadius = capsuleHeight / 2.0;
        // capsuleView.tag = i;
        
        // 添加标题标签
        id titleLabel = [[NSObject alloc] init];
        // titleLabel.text = stateTitle ?: [NSString stringWithFormat:@"胶囊%ld", (long)i];
        // titleLabel.textColor = [UIColor whiteColor];
        // titleLabel.font = [UIFont systemFontOfSize:12.0];
        // titleLabel.textAlignment = NSTextAlignmentCenter;
        // [capsuleView addSubview:titleLabel];
        
        // 设置框架
        CGFloat x = totalWidth;
        // capsuleView.frame = CGRectMake(x, 0, capsuleWidth, capsuleHeight);
        // titleLabel.frame = capsuleView.bounds;
        
        // 高亮选中状态
        if (i == self.selectedIndex) {
            // capsuleView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8];
        }
        
        // [self.contentView addSubview:capsuleView];
        [self.capsuleViews addObject:capsuleView];
        
        totalWidth += capsuleWidth + spacing;
    }
    
    // 更新滚动视图内容大小
    // self.scrollView.contentSize = CGSizeMake(totalWidth - spacing, capsuleHeight);
}

- (void)performShowAnimation {
    NSLog(@"[FloatingTagCell] 执行显示动画");
}

// Touch事件处理方法（注释掉避免编译错误）
// - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//     [super touchesBegan:touches withEvent:event];
// }
// 
// - (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//     [super touchesEnded:touches withEvent:event];
// }
// 
// - (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//     [super touchesCancelled:touches withEvent:event];
// }

@end