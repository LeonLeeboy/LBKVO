//
//  NSObject+LBKVO.h
//  demo
//
//  Created by 李兵 on 2019/5/13.
//  Copyright © 2019 李兵. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LBKVOBlock)(id observer, NSString *key, id oldValue, id newValue);

@interface LBKVOInfo : NSObject

@property (nonatomic, weak) id observer;

@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) LBKVOBlock changeBlock;

@end

@interface NSObject (LBKVO)
//接口设计 ，需要什么属性呢？ 观察者，被观察者的属性，对应条件下发生的改变的回调。
- (void)LB_addObserver:(NSObject *)observer keyPath:(NSString *)keyPath changeBlock:(LBKVOBlock)changeBlock;

- (void)LB_removeObserver:(NSObject *)observer keyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
