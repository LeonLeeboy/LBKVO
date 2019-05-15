//
//  NSObject+LBKVO.m
//  demo
//
//  Created by 李兵 on 2019/5/13.
//  Copyright © 2019 李兵. All rights reserved.
//

#import "NSObject+LBKVO.h"
//#import <Foundation/NSObjCRuntime.h>
#include <objc/message.h>

@interface LBKVOInfo ()

- (instancetype)initWithObserver:(id)observer key:(NSString *)key changeBlock:(LBKVOBlock)changeBlock;

@end

@implementation LBKVOInfo

- (instancetype)initWithObserver:(id)observer key:(NSString *)key changeBlock:(LBKVOBlock)changeBlock{
    if (self = [super init]) {
        _key = key;
        _observer = observer;
        _changeBlock = changeBlock;
    }
    return self;
}

@end


static NSString * kLBKVOPrefix = @"kLBKVOPrefix";
static NSString * kLBKVOObserversKey = @"kLBKVOObserversKey";

static NSString * setterForGetter (NSObject *parameter){
    NSString *p = [NSString stringWithFormat:@"%@",parameter];
    NSString *firstCharacter = [[p substringToIndex:1] uppercaseString];
    NSString *remainingCharacters = [p substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:",firstCharacter,remainingCharacters];
}

static NSString *getterForSetter(NSString *parameter){
    NSString *result;
    
    NSRange r = [parameter rangeOfString:@"set"];
    result = [parameter substringFromIndex:r.location + r.length];
    
    NSString *firstCharacter = [result substringToIndex:1].lowercaseString;
    result = [result stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstCharacter];
    
    result = [result stringByReplacingCharactersInRange:[result rangeOfString:@":"] withString:@""];
    
    return result;
}

@implementation NSObject (LBKVO)

static Class LBKVO_Class(id self, SEL _cmd)
{
    Class clazz = object_getClass(self); // kvo_class
    Class superClazz = class_getSuperclass(clazz); // origin_class
    return superClazz; // origin_class
}

static void KVO_setterIMP(id self,SEL _cmd,id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
  
    id oldValue = [self valueForKey:getterName];
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *,SEL ,id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superClazz,_cmd,newValue);
    NSMutableArray<LBKVOInfo *> *observers = objc_getAssociatedObject(self, (__bridge const void *)kLBKVOObserversKey);
    [observers enumerateObjectsUsingBlock:^(LBKVOInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([(NSString *)obj.key isEqualToString:getterName]) {
            obj.changeBlock(self, getterName, oldValue, newValue);
        }
    }];

}

#pragma mark - core initialize
/** implementation   */
- (void)LB_addObserver:(NSObject *)observer keyPath:(NSString *)keyPath changeBlock:(LBKVOBlock)changeBlock{
    //1. 是否实现setter方法
    Method superSetMethod = [self p_checkIsImplementionSetterWithContext:self keypath:keyPath];
    if (!superSetMethod) {
        @throw [NSException exceptionWithName:@"does't find selector" reason:@"does't imp setter metthod" userInfo:nil];
    }
    //2. 判断这个类是否是自定义KVO类
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    //3. 没有就创建一个类并且让该对象的isa指向
    if (![clazzName hasPrefix:kLBKVOPrefix]) {
        clazz = [self createKVOClassWithClassName:clazzName];
        object_setClass(self, clazz);
    }
    //重写setter方法
    const char * types = method_getTypeEncoding(superSetMethod);
    class_addMethod(object_getClass(self), NSSelectorFromString(setterForGetter(keyPath)), (IMP)KVO_setterIMP, types);
    
    
    NSMutableArray *observers = objc_getAssociatedObject(self,(__bridge const void *) kLBKVOObserversKey);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *) kLBKVOObserversKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    LBKVOInfo *info = [[LBKVOInfo alloc] initWithObserver:observers key:keyPath changeBlock:changeBlock];
    [observers addObject:info];
}


#pragma mark - 检查是否有设置方法
- (Method)p_checkIsImplementionSetterWithContext:(NSObject *)context keypath:(NSObject *)keypath{
    //get method
    SEL selector = NSSelectorFromString(setterForGetter(keypath));
    Method setMethod = class_getInstanceMethod([self class], selector);
    return setMethod;
}

- (Class)createKVOClassWithClassName:(NSString *)className{
    NSString *kvoClazzName = [kLBKVOPrefix stringByAppendingString:className];
    Class KVOClazz = NSClassFromString(kvoClazzName);
    if (KVOClazz) {
        return KVOClazz;
    }
    //创建
    Class superClazz = object_getClass(self);
    Class KVOClazz1 = objc_allocateClassPair(superClazz, kvoClazzName.UTF8String, 0);
   
    //获得Types类型
    Method m = class_getInstanceMethod(superClazz, @selector(class));
    const char *types = method_getTypeEncoding(m);
    class_addMethod(KVOClazz1, @selector(class), (IMP)LBKVO_Class, types);

    objc_registerClassPair(KVOClazz1);
    return KVOClazz1;
}

#pragma mark - 析构
- (void)LB_removeObserver:(NSObject *)observer keyPath:(NSString *)keyPath{
    NSMutableArray<LBKVOInfo *> *observers = objc_getAssociatedObject(self, (__bridge const void *)kLBKVOObserversKey);
    if (!observers) {
        return;
    }
    for (LBKVOInfo *info in observers) {
        if ([info.key isEqualToString:keyPath]) {
            [observers removeObject:info];
        }
    }
    
}



@end

