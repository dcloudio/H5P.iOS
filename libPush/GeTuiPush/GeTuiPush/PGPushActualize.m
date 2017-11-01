//
//  GeTuiPush.m
//  GeTuiPush
//
//  Created by X on 14-4-3.
//  Copyright (c) 2014年 io.dcloud. All rights reserved.
//

#import "PGPushActualize.h"
#import "PDRCommonString.h"
#import "PDRCorePrivate.h"
#import <Foundation/Foundation.h>
#import "PGPushServerAct.h"

@implementation PGPushActualize

- (void) onCreate{
    [super onCreate];
    
    __block typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        PGPushServerAct *pushServer = [weakSelf getPushServer];
        if ( pushServer ) {
            [pushServer.multiDelegate addDelegate:weakSelf];
        }
    });
}

- (PGPushServerAct*)getPushServer {
    return [[PDRCore Instance] getServerByIdentifier:[PGPushServerAct identifier]];
}

//- (void) onAppStarted:(NSDictionary*)options {
//    [super onAppStarted:options];
//    
//    _pushServer = [[PDRCore Instance] getServerByIdentifier:[GetuiPushServer identifier]];
//    if ( _pushServer ) {
//        [_pushServer.multiDelegate addDelegate:self];
//    }
//}

- (NSMutableDictionary*)getClientInfoJSObjcet {
    PGPushServerAct *pushServer = [self getPushServer];
    NSMutableDictionary *clientInfo = [super getClientInfoJSObjcet];
    [clientInfo setObject:pushServer.appID ? pushServer.appID : @"" forKey:g_pdr_string_appid];
    [clientInfo setObject:pushServer.appKey ? pushServer.appKey: @"" forKey:g_pdr_string_appkey];
    [clientInfo setObject:pushServer.clientId ? pushServer.clientId : @"" forKey:@"clientid"];
    [clientInfo setObject:@"igexin" forKey:g_pdr_string_id];
    return clientInfo;
}

- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData
                            andTaskId:(NSString *)taskId
                             andMsgId:(NSString *)msgId
                           andOffLine:(BOOL)offLine
                          fromGtAppId:(NSString *)appId
{
//    if ( !offLine
//        || (offLine && self.handleOfflineMsg) ) {
//        NSData *payload = [GeTuiSdk retrivePayloadById:payloadId];
    if ( !offLine ) {
        NSString *payloadMsg = nil;
        if (payloadData) {
            payloadMsg = [[[NSString alloc] initWithBytes:payloadData.bytes
                                                   length:payloadData.length
                                                 encoding:NSUTF8StringEncoding] autorelease];
            
            //  NSMutableDictionary* dict = [NSMutableDictionary dictionary];
            //  NSMutableDictionary *userInfo = [payloadMsg objectFromJSONString];
            // if ( ![userInfo isKindOfClass:[NSDictionary class]] ) {
            // userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:payloadMsg, g_pdr_string_payload, nil];
            // } else {
            // userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:userInfo, @"payload", nil];
            // }
            //[dict setObject:userInfo forKey:g_pdr_string_aps];
            //[dict setObject:g_pdr_string_receive forKey:g_pdr_string_type];
            [self onRevRemoteNotification:(id)payloadMsg isReceive:YES];
            
            //  [[PDRCore Instance] handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:payloadMsg];
        }
    }
  //  }
}

- (void)dealloc {
    PGPushServerAct *pushServer = [self getPushServer];
    if ( pushServer ) {
        [pushServer.multiDelegate removeDelegate:self];
    }
    [super dealloc];
}
@end
