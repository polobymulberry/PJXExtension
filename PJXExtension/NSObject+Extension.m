//
//  NSObject+Extension.m
//  PJXExtension
//
//  Created by poloby on 16/3/29.
//  Copyright © 2016年 poloby. All rights reserved.
//

#import "NSObject+Extension.h"
#import <objc/message.h>
#import <objc/runtime.h>

typedef struct {
    void *modelSelf;
    void *modelClassInfo;
}PJXModelContext;

/**
 * @brief 存储Model中每个property的信息
 * @param property 是一个objc_property_t类型变量
 * @param name 表示该property的名称
 * @param setter 是一个SEL类型变量，表示该property的setter方法
 */
@interface PJXPropertyInfo : NSObject
@property (nonatomic, assign) objc_property_t property;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) SEL setter;
@end

@implementation PJXPropertyInfo

- (instancetype)initWithPropertyInfo:(objc_property_t)property
{
    self = [self init];
    
    if (self) {
        // 以备不时之需
        _property = property;
        
        // 使用property_getName获取到该property的名称
        const char *name = property_getName(property);
        if (name) {
            _name = [NSString stringWithUTF8String:name];
        }
        
        // 目前不考虑自定义setter方法，只考虑系统默认生成setter方法
        // 也就是说属性username的setter方法为setUsername:
        NSString *setter = [NSString stringWithFormat:@"%@%@", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]];
        _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", setter]);
    }
    
    return self;
}

@end

/**
 * @brief 存储Model的Class信息，不过目前只存储Class的property信息
 * @param propertyInfos 是一个NSMutableDictionary类型的变量，key存储property的名称，value存储对应的PJXPropertyInfo对象
 */
@interface PJXClassInfo : NSObject
@property (nonatomic, strong) NSMutableDictionary *propertyInfos;
@end

@implementation PJXClassInfo

- (instancetype)initWithClassInfo:(Class)cls
{
    self = [self init];
    
    // 使用class_copyPropertyList获取到Class的所有property（objc_property_t类型）
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    
    _propertyInfos = [NSMutableDictionary dictionary];
    
    // 遍历properties数组
    // 根据对应的objc_property_t信息构建出PJXPropertyInfo对象，并给propertyInfos赋值
    if (properties) {
        for (unsigned int i = 0; i < propertyCount; i++) {
            PJXPropertyInfo *propertyInfo = [[PJXPropertyInfo alloc] initWithPropertyInfo:properties[i]];
            _propertyInfos[propertyInfo.name] = propertyInfo;
        }
        // 注意释放空间
        free(properties);
    }
    
    return self;
}

@end

@implementation NSObject (Extension)

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
    self = [self init];
    
    if (self) {
        // 初始化PJXClassInfo对象，并给modelContext赋值
        PJXModelContext modelContext = {0};
        modelContext.modelSelf = (__bridge void *)(self);
        PJXClassInfo *classInfo = [[PJXClassInfo alloc] initWithClassInfo:[self class]];
        modelContext.modelClassInfo = (__bridge void *)classInfo;
        
        // 应用该函数，将得到JSON->Model后的Model数据
        CFDictionaryApplyFunction((CFDictionaryRef)attributes, PropertyWithDictionaryFunction, &modelContext);
    }
    
    return self;
}

// 注意我传入的dictionary就是用户提供的JSON数据
// 比如此处传入的key==@"username",value==@"shuaige"
static void PropertyWithDictionaryFunction(const void *key, const void *value, void *context)
{
    // 先将key和value转化到Cocoa框架下
    NSString *keyStr    = (__bridge NSString *)(key);
    id setValue         = (__bridge id)(value);
    
    // modelSelf其实就是self，不过我这里用的是static函数，所以没有默认参数self
    // 此时我们需要借助context参数来获取到这个self
    // 所以我设计了一个PJXModelContext，用来存储self信息
    // 另外，此函数的参数中也没有保存每个propery信息，也得靠context这个参数来传递
    // 所以PJXModelContext还需要存储PJXClassInfo对象信息
    PJXModelContext *modelContext = context;
    
    id modelSelf = (__bridge id)(modelContext->modelSelf);
    
    PJXClassInfo *classInfo = (__bridge PJXClassInfo *)(modelContext->modelClassInfo);
    PJXPropertyInfo *info = classInfo.propertyInfos[keyStr];
    
    ((void (*)(id, SEL, id))(void *) objc_msgSend)(modelSelf, info.setter, setValue);
}

@end
