//
//  GeTuiPush.m
//  GeTuiPush
//
//  Created by X on 14-4-3.
//  Copyright (c) 2014年 io.dcloud. All rights reserved.
//

#import "DHPushHelper.h"
#import <UIKit/UIKit.h>
#import "PDRCommonString.h"

@implementation PGDHPush

- (void) onAppStarted:(NSDictionary*)options {
    [super onAppStarted:options];
    _dhPusher = [[DHPushHelper alloc] init];
    [_dhPusher startEngineWithDelegate:self];
}

- (void) onRegRemoteNotificationsError:(NSError *)error {
}

- (void) onRevDeviceToken:(NSString *)deviceToken {
    [_dhPusher registerMkeyPushUseDeviceToken:deviceToken];
}

- (void) onRevRemoteNotification:(NSDictionary *)userInfo {
    [_dhPusher handleRemoteNotification:userInfo];
}

- (void) onRevLocationNotification:(NSDictionary *)userInfo {
}

- (void) onAppEnterBackground {
}

- (void) onAppEnterForeground {
}

- (NSMutableDictionary*)getClientInfoJSObjcet {
    NSMutableDictionary *clientInfo = [super getClientInfoJSObjcet];
    NSString *appID = nil, *appKey = nil, *clientId = nil;
    if ( _dhPusher ) {
        appID = _dhPusher.appID;
    }
    [clientInfo setObject:@"mkeypush" forKey:g_pdr_string_id];
    [clientInfo setObject:appID ? appID : @"" forKey:g_pdr_string_appid];
    [clientInfo setObject:appKey ? appKey: @"" forKey:g_pdr_string_appkey];
    [clientInfo setObject:clientId ? clientId : @"" forKey:@"clientid"];
    [clientInfo setObject:@"mkeypush" forKey:g_pdr_string_id];
    return clientInfo;
}

//收到消息()
- (void)didReceiveMessage:(NSDictionary*)message {
   // NSMutableDictionary* pDictionary = [self packageApns:message receive:!bIsDeactivate];
  //  [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:pDictionary];
}

//收到炸弹短息消息
- (void)didReceiveBombMessage {
    
}
/*
 //过程中出现错误
 - (void)didReceiveFailWithError:(NSError*)error {
 }
 */

@end


@implementation DHPushHelper

//@synthesize appKey;
@synthesize serverUrl;
@synthesize appID;

- (id)init {
    if ( self = [super init] ) {
        NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"dhpush"];
        if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
            self.appID = [dhDict objectForKey:@"appid"];
            self.serverUrl = [dhDict objectForKey:@"url"];
          //  self.appKey = [dhDict objectForKey:@"appkey"];
            //self.appSecret = [dhDict objectForKey:@"appsecret"];
           // self.appID = [dhDict objectForKey:@"appid"];
        }
    }
    return self;
}

- (void)startEngineWithDelegate:(id)delgate {
    NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"dhpush"];
    if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
        self.appID = [dhDict objectForKey:@"appid"];
        if ( appID ) {
            [self setDelegate:delgate];
            [self initMkeyPushWithAppID:appID option:nil];
        }
    }
}

- (void)registerMkeyPushUseDeviceToken:(NSString *)deviceToken{
    if ( self.serverUrl ) {
        [self registerMkeyPushUseDeviceToken:deviceToken toServer:self.serverUrl];
    }
}

- (void)stopEngine {

}
@end
