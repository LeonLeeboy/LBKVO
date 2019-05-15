//
//  ViewController.m
//  demo
//
//  Created by 李兵 on 2019/5/8.
//  Copyright © 2019 李兵. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+LBKVO.h"



@interface ViewController ()

/** tempt */
@property (nonatomic , copy) NSString * kekee;

@property (nonatomic , copy) void(^customBlock)(NSString *);

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
//    __weak typeof(self) weakSelf = self;
//    self.customBlock = ^(NSString *para){
//        NSLog(@"%lu",(unsigned long)weakSelf.idx);
//        NSLog(@"%@",para);
//    };
//    self.customBlock(@"how do you do");
   
//    [self addObserver:self forKeyPath:@"idx" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self LB_addObserver:self keyPath:@"kekee" changeBlock:^(id  _Nonnull observer, NSString * _Nonnull key, id  _Nonnull oldValue, id  _Nonnull newValue) {
         NSLog(@"sadf");
    }];
}

//-(void)viewWillAppear:(BOOL)animated{
//    [super viewWillAppear:animated];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChange) name:@"didChange" object:nil];
//}
//
//- (void)didChange {
//    NSLog(@"asdf");
//}
//
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    static CGFloat idx = 2;
    self.kekee = [NSString stringWithFormat:@"%f",idx++];
    
}
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
//    NSLog(@"asfd");
//}
//
-(void)dealloc{
    [self LB_removeObserver:self keyPath:@"tempt"];
}

@end
