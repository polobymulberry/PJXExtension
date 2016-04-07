//
//  NSObject+Extension.h
//  PJXExtension
//
//  Created by poloby on 16/3/29.
//  Copyright © 2016年 poloby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Extension)

- (instancetype)initWithAttributes:(NSDictionary *)attributes;
- (instancetype)initWithJSONData:(id)json;

@end

@protocol JSONProtocol <NSObject>

@required
+ (NSDictionary *)propertyMapper;

@end
