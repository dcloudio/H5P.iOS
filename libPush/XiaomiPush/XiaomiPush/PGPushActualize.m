//
//  PGMiPush.m
//  HBuilder-Hello
//
//  Created by EICAPITAN on 16/11/17.
//  Copyright © 2016年 DCloud. All rights reserved.
//
#import "PGPushServerAct.h"
#import "PGPushActualize.h"
#import "PDRCommonString.h"
#import "PDRCorePrivate.h"

@implementation PGPushActualize

- (void) onCreate{
    [super onCreate];
    PGPushServerAct *pushServer = [self getPushServer];
    if ( pushServer ) {
        [pushServer.multiDelegate addDelegate:self];
    }
}

- (PGPushServerAct*)getPushServer {
    return [[PDRCore Instance] getServerByIdentifier:[PGPushServerAct identifier]];
}


- (NSMutableDictionary*)getClientInfoJSObjcet {
    PGPushServerAct *pushServer = [self getPushServer];
    NSMutableDictionary *clientInfo = [super getClientInfoJSObjcet];
    [clientInfo setObject:@"mipush" forKey:g_pdr_string_id];
    [clientInfo setObject:pushServer.appID ? pushServer.appID : @"" forKey:g_pdr_string_appid];
    [clientInfo setObject:pushServer.appKey ? pushServer.appKey: @"" forKey:g_pdr_string_appkey];
    [clientInfo setObject:pushServer.clientId ? pushServer.clientId : @"" forKey:@"clientid"];
    return clientInfo;
}

- (NSString*)convertToJSONData:(id)infoDict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    NSString *jsonString = @"";
    if (! jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }else
    {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //去除掉首尾的空白字符和换行字符
    
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}

- (void)MiPushDidReceivePayloadData:(NSDictionary*)payloadData
{
    NSString *payloadMsg = nil;
    if (payloadData) {
        payloadMsg = [self convertToJSONData:payloadData];            
        [self onRevRemoteNotification:(id)payloadMsg isReceive:YES];
    }
}

- (void)dealloc {
    PGPushServerAct *pushServer = [self getPushServer];
    if ( pushServer ) {
        [pushServer.multiDelegate removeDelegate:self];
    }
    [super dealloc];
}
@end
