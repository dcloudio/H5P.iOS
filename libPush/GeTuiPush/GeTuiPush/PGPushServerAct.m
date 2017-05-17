//
//  GetuiPushServer.m
//  GeTuiPush
//
//  Created by DCloud on 16/7/20.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import "PGPushServerAct.h"
#import "PDRCommonString.h"
#import "PDRCorePrivate.h"

@implementation PGPushServerAct

@synthesize appKey;
@synthesize appSecret;
@synthesize appID;
@synthesize clientId;

+ (NSString*)identifier {
    return @"com.pushserver";
}

-(void)onCreate {
    [super onCreate];
    [self readSetup];
    [self startSdk];
    self.clientId = [GeTuiSdk clientId];
    if ([PDRCore Instance].deviceToken) {
        [self onRevDeviceToken:[PDRCore Instance].deviceToken];
    }
}

- (void) readSetup {
    NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"getui"];
    if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
        self.appKey = [dhDict objectForKey:@"appkey"];
        self.appSecret = [dhDict objectForKey:@"appsecret"];
        self.appID = [dhDict objectForKey:@"appid"];
    }
}

- (void) onRegRemoteNotificationsError:(NSError *)error {
    [GeTuiSdk registerDeviceToken:@""];
}

- (void) onRevDeviceToken:(NSString *)deviceToken {
    NSLog(@"GeTuiSdk--onRevDeviceToken[%@]", deviceToken);
    if ( deviceToken ) {
        [GeTuiSdk registerDeviceToken:deviceToken];
    } else {
        [GeTuiSdk registerDeviceToken:@""];
    }
}

- (void)startSdk
{
    [GeTuiSdk startSdkWithAppId:self.appID
                         appKey:self.appKey
                      appSecret:self.appSecret
                       delegate:self];
    [GeTuiSdk runBackgroundEnable:NO];
    //[1-3]:设置电子围栏功能，开启LBS定位服务 和 是否允许SDK 弹出用户定位请求
    [GeTuiSdk lbsLocationEnable:NO andUserVerify:NO];
}

#pragma mark - GexinSdkDelegate
- (void)GeTuiSdkDidRegisterClient:(NSString *)cId
{
    self.clientId = cId;
}

- (void)GeTuiSdkDidOccurError:(NSError *)error
{
    // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
    NSLog(@"\n>>>[GexinSdk error]:%@\n\n", [error localizedDescription]);
}

- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData
                            andTaskId:(NSString *)taskId
                             andMsgId:(NSString *)msgId
                           andOffLine:(BOOL)offLine
                          fromGtAppId:(NSString *)appId
{
    [_multiDelegate enumerateDelegateUsingBlock:^(id<GeTuiSdkDelegate> obj, NSUInteger idx, BOOL *stop) {
        if ( [obj respondsToSelector:@selector(GeTuiSdkDidReceivePayloadData:andTaskId:andMsgId:andOffLine:fromGtAppId:)] ) {
            [obj GeTuiSdkDidReceivePayloadData:payloadData andTaskId:msgId andMsgId:msgId andOffLine:offLine fromGtAppId:appId];
        }
    }];
}

- (void)dealloc {
    [GeTuiSdk destroy];
    self.appSecret = nil;
    self.appID = nil;
    self.appKey = nil;
    self.clientId = nil;
    [super dealloc];
}

@end
