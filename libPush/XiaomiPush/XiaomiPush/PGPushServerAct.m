//
//  MiPushService.m
//  HBuilder-Hello
//
//  Created by EICAPITAN on 16/11/17.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import "PGPushServerAct.h"
#import "PDRCommonString.h"
#import "PDRCorePrivate.h"




extern NSData* Global_TokeData;



@implementation PGPushServerAct

@synthesize appKey;
@synthesize appSecret;
@synthesize appID;
@synthesize clientId;

+ (NSString*)identifier
{
    return @"com.pushserver";
}

- (void)onCreate
{
    [super onCreate];
    [self readSetup];
    [MiPushSDK registerMiPush:self type:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeNewsstandContentAvailability connect:YES];
}

- (void) readSetup {
    NSDictionary *dhDict = [[NSBundle mainBundle] infoDictionary];
    if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
        self.appKey = [dhDict objectForKey:@"MiSDKAppKey"];
        self.appSecret = @"";
        self.appID = [dhDict objectForKey:@"MiSDKAppID"];
    }
}

#pragma mark ApplicationDelegateMessage

- (void) onRegRemoteNotificationsError:(NSError *)error {
}


- (void) onRevDeviceToken:(NSString *)deviceToken {
    [MiPushSDK bindDeviceToken:[self convertHexStrToData:deviceToken]];
}

// 当同时启动APNs与内部长连接时, 把两处收到的消息合并. 通过miPushReceiveNotification返回
- (void) onRevRemoteNotification:(NSDictionary *)userInfo
{
    [MiPushSDK handleReceiveRemoteNotification:userInfo];
}



#pragma mark MiPushSDKDelegate
- (void)miPushRequestSuccWithSelector:(NSString *)selector data:(NSDictionary *)data
{
    if ([selector isEqualToString:@"bindDeviceToken:"]) {
        self.clientId = [[NSString alloc] initWithString:data[@"regid"]];
        self.appSecret = [[NSString alloc] initWithString:data[@"regsecret"]];
    }
}

//- (void)miPushReceiveNotification:(NSDictionary*)data
//{
//    [multiDelegate enumerateDelegateUsingBlock:^(id<MiPushSDKDelegate> obj, NSUInteger idx, BOOL *stop) {
//        if ( [obj respondsToSelector:@selector(MiPushDidReceivePayloadData:)] ) {
//            [obj MiPushDidReceivePayloadData:data];
//        }
//    }];
//}

- (NSString*)getOperateType:(NSString*)selector
{
    NSString *ret = nil;
    if ([selector hasPrefix:@"registerMiPush:"] ) {
        ret = @"客户端注册设备";
    }else if ([selector isEqualToString:@"unregisterMiPush"]) {
        ret = @"客户端设备注销";
    }else if ([selector isEqualToString:@"registerApp"]) {
        ret = @"注册App";
    }else if ([selector isEqualToString:@"bindDeviceToken:"]) {
        ret = @"绑定 PushDeviceToken";
    }else if ([selector isEqualToString:@"setAlias:"]) {
        ret = @"客户端设置别名";
    }else if ([selector isEqualToString:@"unsetAlias:"]) {
        ret = @"客户端取消别名";
    }else if ([selector isEqualToString:@"subscribe:"]) {
        ret = @"客户端设置主题";
    }else if ([selector isEqualToString:@"unsubscribe:"]) {
        ret = @"客户端取消主题";
    }else if ([selector isEqualToString:@"setAccount:"]) {
        ret = @"客户端设置账号";
    }else if ([selector isEqualToString:@"unsetAccount:"]) {
        ret = @"客户端取消账号";
    }else if ([selector isEqualToString:@"openAppNotify:"]) {
        ret = @"统计客户端";
    }else if ([selector isEqualToString:@"getAllAliasAsync"]) {
        ret = @"获取Alias设置信息";
    }else if ([selector isEqualToString:@"getAllTopicAsync"]) {
        ret = @"获取Topic设置信息";
    }
    return ret;
}

- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    return hexData;
}


-(void)dealloc
{
    PGPushServerAct *pushServer = [self getPushServer];
    if ( pushServer ) {
        [pushServer.multiDelegate removeDelegate:self];
    }
    self.clientId = nil;
    self.appSecret = nil;
    self.appKey = nil;
    self.clientId = nil;
    [super dealloc];
}

@end
