//
//  MiPushService.h
//  HBuilder-Hello
//
//  Created by EICAPITAN on 16/11/17.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import "PGPush.h"
#import "MiPushSDK.h"
#import "H5MultiDelegate.h"

@interface PGPushServerAct:PGPushServer<MiPushSDKDelegate>
@property(retain, nonatomic)NSString* appKey;
@property(retain, nonatomic)NSString* appSecret;
@property(retain, nonatomic)NSString* appID;
@property(retain, nonatomic)NSString* clientId;
@end
