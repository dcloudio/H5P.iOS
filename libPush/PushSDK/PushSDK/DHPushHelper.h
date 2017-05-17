//
//  DHPushHelper.h
//  PushSDK
//
//  Created by X on 14-4-3.
//  Copyright (c) 2014年 io.dcloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKeyPush.h"
#import "PGPush.h"

@interface DHPushHelper : MKeyPush {
}

@property (retain, nonatomic) NSString *serverUrl;
@property (retain, nonatomic) NSString *appID;

- (void)startEngineWithDelegate:(id)delgate;
- (void)stopEngine;
- (void)registerMkeyPushUseDeviceToken:(NSString *)deviceToken;
@end

@interface PGDHPush : PGPush {
    DHPushHelper *_dhPusher;
}
- (NSMutableDictionary*)getClientInfoJSObjcet;
- (void) onRegRemoteNotificationsError:(NSError *)error;
- (void) onRevDeviceToken:(NSString *)deviceToken;
- (void) onRevRemoteNotification:(NSDictionary *)userInfo;
- (void) onRevLocationNotification:(NSDictionary *)userInfo;
- (void) onAppEnterBackground;
- (void) onAppEnterForeground;
@end