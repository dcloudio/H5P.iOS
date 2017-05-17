//
//  QQAuth.h
//  QQAuth
//
//  Created by X on 15/3/12.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "PGOauth.h"

@interface PGQQOauth : PGOauth<TencentSessionDelegate> {
    TencentOAuth *_tencentOAuth;
}
@property(nonatomic, retain)NSString *appId;
@property(nonatomic, retain)NSString *openid;
@property(nonatomic, retain)NSString *accessToken;
@property(nonatomic, assign)NSTimeInterval expireTime;
@property(nonatomic, retain)NSDictionary *userInfo;

@property(nonatomic, retain)NSString *extra;
@property(nonatomic, retain)NSString *callbackId;
- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;
@end
