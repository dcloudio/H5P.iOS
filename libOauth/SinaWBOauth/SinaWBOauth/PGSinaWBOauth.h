//
//  PGSinaWBOauth.h
//  PGSinaWBOauth
//
//  Created by X on 15/3/12.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGOauth.h"
#import "WeiboSDK.h"


@interface PGSinaWBOauth : PGOauth<WeiboSDKDelegate> {
}
@property(nonatomic, retain)NSString *redirectURI;
@property(nonatomic, retain)NSString *appId;
@property(nonatomic, retain)NSString *uid;
@property(nonatomic, retain)NSString *accessToken;
@property(nonatomic, assign)NSTimeInterval expireTime;
@property(nonatomic, retain)NSDictionary *userInfo;
@property(nonatomic, retain)NSString *extra;
@property(nonatomic, retain)NSString *callbackId;
@property(nonatomic, assign)BOOL isMeSend;
- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;
@end
