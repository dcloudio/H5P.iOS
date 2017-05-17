//
//  PGPingpp.m
//  HBuilder-PGPingpp
//
//  Created by afon on 15/3/6.
//  Copyright (c) 2015年 Pingplusplus. All rights reserved.
//

#import "PGPingpp.h"
#import "Pingpp.h"
#import "PDRCore.h"

static NSString * const PingppAPIChargeURLString = @"https://api.pingxx.com/v1/charges";

@implementation PGPingpp

@synthesize callBackID;
@synthesize chargeDict;

- (id)init {
    if ( self = [super init] ) {
        self.type = @"pingpp";
        self.description = @"Ping++";
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleOpenURL:)
                                                     name:PDRCoreOpenUrlNotification
                                                   object:nil];
    }
    return self;
}

- (void)request:(PGMethod *)command {
    
    NSString* cbID = [command.arguments objectAtIndex:2];
    NSString *arg1 = [command.arguments objectAtIndex:1];
    
    PDRPluginResult *result = nil;
    if (self.callBackID || self.chargeDict) {
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:PingppErrUnknownError];
        [self toCallback:cbID withReslut:[result toJSONString]];
        return;
    }
    
    if ([arg1 isKindOfClass:NSString.class]) {
        NSString *charge = arg1;
        NSString* scheme = [self getUrlScheme];
        self.callBackID = [cbID isKindOfClass:[NSString class]] ? cbID : nil;
        self.chargeDict = [NSJSONSerialization JSONObjectWithData:[charge dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        [Pingpp createPayment:charge appURLScheme:scheme withCompletion:^(NSString *result, PingppError *error) {
            [self handlePaymentResult:result error:error];
        }];
    }
}

- (void)handleOpenURL:(NSNotification*)notification {
    NSURL *url = [notification object];
    [Pingpp handleOpenURL:url withCompletion:^(NSString *result, PingppError *error) {
        [self handlePaymentResult:result error:error];
    }];
}

- (void)handlePaymentResult:(NSString *)result error:(PingppError *)error {
    if ([result isEqualToString:@"success"]) {
        NSString *tradeno = self.chargeDict && self.chargeDict[@"order_no"] ? self.chargeDict[@"order_no"] : @"";
        NSString *url = self.chargeDict && self.chargeDict[@"id"] ? [NSString stringWithFormat:@"%@/%@", PingppAPIChargeURLString, self.chargeDict[@"id"]] : @"";
        NSDictionary *dict = [NSDictionary
                              dictionaryWithObjectsAndKeys:self.type, @"channel",
                              tradeno, @"tradeno",
                              @"", @"description",
                              @"" , @"signature",
                              url, @"url", nil];
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
        [self toCallback:self.callBackID withReslut:[result toJSONString]];
    } else {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:error.code withMessage:[error getMsg]];
        [self toCallback:self.callBackID withReslut:[result toJSONString]];
    }
    self.callBackID = nil;
    self.chargeDict = nil;
}

- (NSString *)getUrlScheme {
    NSArray *urlSchemeList = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    if ([urlSchemeList count] == 0) {
        return nil;
    }
    NSDictionary *urlSchemeType = [urlSchemeList objectAtIndex:0];
    NSArray *schemes = [urlSchemeType objectForKey:@"CFBundleURLSchemes"];
    if ([schemes count] == 0) {
        return nil;
    }
    return [schemes objectAtIndex:0];
}

- (void)installService {
    // 安装微信
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/cn/app/wechat/id414478124?mt=8"]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PDRCoreOpenUrlNotification
                                                  object:nil];
    self.callBackID = nil;
    self.chargeDict = nil;
    [super dealloc];
}

@end
