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

// 遵循JSONProtocol协议，这个JSONProtocol中定义的就是我的propertyMapper协议函数
@interface PJXUserPropertyMapper : NSObject <JSONProtocol>

@property (nonatomic, copy) NSString* username; // 用户名
@property (nonatomic, copy) NSString* password; // 密码
@property (nonatomic, copy) NSString* avatarImageURL; // 头像的URL地址

@end

@implementation PJXUserPropertyMapper
// 实现propertyMapper这个协议方法
+ (NSDictionary *)propertyMapper
{
    return @{@"Username" : @"username",
             @"Password" : @"password",
             @"AvatarImageURL" : @"avatarImageURL"};
}

@end

@interface PJXUserVariousType : NSObject

@property (nonatomic, copy) NSString *blogTitle; // 博客标题
@property (nonatomic, strong) NSURL *blogURL; // 博客网址
@property (nonatomic, assign) NSInteger blogIndex; // 博客索引值
@property (nonatomic, strong) NSDate *postDate; // 博客发布时间
@property (nonatomic, strong) NSArray *friends; // 我的好友名称
@property (nonatomic, strong) NSSet *collections; // 我的收藏
@property (nonatomic, assign) BOOL isDeveloper; // 是否是开发者

@end

@implementation PJXUserVariousType

@end

@interface PJXUserCustomSetter : NSObject

@property (nonatomic, copy, setter=setCustomUserName:) NSString* username; // 用户名
@property (nonatomic, copy, setter=setCustomBirthday:) NSDate* birthday; // 生日

@end

@implementation PJXUserCustomSetter

- (void)setCustomUserName:(NSString *)username
{
    _username = [NSString stringWithFormat:@"My name is %@", username];
}

- (void)setCustomBirthday:(NSDate *)birthday
{
    NSTimeInterval timeInterval = 24*60*60; // 过一天
    _birthday = [NSDate dateWithTimeInterval:timeInterval sinceDate:birthday];
}

@end

@interface PJXBlog : NSObject

@property (nonatomic, copy) NSString *title; // 博客名称
@property (nonatomic, strong) NSDate *postDate; // 博客发表日期
@property (nonatomic, copy) PJXUser *author; // 博客作者

@end

@implementation PJXBlog

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // simple sample
    [self runSimpleSample1];
    [self runSimpleSample2];
    [self runSimpleSample3];
    [self runPropertyMapperSample];
    [self runVariousTypeSample];
    [self runCustomSetterSample];
    [self runNestSample];
}

#pragma mark - Simple Sample
// NSDictionary类型的JSON数据
- (void)runSimpleSample1
{
    NSDictionary *userDict = @{@"username"      :@"shuaige",
                               @"password"      :@"123456",
                               @"avatarImageURL":@"http://www.example.com/shuaige.png"};
    
    PJXUser *user = [[PJXUser alloc] initWithAttributes:userDict];
    
    NSLog(@"runSimpleSample1\n");
    NSLog(@"----------------------------------------");
    NSLog(@"username:%@\n",user.username);
    NSLog(@"password:%@\n",user.password);
    NSLog(@"avatarImageURL:%@\n",user.avatarImageURL);
}

// NSString类型的JSON数据
- (void)runSimpleSample2
{
    NSString *userStr = @"                                                              \
                        {                                                               \
                            \"username\"       : \"shuaige\",                           \
                            \"password\"       : \"123456\",                            \
                            \"avatarImageURL\" : \"http://www.example.com/shuaige.png\" \
                        }";
    
    PJXUser *user = [[PJXUser alloc] initWithJSONData:userStr];
    
    NSLog(@"runSimpleSample2\n");
    NSLog(@"----------------------------------------");
    NSLog(@"username:%@\n",user.username);
    NSLog(@"password:%@\n",user.password);
    NSLog(@"avatarImageURL:%@\n",user.avatarImageURL);
}

// NSData类型的JSON数据
- (void)runSimpleSample3
{
    NSString *userInfoFilePath = [[NSBundle mainBundle] pathForResource:@"UserInfo" ofType:@"txt"];
    NSData *data = [NSData dataWithContentsOfFile:userInfoFilePath];
    PJXUser *user = [[PJXUser alloc] initWithJSONData:data];
    
    NSLog(@"runSimpleSample3\n");
    NSLog(@"----------------------------------------");
    NSLog(@"username:%@\n",user.username);
    NSLog(@"password:%@\n",user.password);
    NSLog(@"avatarImageURL:%@\n",user.avatarImageURL);
}

#pragma mark - PropertyMapper Sample
- (void)runPropertyMapperSample
{
    NSDictionary *userDict = @{@"Username" : @"shuaige",
                               @"Password" : @"123456",
                               @"AvatarImageURL" : @"http://www.example.com/shuaige.png"};
    PJXUserPropertyMapper *user = [[PJXUserPropertyMapper alloc] initWithJSONData:userDict];
    
    NSLog(@"runPropertyMapperSample\n");
    NSLog(@"----------------------------------------");
    NSLog(@"username:%@\n",user.username);
    NSLog(@"password:%@\n",user.password);
    NSLog(@"avatarImageURL:%@\n",user.avatarImageURL);
}

#pragma mark - VariousType Sample
- (void)runVariousTypeSample
{
    NSDictionary *userDict = @{@"blogTitle" : @"iOS developer",
                               @"blogURL" : @"http://www.example.com/blog.html",
                               @"blogIndex" : @666,
                               @"postDate" : [NSDate date],
                               @"friends" : @[@"meinv1", @"meinv2", @"meinv3"],
                               @"collections" : @[@"shuaige1", @"shuaige2", @"shuaige3"],
                               @"isDeveloper" : @YES};
    PJXUserVariousType *user = [[PJXUserVariousType alloc] initWithJSONData:userDict];
    
    NSLog(@"runVariousTypeSample\n");
    NSLog(@"----------------------------------------");
    NSLog(@"blogTitle:%@\n",user.blogTitle);
    NSLog(@"blogURL:%@\n",user.blogURL);
    NSLog(@"blogIndex:%ld\n",user.blogIndex);
    NSLog(@"postDate:%@\n",user.postDate);
    NSLog(@"friends:%@\n",user.friends);
    NSLog(@"collections:%@\n",user.collections);
    NSLog(@"isDeveloper:%@\n",user.isDeveloper ? @"YES" : @"NO");
}

#pragma mark - Custom Setter Sample
- (void)runCustomSetterSample
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *birthday = [dateFormatter dateFromString:@"2016-04-07 00:20:03"];
    NSDictionary *userDict = @{@"username" : @"shuaige",
                               @"birthday" : birthday};
    PJXUserCustomSetter *user = [[PJXUserCustomSetter alloc] initWithJSONData:userDict];
    
    NSLog(@"runCustomSetterSample\n");
    NSLog(@"----------------------------------------");
    NSLog(@"username:%@\n",user.username);
    NSLog(@"birthday:%@\n",user.birthday);
}

#pragma mark - Nest Sample
- (void)runNestSample
{
    NSDictionary *blogDict = @{@"title" : @"how to convert JSON to Model?",
                               @"postDate" : [NSDate date],
                               @"author" : @{@"username" : @"shuaige",
                                             @"password" : @"123456",
                                             @"avatarImageURL":@"http://www.example.com/shuaige.png"}};
    PJXBlog *blog = [[PJXBlog alloc] initWithJSONData:blogDict];
    
    NSLog(@"runNestSample\n");
    NSLog(@"----------------------------------------");
    NSLog(@"title:%@\n",blog.title);
    NSLog(@"postDate:%@\n",blog.postDate);
    NSLog(@"author:%@\n",blog.author);
}

@end
