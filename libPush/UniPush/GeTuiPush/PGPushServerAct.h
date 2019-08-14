//
//  GetuiPushServer.h
//  GeTuiPush
//
//  Created by DCloud on 16/7/20.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeTuiSdk.h"
#import "PGPush.h"

@interface PGPushServerAct:PGPushServer<GeTuiSdkDelegate>
@property (retain, nonatomic) NSString *appKey;
@property (retain, nonatomic) NSString *appSecret;
@property (retain, nonatomic) NSString *appID;
@property (retain, nonatomic) NSString *clientId;
@end

