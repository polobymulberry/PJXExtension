//
//  ViewController.m
//  PJXExtension
//
//  Created by poloby on 16/3/26.
//  Copyright © 2016年 poloby. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+Extension.h"

#pragma mark - PJXUser
@interface PJXUser : NSObject

@property (nonatomic, copy) NSString* username; // 用户名
@property (nonatomic, copy) NSString* password; // 密码
@property (nonatomic, copy) NSString* avatarImageURL; // 头像的URL地址

@end

@implementation PJXUser

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // simple sample
    [self runSimpleSample];
}

#pragma mark - Simple Sample
- (void)runSimpleSample
{
    NSDictionary *userDict = @{@"username"      :@"shuaige",
                               @"password"      :@"123456",
                               @"avatarImageURL":@"http://www.example.com/shuaige.png"};
    
    PJXUser *user = [[PJXUser alloc] initWithAttributes:userDict];
    
    NSLog(@"username:%@\n",user.username);
    NSLog(@"password:%@\n",user.password);
    NSLog(@"avatarImageURL:%@\n",user.avatarImageURL);
}

@end
