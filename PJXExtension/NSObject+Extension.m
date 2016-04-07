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

// Number类型
typedef NS_ENUM(NSUInteger, PJXEncodingType) {
    PJXEncodingTypeUnknown    = 0, ///< unknown
    PJXEncodingTypeBool       = 1, ///< bool
    PJXEncodingTypeInt8       = 2, ///< char / BOOL
    PJXEncodingTypeUInt8      = 3, ///< unsigned char
    PJXEncodingTypeInt16      = 4, ///< short
    PJXEncodingTypeUInt16     = 5, ///< unsigned short
    PJXEncodingTypeInt32      = 6, ///< int
    PJXEncodingTypeUInt32     = 7, ///< unsigned int
    PJXEncodingTypeInt64      = 8, ///< long long
    PJXEncodingTypeUInt64     = 9, ///< unsigned long long
    PJXEncodingTypeFloat      = 10, ///< float
    PJXEncodingTypeDouble     = 11, ///< double
    PJXEncodingTypeLongDouble = 12, ///< long double
};

// 根据objc_property_attribute_t可以获取到property的类型
// 参考YYModel
PJXEncodingType PJXGetEncodingType(const char *encodingType) {
    char *type = (char *)encodingType;
    if (!type) return PJXEncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return PJXEncodingTypeUnknown;
    
    switch (*type) {
        case 'B': return PJXEncodingTypeBool;
        case 'c': return PJXEncodingTypeInt8;
        case 'C': return PJXEncodingTypeUInt8;
        case 's': return PJXEncodingTypeInt16;
        case 'S': return PJXEncodingTypeUInt16;
        case 'i': return PJXEncodingTypeInt32;
        case 'I': return PJXEncodingTypeUInt32;
        case 'l': return PJXEncodingTypeInt32;
        case 'L': return PJXEncodingTypeUInt32;
        case 'q': return PJXEncodingTypeInt64;
        case 'Q': return PJXEncodingTypeUInt64;
        case 'f': return PJXEncodingTypeFloat;
        case 'd': return PJXEncodingTypeDouble;
        case 'D': return PJXEncodingTypeLongDouble;

        default: return PJXEncodingTypeUnknown;
    }
}

/**
 * @brief 存储Model中每个property的信息
 * @param property 是一个objc_property_t类型变量
 * @param name 表示该property的名称
 * @param setter 是一个SEL类型变量，表示该property的setter方法
 * @param type 是一个PJXEncodingType类型变量，为了存储该属性是哪种Number(int?double?BOOL?)
 */
@interface PJXPropertyInfo : NSObject
@property (nonatomic, assign) objc_property_t property;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) SEL setter;
@property (nonatomic, assign) PJXEncodingType type;
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
        
        BOOL isCustomSetter = NO;
        // 判断属性类型
        unsigned int attrCount;
        // 关于objc_property_attribute_t，这里有一篇文章介绍的很好
        // http://www.henishuo.com/runtime-property-ivar/
        objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
        for (unsigned int i = 0; i < attrCount; i++) {
            switch (attrs[i].name[0]) {
                case 'T': { // EncodingType
                    if (attrs[i].value) {
                        //NSLog(@"attrs[%d].value = %s", i, attrs[i].value);
                        // 可以根据value获取到property类型
                        _type = PJXGetEncodingType(attrs[i].value);
                    }
                    break;
                }
                case 'S': { // 自定义setter方法
                    if (attrs[i].value) {
                        isCustomSetter = YES;
                        _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                    }
                } break;
                default:
                    break;
            }
        }
        
        if (!isCustomSetter) {
            // 如果没有自定义setter方法，只考虑系统默认生成setter方法
            // 也就是说属性username的setter方法为setUsername:
            NSString *setter = [NSString stringWithFormat:@"%@%@", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]];
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", setter]);
        }
    }
    
    return self;
}

// 根据propertyInfo中存储的type判断其是否为Number
- (BOOL)isNumber
{
    switch (self.type) {
        case PJXEncodingTypeBool:
        case PJXEncodingTypeInt8:
        case PJXEncodingTypeUInt8:
        case PJXEncodingTypeInt16:
        case PJXEncodingTypeUInt16:
        case PJXEncodingTypeInt32:
        case PJXEncodingTypeUInt32:
        case PJXEncodingTypeInt64:
        case PJXEncodingTypeUInt64:
        case PJXEncodingTypeFloat:
        case PJXEncodingTypeDouble:
        case PJXEncodingTypeLongDouble:
            return YES;
        default:
            return NO;
            break;
    }
}

// 使用objc_msgSend调用modelSelf中该属性对应的setter方法
- (void)setNumberValue:(NSNumber *)number withModelSelf:(id)modelSelf
{
    switch (self.type) {
        case PJXEncodingTypeBool:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.boolValue);
            break;
        case PJXEncodingTypeInt8:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.charValue);
            break;
        case PJXEncodingTypeUInt8:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.unsignedCharValue);
            break;
        case PJXEncodingTypeInt16:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.shortValue);
            break;
        case PJXEncodingTypeUInt16:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.unsignedShortValue);
            break;
        case PJXEncodingTypeInt32:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.intValue);
            break;
        case PJXEncodingTypeUInt32:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(modelSelf, self.setter, number.unsignedIntValue);
            break;
        case PJXEncodingTypeInt64:
            ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)(modelSelf, self.setter, number.longLongValue);
            break;
        case PJXEncodingTypeUInt64:
            ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)(modelSelf, self.setter, number.unsignedLongLongValue);
            break;
        case PJXEncodingTypeFloat:
            ((void (*)(id, SEL, float))(void *) objc_msgSend)(modelSelf, self.setter, number.floatValue);
            break;
        case PJXEncodingTypeDouble:
            ((void (*)(id, SEL, double))(void *) objc_msgSend)(modelSelf, self.setter, number.doubleValue);
            break;
        case PJXEncodingTypeLongDouble:
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)(modelSelf, self.setter, number.doubleValue);
            break;
        default:
            break;
    }
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

- (instancetype)initWithJSONData:(id)json
{
    NSDictionary *dict = [self pjx_dictionaryWithJSON:json];
    return [self initWithAttributes:dict];
}

/**
 * @brief 将NSString和NSData格式的json数据转化为NSDictionary类型
 */
- (NSDictionary *)pjx_dictionaryWithJSON:(id)json
{
    if (!json) {
        return nil;
    }
    // 若是NSDictionary类型，直接返回
    if ([json isKindOfClass:[NSDictionary class]]) {
        return json;
    }
    
    NSDictionary *dict = nil;
    NSData *jsonData = nil;
    
    if ([json isKindOfClass:[NSString class]]) {
        // 如果是NSString，就先转化为NSData
        jsonData = [(NSString*)json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    
    if (jsonData && [jsonData isKindOfClass:[NSData class]]) {
        // 如果时NSData类型，使用NSJSONSerialization
        NSError *error = nil;
        dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error) {
            NSLog(@"pjx_dictionaryWithJSON error:%@", error);
            return nil;
        }
        if (![dict isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
    }
    
    return dict;
}

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
    if (!attributes) {
        return nil;
    }
    
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
    // 另外，此函数的参数中也没有保存每个property信息，也得靠context这个参数来传递
    // 所以PJXModelContext还需要存储PJXClassInfo对象信息
    PJXModelContext *modelContext = context;
    
    id modelSelf = (__bridge id)(modelContext->modelSelf);
    
    // 如果使用了JSONProtocol，并且自定义了propertyMapper，那么还需要将keyStr转化下
    if ([modelSelf conformsToProtocol:@protocol(JSONProtocol)] && [[modelSelf class] respondsToSelector:@selector(propertyMapper)]) {
        keyStr = [[[modelSelf class] propertyMapper] objectForKey:keyStr];
    }
    
    PJXClassInfo *classInfo = (__bridge PJXClassInfo *)(modelContext->modelClassInfo);
    PJXPropertyInfo *info = classInfo.propertyInfos[keyStr];
    
    // 如果该属性是Number，那么就用Number赋值方法给其赋值
    if ([info isNumber]) {
        [info setNumberValue:setValue withModelSelf:modelSelf];
    } else {
        ((void (*)(id, SEL, id))(void *) objc_msgSend)(modelSelf, info.setter, setValue);
    }
}

@end